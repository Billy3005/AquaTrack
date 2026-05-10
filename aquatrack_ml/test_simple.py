#!/usr/bin/env python3
"""
Simple End-to-End Test (No Unicode)
Test ML pipeline functionality
"""

import os
import sys
import numpy as np
import tensorflow as tf
from pathlib import Path

# Add src paths with proper path handling
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root / 'src' / 'models'))
sys.path.insert(0, str(project_root / 'src' / 'data'))

from aquatrack_model import AquaTrackModel
from data_pipeline import AquaTrackDataPipeline


def test_model_architecture():
    """Test model creation and forward pass"""
    print("\nTEST 1: Model Architecture")
    print("-" * 30)

    try:
        # Create model
        model_builder = AquaTrackModel()
        model = model_builder.create_model()
        model_builder.compile_model(learning_rate=0.01)

        print(f"Model created with {model.count_params():,} parameters")

        # Test forward pass
        dummy_input = tf.random.normal((2, 224, 224, 3))
        outputs = model(dummy_input)

        # Validate outputs
        print(f"Container output: {outputs['container_class'].shape}")
        print(f"Fill level output: {outputs['fill_level'].shape}")
        print(f"Liquid output: {outputs['liquid_type'].shape}")

        # Check ranges
        container_probs = tf.nn.softmax(outputs['container_class']).numpy()
        fill_levels = outputs['fill_level'].numpy()

        print(f"Container probs sum: {np.sum(container_probs, axis=1)}")
        print(f"Fill level range: {np.min(fill_levels):.3f} - {np.max(fill_levels):.3f}")

        print("PASSED: Model architecture test")
        return True

    except Exception as e:
        print(f"FAILED: Model architecture test - {e}")
        return False


def test_data_pipeline():
    """Test data pipeline setup"""
    print("\nTEST 2: Data Pipeline")
    print("-" * 30)

    try:
        # Test pipeline creation
        pipeline = AquaTrackDataPipeline(batch_size=4)

        print("Pipeline created successfully")

        # Test class mappings
        print(f"Container classes: {len(pipeline.container_classes)}")
        print(f"Liquid classes: {len(pipeline.liquid_classes)}")

        # Test augmentation
        test_image = np.random.rand(224, 224, 3) * 255
        augmented = pipeline.augment_image(test_image.astype(np.uint8))

        print(f"Image augmented: {augmented.shape}")
        print(f"Augmented range: {np.min(augmented):.3f} - {np.max(augmented):.3f}")

        print("PASSED: Data pipeline test")
        return True

    except Exception as e:
        print(f"FAILED: Data pipeline test - {e}")
        return False


def test_tflite_conversion():
    """Test TFLite conversion basics"""
    print("\nTEST 3: TFLite Conversion")
    print("-" * 30)

    try:
        # Create simple model for conversion
        model_builder = AquaTrackModel()
        model = model_builder.create_model()

        print("Model created for conversion test")

        # Test TFLite conversion method
        # Create temporary model directory
        temp_dir = Path("./temp_models")
        temp_dir.mkdir(exist_ok=True)

        # Save model temporarily
        temp_model_path = temp_dir / "temp_model.h5"
        model.save(str(temp_model_path))

        print(f"Temporary model saved: {temp_model_path}")

        # Test conversion to TFLite
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        tflite_model = converter.convert()

        # Save TFLite model
        tflite_path = temp_dir / "temp_model.tflite"
        with open(tflite_path, 'wb') as f:
            f.write(tflite_model)

        print(f"TFLite model size: {len(tflite_model) / 1024 / 1024:.2f} MB")

        # Test TFLite inference
        interpreter = tf.lite.Interpreter(model_path=str(tflite_path))
        interpreter.allocate_tensors()

        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        print(f"TFLite inputs: {len(input_details)}")
        print(f"TFLite outputs: {len(output_details)}")

        # Test inference
        test_input = np.random.rand(1, 224, 224, 3).astype(np.float32) * 255
        interpreter.set_tensor(input_details[0]['index'], test_input)
        interpreter.invoke()

        print("TFLite inference successful")

        # Cleanup
        os.remove(temp_model_path)
        os.remove(tflite_path)
        temp_dir.rmdir()

        print("PASSED: TFLite conversion test")
        return True

    except Exception as e:
        print(f"FAILED: TFLite conversion test - {e}")
        return False


def main():
    """Run simple end-to-end test"""
    print("AquaTrack ML Pipeline - Simple Test")
    print("=" * 50)

    tests = [
        ("Model Architecture", test_model_architecture),
        ("Data Pipeline", test_data_pipeline),
        ("TFLite Conversion", test_tflite_conversion)
    ]

    passed = 0
    total = len(tests)

    for test_name, test_func in tests:
        if test_func():
            passed += 1

    print("\n" + "=" * 50)
    print("TEST SUMMARY")
    print(f"Passed: {passed}/{total}")
    print(f"Success Rate: {passed/total:.1%}")

    if passed == total:
        print("\nALL TESTS PASSED! ML Pipeline is working correctly.")
    else:
        print(f"\n{total - passed} tests failed. Check output above.")

    return passed == total


if __name__ == "__main__":
    success = main()