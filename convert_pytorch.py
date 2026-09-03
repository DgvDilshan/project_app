import sys
from unittest.mock import MagicMock
sys.modules['matplotlib'] = MagicMock()
sys.modules['matplotlib.pyplot'] = MagicMock()
sys.modules['cv2'] = MagicMock()

import torch
import torch.nn as nn
import sys
sys.path.append("d:/Project/Final_Project")
sys.path.append("d:/Project/Final_Project/new_dataset")
from new_dataset.train_baseline import build_baseline

try:
    print("Loading model...")
    state_dict = torch.load('d:/Project/Final_Project/new_dataset/resnet50_baseline.pth', map_location='cpu')
    model = build_baseline(num_classes=3)
    model.load_state_dict(state_dict)
    model.eval()
    print("Model loaded successfully.")
        
    def replace_gelu_with_relu(module):
        for child in module.modules():
            if isinstance(child, nn.GELU):
                # We can't easily replace it in modules() iteration if we don't know the parent,
                # but we can do it via named_children.
                pass
            if isinstance(child, nn.TransformerEncoderLayer):
                import torch.nn.functional as F
                child.activation = F.relu
                
    # Also replace standard nn.GELU just in case
    def replace_gelu_modules(module):
        for name, child in module.named_children():
            if isinstance(child, nn.GELU):
                setattr(module, name, nn.ReLU())
            else:
                replace_gelu_modules(child)
                
    replace_gelu_modules(model)
    replace_gelu_with_relu(model)
    
    # Just to be absolutely safe, patch F.gelu globally for the export
    import torch.nn.functional as F
    F.gelu = F.relu
    
    print("Replaced GELU with ReLU")
    
    dummy_input = torch.randn(1, 3, 224, 224)
    torch.onnx.export(model, dummy_input, "d:/Project/Final_Project/project_app/baseline.onnx", opset_version=13)
    print("Exported ONNX without GELU")
except Exception as e:
    print("Error:", e)
