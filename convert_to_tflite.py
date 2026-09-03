import os
import sys
import torch
import torch.nn as nn
import onnx
from onnx_tf.backend import prepare
import tensorflow as tf

# Add new_dataset path to import train_model
sys.path.append(r'd:\Project\Final_Project\new_dataset')
from train_model import HybridResNetTransformer

def main():
    print("Loading PyTorch model...")
    device = torch.device("cpu")
    
    # We need to specify num_classes. Usually it's 5 or 6 for tea leaf disease.
    # Let's assume num_classes=5 for Blister Blight dataset, but we should load the correct number.
    # Wait, the class names in ml_service.dart are loaded from labels.txt.
    # Let's read labels.txt to find num_classes.
    labels_file = r"d:\Project\Final_Project\project_app\assets\models\labels.txt"
    if os.path.exists(labels_file):
        with open(labels_file, "r") as f:
            classes = [line.strip() for line in f if line.strip()]
        num_classes = len(classes)
    else:
        num_classes = 5 # Default fallback
    
    print(f"Num classes determined as: {num_classes}")
    
    # Initialize model
    model = HybridResNetTransformer(num_classes=num_classes)
    
    # Load weights
    model_path = r"d:\Project\Final_Project\new_dataset\hybrid_resnet_transformer.pth"
    model.load_state_dict(torch.load(model_path, map_location=device))
    model.eval()
    
    # Export to ONNX
    print("Exporting to ONNX...")
    dummy_input = torch.randn(1, 3, 224, 224)
    onnx_path = "model.onnx"
    torch.onnx.export(
        model, 
        dummy_input, 
        onnx_path, 
        export_params=True,
        opset_version=12,
        do_constant_folding=True,
        input_names=['input'],
        output_names=['output'],
        dynamic_axes={'input': {0: 'batch_size'}, 'output': {0: 'batch_size'}}
    )
    
    # Convert ONNX to TensorFlow SavedModel
    print("Converting ONNX to TensorFlow SavedModel...")
    onnx_model = onnx.load(onnx_path)
    tf_rep = prepare(onnx_model)
    tf_model_path = "tf_saved_model"
    tf_rep.export_graph(tf_model_path)
    
    # Convert TensorFlow SavedModel to TFLite
    print("Converting TensorFlow SavedModel to TFLite...")
    converter = tf.lite.TFLiteConverter.from_saved_model(tf_model_path)
    
    # Quantization (optional but good for mobile)
    # converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    tflite_model = converter.convert()
    
    # Save TFLite model
    tflite_path = r"d:\Project\Final_Project\project_app\assets\models\hybrid_agrovision_model.tflite"
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)
        
    print(f"Conversion complete! Saved TFLite model to {tflite_path}")

if __name__ == '__main__':
    main()
