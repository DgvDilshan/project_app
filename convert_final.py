import onnx2tf
import tensorflow as tf
import numpy as np
import onnx2tf.utils.common_functions

# Patch download_test_image_data for offline support
onnx2tf.utils.common_functions.download_test_image_data = lambda: np.zeros((1, 224, 224, 3), dtype=np.float32)
import onnx2tf.onnx2tf
onnx2tf.onnx2tf.download_test_image_data = lambda: np.zeros((1, 224, 224, 3), dtype=np.float32)

original_save = tf.saved_model.save
keras_model_ref = []

def fake_save(model, export_dir, signatures=None, options=None):
    keras_model_ref.append(model)

tf.saved_model.save = fake_save

try:
    onnx2tf.convert(
        input_onnx_file_path="d:/Project/Final_Project/project_app/baseline.onnx",
        output_folder_path="dummy_dir",
        batch_size=1,
        non_verbose=True,
    )
except Exception as e:
    print(f"Exception during conversion: {e}")

if keras_model_ref:
    print("Intercepted Keras model! Converting to TFLite...")
    model = keras_model_ref[0]
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    with open("assets/models/hybrid_agrovision_model.tflite", "wb") as f:
        f.write(tflite_model)
    print("Successfully saved hybrid_agrovision_model.tflite")
else:
    print("FAILED TO INTERCEPT via tf.saved_model.save")
    
    # Let's also try to intercept via tf.keras.Model.save
    try:
        model = tf.saved_model.load("dummy_dir")
        print("Loaded saved model from dummy_dir, converting...")
        converter = tf.lite.TFLiteConverter.from_saved_model("dummy_dir")
        tflite_model = converter.convert()
        with open("assets/models/hybrid_agrovision_model.tflite", "wb") as f:
            f.write(tflite_model)
        print("Successfully saved hybrid_agrovision_model.tflite from saved_model")
    except Exception as e:
        print(f"Could not load saved model: {e}")
