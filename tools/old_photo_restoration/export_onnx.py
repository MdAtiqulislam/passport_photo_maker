import torch
import torch.nn as nn
import onnx
import onnxruntime
import numpy as np

# A minimal lightweight U-Net style model to act as a placeholder
# for a mobile-friendly inpainting/restoration network.
class LightweightRestorationNet(nn.Module):
    def __init__(self):
        super(LightweightRestorationNet, self).__init__()
        # Downsample
        self.conv1 = nn.Conv2d(3, 16, 3, padding=1)
        self.relu1 = nn.ReLU()
        self.pool1 = nn.MaxPool2d(2)
        
        # Bottleneck
        self.conv2 = nn.Conv2d(16, 16, 3, padding=1)
        self.relu2 = nn.ReLU()
        
        # Upsample
        self.up1 = nn.Upsample(scale_factor=2, mode='bilinear', align_corners=False)
        self.conv3 = nn.Conv2d(16, 3, 3, padding=1)
        self.sigmoid = nn.Sigmoid()

    def forward(self, x):
        x1 = self.relu1(self.conv1(x))
        x2 = self.pool1(x1)
        x3 = self.relu2(self.conv2(x2))
        x4 = self.up1(x3)
        # Skip connection addition (simulated)
        x5 = x4 + x1
        out = self.sigmoid(self.conv3(x5))
        return out

def export_to_onnx():
    model = LightweightRestorationNet()
    model.eval()
    
    # Standard mobile input resolution (e.g. 256x256)
    dummy_input = torch.randn(1, 3, 256, 256)
    onnx_path = "mobile_restoration_model.onnx"
    
    print(f"Exporting model to {onnx_path}...")
    torch.onnx.export(
        model, 
        dummy_input, 
        onnx_path, 
        export_params=True,
        opset_version=11, 
        do_constant_folding=True, 
        input_names=['input_image'], 
        output_names=['output_image'],
        dynamic_axes={'input_image': {0: 'batch_size', 2: 'height', 3: 'width'},
                      'output_image': {0: 'batch_size', 2: 'height', 3: 'width'}}
    )
    print("Export successful!")

    # Validate ONNX model
    print("Validating ONNX model...")
    onnx_model = onnx.load(onnx_path)
    onnx.checker.check_model(onnx_model)
    print("ONNX model is valid.")

    # Run inference test using ONNX Runtime
    print("Running inference test...")
    ort_session = onnxruntime.InferenceSession(onnx_path)
    
    def to_numpy(tensor):
        return tensor.detach().cpu().numpy() if tensor.requires_grad else tensor.cpu().numpy()

    # Compare PyTorch output with ONNX output
    ort_inputs = {ort_session.get_inputs()[0].name: to_numpy(dummy_input)}
    ort_outs = ort_session.run(None, ort_inputs)
    
    torch_out = model(dummy_input)
    
    np.testing.assert_allclose(to_numpy(torch_out), ort_outs[0], rtol=1e-03, atol=1e-05)
    print("Success! ONNX runtime outputs match PyTorch outputs.")

if __name__ == "__main__":
    export_to_onnx()
