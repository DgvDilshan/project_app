import tensorflow as tf
import numpy as np

try:
    print("Loading TFLite model...")
    interpreter = tf.lite.Interpreter(model_path="assets/models/hybrid_agrovision_model.tflite")
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print("Input details:", input_details)
    print("Output details:", output_details)
    
    input_shape = input_details[0]['shape']
    print("Input shape:", input_shape)
    
    dummy_input = np.zeros(input_shape, dtype=np.float32)
    interpreter.set_tensor(input_details[0]['index'], dummy_input)
    
    print("Running inference...")
    interpreter.invoke()
    
    output_data = interpreter.get_tensor(output_details[0]['index'])
    print("Inference output:", output_data)
    print("SUCCESS")
except Exception as e:
    print("Error:", e)
