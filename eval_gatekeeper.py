import os
import numpy as np
import tensorflow as tf
from PIL import Image

interpreter = tf.lite.Interpreter(model_path="assets/models/gatekeeper_model.tflite")
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

def predict(img_path):
    try:
        img = Image.open(img_path).convert('RGB')
        img = img.resize((224, 224))
        input_data = np.array(img, dtype=np.float32)
        input_data = (input_data / 127.5) - 1.0
        input_data = np.expand_dims(input_data, axis=0)
        
        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_details[0]['index'])
        return output_data[0][0]
    except Exception as e:
        return -1

def eval_folder(folder, label):
    correct = 0
    total = 0
    for f in os.listdir(folder):
        if not f.lower().endswith('.jpg'): continue
        path = os.path.join(folder, f)
        prob = predict(path)
        if prob == -1: continue
        
        # If label is 1 (tea_leaf), we want prob > 0.5
        # If label is 0 (not_tea_leaf), we want prob <= 0.5
        if label == 1 and prob > 0.5:
            correct += 1
        elif label == 0 and prob <= 0.5:
            correct += 1
        
        total += 1
    
    print(f"Folder {folder}: {correct}/{total} correct")

eval_folder('dataset/tea_leaf', 1)
eval_folder('dataset/not_tea_leaf', 0)
