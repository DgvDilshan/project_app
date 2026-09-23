import tensorflow as tf

interpreter = tf.lite.Interpreter(model_path="assets/models/hybrid_agrovision_model.tflite")
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Input details:", input_details)
print("Output details:", output_details)
