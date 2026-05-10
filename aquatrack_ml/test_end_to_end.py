#!/usr/bin/env python3
"""
End-to-End Test of AquaTrack ML Pipeline
Test complete workflow with synthetic data
"""

import os
import sys
import json
import numpy as np
import tensorflow as tf
from pathlib import Path
from datetime import datetime
from typing import List, Dict

# Add src paths with proper path handling
project_root = Path(__file__).parent
for module_dir in ['models', 'data', 'training', 'evaluation', 'deployment']:
    sys.path.insert(0, str(project_root / 'src' / module_dir))

from aquatrack_model import AquaTrackModel
from data_pipeline import AquaTrackDataPipeline
from trainer import AquaTrackTrainer
from evaluator import AquaTrackEvaluator
from tflite_converter import TFLiteOptimizer


class SyntheticDataGenerator:
    """Generate synthetic training data for testing"""

    def __init__(self, output_dir: str = "./data"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Create subdirectories
        (self.output_dir / "raw").mkdir(exist_ok=True)
        (self.output_dir / "annotations").mkdir(exist_ok=True)

        # Class mappings
        self.container_classes = [
            'glass_small', 'glass_large', 'cup_plastic', 'bottle_500',
            'bottle_750', 'bottle_1000', 'bottle_1500', 'mug',
            'can_330', 'other'
        ]
        self.liquid_classes = ['water', 'tea', 'coffee', 'juice', 'smoothie']

    def generate_synthetic_image(self,
                               container_type: str,
                               fill_level: float,
                               liquid_type: str) -> np.ndarray:
        """Generate synthetic container image"""
        # Create base image (224x224x3)
        image = np.random.rand(224, 224, 3) * 255

        # Add container-like features based on type
        container_idx = self.container_classes.index(container_type) if container_type in self.container_classes else 0

        # Simple container simulation (different colors/patterns)
        if 'bottle' in container_type:
            # Bottle-like vertical pattern
            image[50:200, 80:144, :] = 200 + np.random.rand(150, 64, 3) * 55
        elif 'glass' in container_type:
            # Glass-like circular pattern
            center = (112, 112)
            y, x = np.ogrid[:224, :224]
            mask = (x - center[0])**2 + (y - center[1])**2 < 50**2
            image[mask] = 180 + np.random.rand(np.sum(mask), 3) * 75
        else:
            # Generic container
            image[60:180, 90:134, :] = 160 + np.random.rand(120, 44, 3) * 95

        # Add fill level indication (darker region for liquid)
        if fill_level > 0.1:
            fill_height = int(100 * fill_level)
            liquid_color = self._get_liquid_color(liquid_type)
            image[200-fill_height:200, 90:134, :] = liquid_color + np.random.rand(fill_height, 44, 3) * 30

        return image.astype(np.uint8)

    def _get_liquid_color(self, liquid_type: str) -> np.ndarray:
        """Get color for liquid type"""
        colors = {
            'water': np.array([200, 220, 255]),
            'tea': np.array([150, 100, 50]),
            'coffee': np.array([80, 40, 20]),
            'juice': np.array([255, 150, 50]),
            'smoothie': np.array([255, 180, 100])
        }
        return colors.get(liquid_type, np.array([200, 200, 200]))

    def generate_dataset(self, num_samples: int = 100) -> List[Dict]:
        """Generate synthetic dataset with annotations"""
        print(f"Generating {num_samples} synthetic samples...")

        annotations = []

        for i in range(num_samples):
            # Random sample parameters
            container_type = np.random.choice(self.container_classes)
            liquid_type = np.random.choice(self.liquid_classes)
            fill_level = np.random.uniform(0.05, 0.95)  # 5% to 95%

            # Generate image
            image = self.generate_synthetic_image(container_type, fill_level, liquid_type)

            # Save image
            image_filename = f"synthetic_{i:04d}.png"
            image_path = self.output_dir / "raw" / image_filename

            # Convert to PIL and save
            from PIL import Image
            pil_image = Image.fromarray(image)
            pil_image.save(image_path)

            # Create annotation
            annotation = {
                'original_path': str(image_path),
                'image_path': str(image_path),
                'container_type': container_type,
                'fill_level': fill_level,
                'liquid_type': liquid_type,
                'estimated_volume_ml': int(500 * fill_level),  # Approximate
                'notes': f"Synthetic data - sample {i}",
                'timestamp': datetime.now().isoformat(),
                'collector': 'synthetic_generator'
            }

            annotations.append(annotation)

        # Save annotations
        annotation_file = self.output_dir / "annotations" / "annotations.json"
        with open(annotation_file, 'w') as f:
            json.dump(annotations, f, indent=2)

        print(f"Synthetic dataset created: {num_samples} samples")
        print(f"Images saved to: {self.output_dir / 'raw'}")
        print(f"Annotations saved to: {annotation_file}")

        return annotations


class EndToEndTester:
    """Complete end-to-end ML pipeline test"""

    def __init__(self, test_dir: str = "./test_output"):
        self.test_dir = Path(test_dir)
        self.test_dir.mkdir(parents=True, exist_ok=True)

        self.data_generator = SyntheticDataGenerator(str(self.test_dir / "data"))
        self.results = {}

    def test_model_architecture(self) -> bool:
        """Test 1: Model creation and basic functionality"""
        print("\n" + "="*60)
        print("TEST 1: Model Architecture")
        print("="*60)

        try:
            # Create model
            model_builder = AquaTrackModel()
            model = model_builder.create_model()
            model_builder.compile_model(learning_rate=0.01)

            # Test forward pass
            dummy_input = tf.random.normal((2, 224, 224, 3))  # Batch of 2
            outputs = model(dummy_input)

            # Validate outputs
            assert outputs['container_class'].shape == (2, 10), "Container output shape incorrect"
            assert outputs['fill_level'].shape == (2, 1), "Fill level output shape incorrect"
            assert outputs['liquid_type'].shape == (2, 5), "Liquid output shape incorrect"

            # Check output ranges
            container_probs = tf.nn.softmax(outputs['container_class']).numpy()
            fill_levels = outputs['fill_level'].numpy()
            liquid_probs = tf.nn.softmax(outputs['liquid_type']).numpy()

            assert np.allclose(np.sum(container_probs, axis=1), 1.0, atol=1e-5), "Container probs don't sum to 1"
            assert np.all(fill_levels >= 0) and np.all(fill_levels <= 1), "Fill levels out of range"
            assert np.allclose(np.sum(liquid_probs, axis=1), 1.0, atol=1e-5), "Liquid probs don't sum to 1"

            self.results['model_architecture'] = {
                'status': 'PASSED',
                'parameters': model.count_params(),
                'outputs_validated': True
            }

            print("✅ Model architecture test PASSED")
            return True

        except Exception as e:
            print(f"❌ Model architecture test FAILED: {e}")
            self.results['model_architecture'] = {'status': 'FAILED', 'error': str(e)}
            return False

    def test_data_pipeline(self) -> bool:
        """Test 2: Data pipeline with synthetic data"""
        print("\n" + "="*60)
        print("TEST 2: Data Pipeline")
        print("="*60)

        try:
            # Generate synthetic dataset
            annotations = self.data_generator.generate_dataset(num_samples=20)

            # Test data pipeline
            pipeline = AquaTrackDataPipeline(
                data_dir=str(self.test_dir / "data"),
                batch_size=4
            )

            # Load and process annotations
            processed = pipeline.preprocess_annotations(annotations)
            assert len(processed) == len(annotations), "Annotation processing lost samples"

            # Create dataset
            dataset = pipeline.create_tf_dataset(processed[:10], is_training=True)

            # Test data loading
            sample_count = 0
            for batch_images, batch_labels in dataset:
                sample_count += batch_images.shape[0]

                # Validate batch shapes
                assert batch_images.shape[1:] == (224, 224, 3), "Image shape incorrect"
                assert batch_labels['container_class'].shape[0] == batch_images.shape[0], "Label batch size mismatch"

                if sample_count >= 8:  # Test first 2 batches
                    break

            self.results['data_pipeline'] = {
                'status': 'PASSED',
                'samples_processed': len(processed),
                'batches_tested': 2
            }

            print("✅ Data pipeline test PASSED")
            return True

        except Exception as e:
            print(f"❌ Data pipeline test FAILED: {e}")
            self.results['data_pipeline'] = {'status': 'FAILED', 'error': str(e)}
            return False

    def test_training_setup(self) -> bool:
        """Test 3: Training pipeline setup"""
        print("\n" + "="*60)
        print("TEST 3: Training Setup")
        print("="*60)

        try:
            # Create trainer
            trainer = AquaTrackTrainer(
                data_dir=str(self.test_dir / "data"),
                output_dir=str(self.test_dir / "models"),
                experiment_name="end_to_end_test"
            )

            # Setup data
            trainer.setup_data(batch_size=4)

            # Setup model
            trainer.setup_model(learning_rate=0.01)

            # Test training for 1 epoch
            history = trainer.train(epochs=1, patience=5)

            assert history is not None, "Training returned no history"
            assert len(history.history) > 0, "Training history is empty"

            self.results['training_setup'] = {
                'status': 'PASSED',
                'epochs_completed': len(history.history['loss']),
                'final_loss': float(history.history['loss'][-1]),
                'experiment_dir': str(trainer.experiment_dir)
            }

            print("✅ Training setup test PASSED")
            return True

        except Exception as e:
            print(f"❌ Training setup test FAILED: {e}")
            self.results['training_setup'] = {'status': 'FAILED', 'error': str(e)}
            return False

    def test_tflite_conversion(self) -> bool:
        """Test 4: TFLite conversion"""
        print("\n" + "="*60)
        print("TEST 4: TFLite Conversion")
        print("="*60)

        try:
            # Find trained model from previous test
            experiment_dir = Path(self.results['training_setup']['experiment_dir'])
            model_path = experiment_dir / "final_model.h5"

            if not model_path.exists():
                print("❌ No trained model found for conversion test")
                return False

            # Create TFLite optimizer
            optimizer = TFLiteOptimizer(
                str(model_path),
                str(self.test_dir / "tflite_models")
            )

            optimizer.load_model()

            # Test basic conversions
            float32_path = optimizer.convert_float32("test_float32.tflite")
            float16_path = optimizer.convert_float16("test_float16.tflite")

            # Verify models were created
            assert os.path.exists(float32_path), "Float32 model not created"
            assert os.path.exists(float16_path), "Float16 model not created"

            # Basic TFLite inference test
            interpreter = tf.lite.Interpreter(model_path=float16_path)
            interpreter.allocate_tensors()

            input_details = interpreter.get_input_details()
            output_details = interpreter.get_output_details()

            # Test inference
            test_input = np.random.rand(1, 224, 224, 3).astype(np.float32) * 255
            interpreter.set_tensor(input_details[0]['index'], test_input)
            interpreter.invoke()

            # Get outputs
            outputs = {}
            for output_detail in output_details:
                output_name = output_detail['name'].split('/')[-1]
                outputs[output_name] = interpreter.get_tensor(output_detail['index'])

            assert len(outputs) == 3, "Expected 3 outputs from TFLite model"

            self.results['tflite_conversion'] = {
                'status': 'PASSED',
                'float32_model': float32_path,
                'float16_model': float16_path,
                'inference_tested': True
            }

            print("✅ TFLite conversion test PASSED")
            return True

        except Exception as e:
            print(f"❌ TFLite conversion test FAILED: {e}")
            self.results['tflite_conversion'] = {'status': 'FAILED', 'error': str(e)}
            return False

    def run_all_tests(self) -> Dict:
        """Run complete end-to-end test suite"""
        print("\n🚀 STARTING AQUATRACK ML PIPELINE END-TO-END TEST")
        print("="*80)

        start_time = datetime.now()

        # Run all tests
        tests = [
            ("Model Architecture", self.test_model_architecture),
            ("Data Pipeline", self.test_data_pipeline),
            ("Training Setup", self.test_training_setup),
            ("TFLite Conversion", self.test_tflite_conversion)
        ]

        passed_tests = 0
        total_tests = len(tests)

        for test_name, test_func in tests:
            if test_func():
                passed_tests += 1

        # Summary
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()

        summary = {
            'total_tests': total_tests,
            'passed_tests': passed_tests,
            'failed_tests': total_tests - passed_tests,
            'success_rate': passed_tests / total_tests,
            'duration_seconds': duration,
            'timestamp': end_time.isoformat(),
            'test_results': self.results
        }

        # Print summary
        print("\n" + "="*80)
        print("END-TO-END TEST SUMMARY")
        print("="*80)
        print(f"Tests Passed: {passed_tests}/{total_tests}")
        print(f"Success Rate: {summary['success_rate']:.1%}")
        print(f"Duration: {duration:.1f} seconds")

        if passed_tests == total_tests:
            print("\n🎉 ALL TESTS PASSED! AquaTrack ML pipeline is ready!")
        else:
            print("\n⚠️  Some tests failed. Check individual results above.")

        # Save detailed results
        results_file = self.test_dir / "end_to_end_test_results.json"
        with open(results_file, 'w') as f:
            json.dump(summary, f, indent=2)

        print(f"\nDetailed results saved to: {results_file}")

        return summary


def main():
    """Run end-to-end test"""
    print("AquaTrack ML Pipeline End-to-End Test")
    print("Testing complete ML workflow with synthetic data...")

    # Install Pillow for image handling if not available
    try:
        from PIL import Image
    except ImportError:
        print("Installing Pillow for image handling...")
        os.system("pip install Pillow")
        from PIL import Image

    # Create and run test
    tester = EndToEndTester()
    results = tester.run_all_tests()

    return results


if __name__ == "__main__":
    main()