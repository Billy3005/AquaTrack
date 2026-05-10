#!/usr/bin/env python3
"""
AquaTrack Multi-Output CNN Model
Main model architecture for container detection and volume estimation
"""

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, Model
from typing import Dict, List, Tuple
import numpy as np


class AquaTrackModel:
    """
    Multi-output CNN for AquaTrack Smart Scan

    Outputs:
    - container_class: 10 categories (bottle_500, glass_small, etc.)
    - fill_level: continuous 0-1 (regression)
    - liquid_type: 5 categories (water, tea, coffee, juice, smoothie)
    """

    def __init__(self,
                 input_shape: Tuple[int, int, int] = (224, 224, 3),
                 num_container_classes: int = 10,
                 num_liquid_classes: int = 5):
        self.input_shape = input_shape
        self.num_container_classes = num_container_classes
        self.num_liquid_classes = num_liquid_classes

        # Class mappings (sync with VisionService)
        self.container_classes = [
            'glass_small', 'glass_large', 'cup_plastic', 'bottle_500',
            'bottle_750', 'bottle_1000', 'bottle_1500', 'mug',
            'can_330', 'other'
        ]

        self.liquid_classes = [
            'water', 'tea', 'coffee', 'juice', 'smoothie'
        ]

        self.model = None

    def create_backbone(self, inputs: tf.Tensor) -> tf.Tensor:
        """
        Create CNN backbone for feature extraction
        Uses EfficientNetB0-inspired architecture optimized for mobile
        """
        # Initial conv block
        x = layers.Conv2D(32, 3, strides=2, padding='same')(inputs)
        x = layers.BatchNormalization()(x)
        x = layers.ReLU()(x)

        # MBConv blocks (Mobile-friendly)
        x = self._mbconv_block(x, 16, 1, 1)  # 112x112x16
        x = self._mbconv_block(x, 24, 6, 2)  # 56x56x24
        x = self._mbconv_block(x, 24, 6, 1)  # 56x56x24

        x = self._mbconv_block(x, 40, 6, 2)  # 28x28x40
        x = self._mbconv_block(x, 40, 6, 1)  # 28x28x40

        x = self._mbconv_block(x, 80, 6, 2)  # 14x14x80
        x = self._mbconv_block(x, 80, 6, 1)  # 14x14x80
        x = self._mbconv_block(x, 80, 6, 1)  # 14x14x80

        x = self._mbconv_block(x, 112, 6, 1) # 14x14x112
        x = self._mbconv_block(x, 112, 6, 1) # 14x14x112

        x = self._mbconv_block(x, 192, 6, 2) # 7x7x192
        x = self._mbconv_block(x, 192, 6, 1) # 7x7x192

        # Final conv
        x = layers.Conv2D(320, 1, padding='same')(x)
        x = layers.BatchNormalization()(x)
        x = layers.ReLU()(x)

        # Global average pooling
        x = layers.GlobalAveragePooling2D()(x)

        return x

    def _mbconv_block(self, inputs: tf.Tensor,
                      filters: int,
                      expand_ratio: int,
                      strides: int) -> tf.Tensor:
        """Mobile Inverted Bottleneck Conv Block"""
        in_filters = inputs.shape[-1]
        expanded_filters = in_filters * expand_ratio

        x = inputs

        # Expand phase (if expand_ratio > 1)
        if expand_ratio != 1:
            x = layers.Conv2D(expanded_filters, 1, padding='same')(x)
            x = layers.BatchNormalization()(x)
            x = layers.ReLU()(x)

        # Depthwise conv
        x = layers.DepthwiseConv2D(3, strides=strides, padding='same')(x)
        x = layers.BatchNormalization()(x)
        x = layers.ReLU()(x)

        # Project phase
        x = layers.Conv2D(filters, 1, padding='same')(x)
        x = layers.BatchNormalization()(x)

        # Skip connection (if same dims)
        if strides == 1 and in_filters == filters:
            x = layers.Add()([inputs, x])

        return x

    def create_model(self) -> Model:
        """Create complete multi-output model"""
        inputs = layers.Input(shape=self.input_shape, name='image_input')

        # Preprocessing
        x = layers.Lambda(lambda x: tf.cast(x, tf.float32) / 255.0)(inputs)

        # Feature extraction backbone
        features = self.create_backbone(x)

        # Shared dense layers
        shared = layers.Dense(256, activation='relu')(features)
        shared = layers.Dropout(0.3)(shared)

        # Container classification head
        container_branch = layers.Dense(128, activation='relu', name='container_dense')(shared)
        container_branch = layers.Dropout(0.2)(container_branch)
        container_output = layers.Dense(
            self.num_container_classes,
            activation='softmax',
            name='container_class'
        )(container_branch)

        # Fill level regression head
        fill_branch = layers.Dense(64, activation='relu', name='fill_dense')(shared)
        fill_branch = layers.Dropout(0.2)(fill_branch)
        fill_output = layers.Dense(
            1,
            activation='sigmoid',
            name='fill_level'
        )(fill_branch)

        # Liquid type classification head
        liquid_branch = layers.Dense(64, activation='relu', name='liquid_dense')(shared)
        liquid_branch = layers.Dropout(0.2)(liquid_branch)
        liquid_output = layers.Dense(
            self.num_liquid_classes,
            activation='softmax',
            name='liquid_type'
        )(liquid_branch)

        # Create model
        model = Model(
            inputs=inputs,
            outputs={
                'container_class': container_output,
                'fill_level': fill_output,
                'liquid_type': liquid_output
            }
        )

        self.model = model
        return model

    def compile_model(self,
                      learning_rate: float = 0.001,
                      container_weight: float = 1.0,
                      fill_weight: float = 2.0,
                      liquid_weight: float = 1.0) -> None:
        """
        Compile model with appropriate loss functions and metrics

        Args:
            learning_rate: Adam optimizer learning rate
            container_weight: Weight for container classification loss
            fill_weight: Weight for fill level regression loss (higher = more important)
            liquid_weight: Weight for liquid classification loss
        """
        if self.model is None:
            raise ValueError("Model not created. Call create_model() first.")

        # Loss functions
        losses = {
            'container_class': 'sparse_categorical_crossentropy',
            'fill_level': 'mse',  # Mean squared error for regression
            'liquid_type': 'sparse_categorical_crossentropy'
        }

        # Loss weights (fill level is most important for volume estimation)
        loss_weights = {
            'container_class': container_weight,
            'fill_level': fill_weight,
            'liquid_type': liquid_weight
        }

        # Metrics
        metrics = {
            'container_class': ['accuracy'],
            'fill_level': ['mae'],  # Mean absolute error
            'liquid_type': ['accuracy']
        }

        # Optimizer
        optimizer = keras.optimizers.Adam(learning_rate=learning_rate)

        self.model.compile(
            optimizer=optimizer,
            loss=losses,
            loss_weights=loss_weights,
            metrics=metrics
        )

    def get_model_summary(self) -> str:
        """Get model architecture summary"""
        if self.model is None:
            self.create_model()

        import io
        import sys

        # Capture summary
        old_stdout = sys.stdout
        sys.stdout = buffer = io.StringIO()
        self.model.summary()
        sys.stdout = old_stdout

        return buffer.getvalue()

    def save_model(self, filepath: str) -> None:
        """Save trained model"""
        if self.model is None:
            raise ValueError("No model to save")

        self.model.save(filepath)
        print(f"Model saved to {filepath}")

    def load_model(self, filepath: str) -> None:
        """Load trained model"""
        self.model = keras.models.load_model(filepath)
        print(f"Model loaded from {filepath}")

    def convert_to_tflite(self,
                          model_path: str,
                          output_path: str,
                          quantize: bool = True) -> None:
        """
        Convert trained model to TFLite for mobile deployment

        Args:
            model_path: Path to saved Keras model
            output_path: Output path for .tflite file
            quantize: Apply quantization for smaller model size
        """
        # Load saved model
        saved_model = keras.models.load_model(model_path)

        # Convert to TFLite
        converter = tf.lite.TFLiteConverter.from_keras_model(saved_model)

        if quantize:
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            # Use float16 quantization for better accuracy vs size trade-off
            converter.target_spec.supported_types = [tf.float16]

        tflite_model = converter.convert()

        # Save TFLite model
        with open(output_path, 'wb') as f:
            f.write(tflite_model)

        print(f"TFLite model saved to {output_path}")
        print(f"Model size: {len(tflite_model) / 1024 / 1024:.2f} MB")


def create_aquatrack_model() -> AquaTrackModel:
    """Factory function to create AquaTrack model instance"""
    return AquaTrackModel()


if __name__ == "__main__":
    # Test model creation
    print("Creating AquaTrack model...")

    model_builder = create_aquatrack_model()
    model = model_builder.create_model()
    model_builder.compile_model()

    print("\n" + "="*50)
    print("AQUATRACK MODEL ARCHITECTURE")
    print("="*50)
    print(model_builder.get_model_summary())

    print("\n" + "="*50)
    print("MODEL INFO")
    print("="*50)
    print(f"Input shape: {model_builder.input_shape}")
    print(f"Container classes: {len(model_builder.container_classes)}")
    print(f"Liquid classes: {len(model_builder.liquid_classes)}")
    print(f"Total parameters: {model.count_params():,}")

    # Test forward pass with dummy data
    print("\nTesting forward pass...")
    dummy_input = tf.random.normal((1, 224, 224, 3))
    outputs = model(dummy_input)

    print(f"Container output shape: {outputs['container_class'].shape}")
    print(f"Fill level output shape: {outputs['fill_level'].shape}")
    print(f"Liquid output shape: {outputs['liquid_type'].shape}")

    print("\n✅ Model architecture created successfully!")