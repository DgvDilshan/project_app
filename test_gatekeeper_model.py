import numpy as np
import tensorflow as tf
from PIL import Image

# Load TFLite model and allocate tensors.
interpreter = tf.lite.Interpreter(model_path="assets/models/gatekeeper_model.tflite")
interpreter.allocate_tensors()

# Get input and output tensors.
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Input details:", input_details)
print("Output details:", output_details)

# Create a dummy image (green)
img = Image.new('RGB', (224, 224), color = (0, 255, 0))
input_data = np.array(img, dtype=np.float32)

# Normalize to [-1, 1] as per MobileNetV2
input_data = (input_data / 127.5) - 1.0

# Add batch dimension
input_data = np.expand_dims(input_data, axis=0)

interpreter.set_tensor(input_details[0]['index'], input_data)
interpreter.invoke()
output_data = interpreter.get_tensor(output_details[0]['index'])

print("Prediction for solid green image (should be tea_leaf = 1):", output_data[0][0])

# Create a dummy image (human/skin tone)
img = Image.new('RGB', (224, 224), color = (255, 200, 150))
input_data = np.array(img, dtype=np.float32)
input_data = (input_data / 127.5) - 1.0
input_data = np.expand_dims(input_data, axis=0)
interpreter.set_tensor(input_details[0]['index'], input_data)
interpreter.invoke()
output_data = interpreter.get_tensor(output_details[0]['index'])
print("Prediction for solid skin tone image (should be not_tea_leaf = 0):", output_data[0][0])
