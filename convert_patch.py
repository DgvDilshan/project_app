import onnx2tf
import tensorflow as tf

original_save = tf.saved_model.save
keras_model_ref = []

def fake_save(model, export_dir, signatures=None, options=None):
    keras_model_ref.append(model)
    # Skip actual saving to avoid Windows file lock issues

tf.saved_model.save = fake_save

try:
    onnx2tf.convert(
        input_onnx_file_path="d:/Project/Final_Project/project_app/model.onnx",
        output_folder_path="dummy_dir",
        replace_to_pseudo_operators=["Erf"],
        non_verbose=True,
    )
except Exception as e:
    # Expected to fail when from_saved_model is called since we didn't save it
    pass

if keras_model_ref:
    model = keras_model_ref[0]
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    with open("d:/Project/Final_Project/project_app/final_hybrid.tflite", "wb") as f:
        f.write(tflite_model)
    print("SUCCESS_MONKEY_PATCH")
else:
    print("FAILED TO INTERCEPT")
