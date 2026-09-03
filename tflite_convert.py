import tensorflow as tf
import os

def main():
    print("Converting TensorFlow SavedModel to TFLite...")
    tf_model_path = "tf_saved_model"
    tflite_path = r"d:\Project\Final_Project\project_app\assets\models\hybrid_agrovision_model.tflite"
    
    if not os.path.exists(tf_model_path):
        print(f"Error: {tf_model_path} not found.")
        return

    converter = tf.lite.TFLiteConverter.from_saved_model(tf_model_path)
    # Enable standard TF ops if needed
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS
    ]
    
    tflite_model = converter.convert()
    
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)
        
    print(f"Conversion complete! Saved TFLite model to {tflite_path}")

if __name__ == '__main__':
    main()
