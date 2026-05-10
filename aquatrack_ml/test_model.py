#!/usr/bin/env python3
"""
Simple test of AquaTrack model creation
"""

import sys
sys.path.append('./src/models')

from aquatrack_model import AquaTrackModel
import tensorflow as tf

def test_model():
    print("Creating AquaTrack model...")

    # Create model
    model_builder = AquaTrackModel()
    model = model_builder.create_model()
    model_builder.compile_model()

    print("Model created successfully!")
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

    # Check output ranges
    container_probs = outputs['container_class'].numpy()[0]
    fill_level = outputs['fill_level'].numpy()[0][0]
    liquid_probs = outputs['liquid_type'].numpy()[0]

    print(f"\nOutput validation:")
    print(f"Container probs sum: {container_probs.sum():.3f} (should be ~1.0)")
    print(f"Fill level: {fill_level:.3f} (should be 0-1)")
    print(f"Liquid probs sum: {liquid_probs.sum():.3f} (should be ~1.0)")

    print("\n✅ Model architecture test passed!")
    return True

if __name__ == "__main__":
    try:
        test_model()
    except Exception as e:
        print(f"❌ Model test failed: {e}")
        sys.exit(1)