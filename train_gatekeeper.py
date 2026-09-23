import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout, Input
# pyrefly: ignore [missing-import]
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import os

IMG_HEIGHT = 224
IMG_WIDTH = 224
BATCH_SIZE = 16 # Small batch size as dataset is small

dataset_dir = 'dataset'

# Check if dataset exists and has both classes
if not os.path.exists(dataset_dir) or len(os.listdir(dataset_dir)) < 2:
    print("Error: Dataset folder not found or doesn't have both classes.")
    exit(1)

print("Preparing dataset...")
# Use MobileNetV2 preprocessing function to scale pixels to [-1, 1]
datagen = ImageDataGenerator(
    preprocessing_function=tf.keras.applications.mobilenet_v2.preprocess_input,
    rotation_range=20,
    width_shift_range=0.2,
    height_shift_range=0.2,
    horizontal_flip=True,
    validation_split=0.2
)

train_generator = datagen.flow_from_directory(
    dataset_dir,
    target_size=(IMG_HEIGHT, IMG_WIDTH),
    batch_size=BATCH_SIZE,
    class_mode='binary',
    subset='training'
)

val_generator = datagen.flow_from_directory(
    dataset_dir,
    target_size=(IMG_HEIGHT, IMG_WIDTH),
    batch_size=BATCH_SIZE,
    class_mode='binary',
    subset='validation'
)

print(f"Classes found: {train_generator.class_indices}")

# Build a robust model using Transfer Learning (MobileNetV2)
print("Building Gatekeeper Model (MobileNetV2 Transfer Learning)...")

base_model = tf.keras.applications.MobileNetV2(
    input_shape=(IMG_HEIGHT, IMG_WIDTH, 3),
    include_top=False,
    weights='imagenet'
)
# Freeze the base model
base_model.trainable = False

model = Sequential([
    base_model,
    tf.keras.layers.GlobalAveragePooling2D(),
    Dense(128, activation='relu'),
    Dropout(0.5),
    Dense(1, activation='sigmoid') # Binary output
])

model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
              loss='binary_crossentropy',
              metrics=['accuracy'])

print("Starting training (10 epochs)...")
epochs = 10
history = model.fit(
    train_generator,
    validation_data=val_generator,
    epochs=epochs
)

print("\nTraining finished! Converting to TFLite format...")

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open('gatekeeper_model.tflite', 'wb') as f:
    f.write(tflite_model)

print("\n=======================================================")
print("SUCCESS! Gatekeeper model saved as 'gatekeeper_model.tflite'!")
print(f"Please remember the Class indices: {train_generator.class_indices}")
print("=======================================================")
