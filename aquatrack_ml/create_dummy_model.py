#!/usr/bin/env python3
"""
Create dummy TFLite model for AquaTrack testing
Run this to generate placeholder model until real training is complete
"""

import tensorflow as tf
import numpy as np
import os

def create_dummy_aquatrack_model():
    """Create a dummy multi-output model matching VisionService expectations"""

    # Input layer: 224x224x3 RGB image
    input_layer = tf.keras.Input(shape=(224, 224, 3), name='image_input')

    # Simple CNN backbone
    x = tf.keras.layers.Conv2D(32, (3, 3), activation='relu')(input_layer)
    x = tf.keras.layers.MaxPooling2D((2, 2))(x)
    x = tf.keras.layers.Conv2D(64, (3, 3), activation='relu')(x)
    x = tf.keras.layers.MaxPooling2D((2, 2))(x)
    x = tf.keras.layers.Conv2D(64, (3, 3), activation='relu')(x)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dense(64, activation='relu')(x)

    # Output 1: Container classification (10 classes)
    container_output = tf.keras.layers.Dense(10, activation='softmax', name='container_classification')(x)

    # Output 2: Fill level regression (0.0-1.0)
    fill_level_output = tf.keras.layers.Dense(1, activation='sigmoid', name='fill_level_regression')(x)

    # Output 3: Liquid type classification (5 classes)
    liquid_type_output = tf.keras.layers.Dense(5, activation='softmax', name='liquid_type_classification')(x)

    # Create model
    model = tf.keras.Model(
        inputs=input_layer,
        outputs=[container_output, fill_level_output, liquid_type_output]
    )

    # Compile with dummy losses
    model.compile(
        optimizer='adam',
        loss={
            'container_classification': 'categorical_crossentropy',
            'fill_level_regression': 'mse',
            'liquid_type_classification': 'categorical_crossentropy'
        }
    )

    return model

def convert_to_tflite(model, output_path):
    """Convert Keras model to TFLite"""
    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    # Optimize for mobile
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]

    # Convert
    tflite_model = converter.convert()

    # Save
    with open(output_path, 'wb') as f:
        f.write(tflite_model)

    print(f"✅ Dummy TFLite model saved to: {output_path}")
    print(f"📊 Model size: {len(tflite_model) / 1024:.1f} KB")

if __name__ == "__main__":
    print("🤖 Creating dummy AquaTrack TFLite model...")

    # Create model
    model = create_dummy_aquatrack_model()
    model.summary()

    # Output path
    output_dir = os.path.join(os.path.dirname(__file__), '..', 'aquatrack_app', 'assets', 'models')
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, 'aquatrack_v1.tflite')

    # Convert and save
    convert_to_tflite(model, output_path)

    print("\n🚀 Ready to test Smart Scan with dummy model!")
    print("📝 Next steps:")
    print("   1. Run 'flutter run' to test camera integration")
    print("   2. Collect real training data")
    print("   3. Train actual model với proper dataset")
    print("   4. Replace dummy model với trained model")