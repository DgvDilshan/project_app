import onnx2tf
import sys
import time

for i in range(5):
    try:
        print(f"Attempt {i+1}...")
        onnx2tf.convert(
            input_onnx_file_path="d:/Project/Final_Project/project_app/model.onnx",
            output_folder_path="d:/Project/Final_Project/project_app/new_tf_model",
            replace_to_pseudo_operators=["Erf"],
            non_verbose=True,
        )
        print("SUCCESS")
        break
    except Exception as e:
        print(f"FAILED on attempt {i+1}:", e)
        time.sleep(2)
