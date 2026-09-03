import onnx2tf
import sys

try:
    onnx2tf.convert(
        input_onnx_file_path="d:/Project/Final_Project/project_app/model.onnx",
        output_folder_path="C:/Temp/new_tf_model",
        replace_to_pseudo_operators=["Erf"],
        non_verbose=True,
    )
    print("SUCCESS")
except Exception as e:
    print("FAILED:", e)
