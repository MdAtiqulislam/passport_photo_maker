import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../data/models/restoration_models.dart';
import 'photo_restoration_service.dart';

class AiRestoreApiService {
  // Get API token from dart-define, fallback to provided Replicate token
  static const String _apiToken = String.fromEnvironment(
    'REPLICATE_API_TOKEN',
    defaultValue: 'r8_YQUx5iCdKZNwZKPTR9G9Hdz1zjOquNo1KvsVY',
  );
  static const String _apiUrl = 'https://api.replicate.com/v1/predictions';
  // GFPGAN model version on Replicate (tencentarc/gfpgan)
  static const String _gfpganVersion = '0fbacf7afc6c144e5be9767cff80f25aff23e52b0708f17e20f9879b2f21516c';
  // CodeFormer model version on Replicate (sczhou/codeformer)
  static const String _codeFormerVersion = '78f2bab438ab0ffc85a68cdfd316a2ecd3994b5dd26aa6b3d203357b45e5eb1b';

  /// Main entry point - restores a photo using cloud AI
  static Future<AiRestoreResult> restoreWithAi({
    required File imageFile,
    int upscale = 2,
    String model = 'codeformer', // 'codeformer' or 'gfpgan'
    double fidelity = 0.7, // 0.1 to 0.9 (CodeFormer only)
  }) async {
    if (!isConfigured) {
      throw Exception('Replicate API Token is missing.');
    }

    final startTime = DateTime.now();

    // 1. Read image file and convert to base64 data URI
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = path.extension(imageFile.path).replaceAll('.', '');
    final mimeType = ext == 'png' ? 'png' : 'jpeg';
    final dataUri = 'data:image/$mimeType;base64,$base64Image';

    final isCodeFormer = model == 'codeformer';

    // 2. POST to Replicate API to create prediction
    final createRes = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $_apiToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'version': isCodeFormer ? _codeFormerVersion : _gfpganVersion,
        'input': isCodeFormer
            ? {
                'image': dataUri,
                'codeformer_fidelity': fidelity,
                'background_enhance': true,
                'face_upsample': true,
                'upscale': upscale,
              }
            : {
                'img': dataUri,
                'version': 'v1.4',
                'scale': upscale,
              }
      }),
    ).timeout(const Duration(seconds: 25));

    if (createRes.statusCode != 201) {
      throw Exception('Failed to start prediction: ${createRes.body}');
    }

    final createData = jsonDecode(createRes.body);
    final getUrl = createData['urls']['get'];
    String status = createData['status'];
    String? outputUrl;

    // 3. Poll prediction status
    int iterations = 0;
    while (status != 'succeeded' && status != 'failed' && status != 'canceled' && iterations < 40) {
      await Future.delayed(const Duration(milliseconds: 1500));
      iterations++;
      
      final pollRes = await http.get(
        Uri.parse(getUrl),
        headers: {
          'Authorization': 'Bearer $_apiToken',
        }
      ).timeout(const Duration(seconds: 15));
      
      if (pollRes.statusCode != 200) {
        throw Exception('Failed to poll prediction: ${pollRes.statusCode}');
      }
      
      final pollData = jsonDecode(pollRes.body);
      status = pollData['status'];
      
      if (status == 'succeeded') {
        final rawOutput = pollData['output'];
        if (rawOutput is String) {
          outputUrl = rawOutput;
        } else if (rawOutput is List && rawOutput.isNotEmpty) {
          outputUrl = rawOutput.first.toString();
        }
      } else if (status == 'failed') {
        throw Exception('Prediction failed: ${pollData['error']}');
      }
    }

    if (status != 'succeeded' || outputUrl == null) {
      throw Exception('Prediction timed out or did not succeed. Status: $status');
    }

    // 4 & 5. Download the output image
    final imageRes = await http.get(Uri.parse(outputUrl)).timeout(const Duration(seconds: 30));
    if (imageRes.statusCode != 200) {
      throw Exception('Failed to download restored image.');
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final downloadedFile = File(path.join(tempDir.path, 'ai_gfpgan_$timestamp.jpg'));
    await downloadedFile.writeAsBytes(imageRes.bodyBytes);

    // 5. Post-process to remove physical scratches on clothes, shirt & background
    String finalPath = downloadedFile.path;
    try {
      final cleanResult = await PhotoRestorationService.restorePhoto(
        imageFile: downloadedFile,
        options: const RestorationOptions(
          strength: RestorationStrength.medium,
          repairScratches: true,
          reduceNoise: true,
          deblurAndSharpen: false,
          recoverFadedColors: false,
        ),
      );
      if (cleanResult.restoredImagePath.isNotEmpty && File(cleanResult.restoredImagePath).existsSync()) {
        finalPath = cleanResult.restoredImagePath;
      }
    } catch (_) {
      // Fallback to direct GFPGAN output if local post-processing fails
    }

    final endTime = DateTime.now();
    final processingTimeMs = endTime.difference(startTime).inMilliseconds;

    // 6. Return result
    return AiRestoreResult(
      originalImagePath: imageFile.path,
      restoredImagePath: finalPath,
      model: '$model+scratch_cleaner',
      upscaleFactor: upscale,
      processingTimeMs: processingTimeMs,
    );
  }

  static bool get isConfigured => _apiToken.isNotEmpty;
}

class AiRestoreResult {
  final String originalImagePath;
  final String restoredImagePath;
  final String model;
  final int upscaleFactor;
  final int processingTimeMs;

  const AiRestoreResult({
    required this.originalImagePath,
    required this.restoredImagePath,
    required this.model,
    required this.upscaleFactor,
    required this.processingTimeMs,
  });
}
