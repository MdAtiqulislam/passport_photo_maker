package com.itpark.passport_photo_maker

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.nio.FloatBuffer

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.passportphotomaker.restoration/onnx"
    private var ortEnv: OrtEnvironment? = null
    private var ortSession: OrtSession? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "runRestorationModel") {
                val imagePath = call.argument<String>("imagePath")
                val modelName = call.argument<String>("modelName")
                
                if (imagePath == null || modelName == null) {
                    result.error("INVALID_ARGS", "Missing imagePath or modelName", null)
                    return@setMethodCallHandler
                }

                CoroutineScope(Dispatchers.Main).launch {
                    try {
                        val outPath = withContext(Dispatchers.IO) {
                            processImageWithOnnx(imagePath, modelName)
                        }
                        result.success(outPath)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.error("INFERENCE_ERROR", e.message, null)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun processImageWithOnnx(imagePath: String, modelName: String): String {
        if (ortEnv == null) {
            ortEnv = OrtEnvironment.getEnvironment()
        }
        
        if (ortSession == null) {
            val assetManager = context.assets
            val modelBytes = assetManager.open(modelName).readBytes()
            ortSession = ortEnv?.createSession(modelBytes, OrtSession.SessionOptions())
        }

        val session = ortSession ?: throw Exception("Failed to create ONNX session")

        val bitmap = BitmapFactory.decodeFile(imagePath) ?: throw Exception("Failed to decode image")
        
        var targetW = bitmap.width
        var targetH = bitmap.height
        val maxSize = 512
        if (targetW > maxSize || targetH > maxSize) {
            val scale = maxSize.toFloat() / maxOf(targetW, targetH).toFloat()
            targetW = (targetW * scale).toInt()
            targetH = (targetH * scale).toInt()
        }
        
        // Ensure dimensions are even numbers (some ONNX models require even dims)
        if (targetW % 2 != 0) targetW -= 1
        if (targetH % 2 != 0) targetH -= 1

        val resizedBitmap = Bitmap.createScaledBitmap(bitmap, targetW, targetH, true)
        
        val inputShape = longArrayOf(1, 3, targetH.toLong(), targetW.toLong())
        val floatBuffer = FloatBuffer.allocate(3 * targetW * targetH)
        
        val pixels = IntArray(targetW * targetH)
        resizedBitmap.getPixels(pixels, 0, targetW, 0, 0, targetW, targetH)
        
        for (i in pixels.indices) {
            val pixel = pixels[i]
            val r = ((pixel shr 16) and 0xFF) / 255.0f
            val g = ((pixel shr 8) and 0xFF) / 255.0f
            val b = (pixel and 0xFF) / 255.0f
            
            floatBuffer.put(i, r)
            floatBuffer.put(i + targetW * targetH, g)
            floatBuffer.put(i + 2 * targetW * targetH, b)
        }

        val inputName = session.inputNames.iterator().next()
        val inputTensor = OnnxTensor.createTensor(ortEnv, floatBuffer, inputShape)
        
        val inferenceResult = session.run(mapOf(inputName to inputTensor))
        val outputTensor = inferenceResult[0] as OnnxTensor
        
        val shape = outputTensor.info.shape
        val outH = shape[2].toInt()
        val outW = shape[3].toInt()
        
        val outputArray = outputTensor.floatBuffer
        
        val outBitmap = Bitmap.createBitmap(outW, outH, Bitmap.Config.ARGB_8888)
        val outPixels = IntArray(outW * outH)
        
        for (i in outPixels.indices) {
            val r = (outputArray.get(i).coerceIn(0f, 1f) * 255).toInt()
            val g = (outputArray.get(i + outW * outH).coerceIn(0f, 1f) * 255).toInt()
            val b = (outputArray.get(i + 2 * outW * outH).coerceIn(0f, 1f) * 255).toInt()
            outPixels[i] = (0xFF shl 24) or (r shl 16) or (g shl 8) or b
        }
        
        outBitmap.setPixels(outPixels, 0, outW, 0, 0, outW, outH)
        
        val outFile = File(context.cacheDir, "restored_${System.currentTimeMillis()}.png")
        FileOutputStream(outFile).use { out ->
            outBitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }

        return outFile.absolutePath
    }
}
