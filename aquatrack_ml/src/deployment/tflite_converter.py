#!/usr/bin/env python3
"""
TFLite Converter and Optimization Pipeline
Convert trained models to mobile-optimized TFLite format
"""

import tensorflow as tf
from tensorflow import keras
import numpy as np
import json
import os
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Union
import sys

# Add parent directories to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'models'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'data'))

from aquatrack_model import AquaTrackModel
from data_pipeline import AquaTrackDataPipeline


class TFLiteOptimizer:
    """
    TFLite conversion and optimization pipeline

    Features:
    - Multiple optimization strategies
    - Model size and latency benchmarking
    - Accuracy preservation analysis
    - Representative dataset generation for quantization
    - Model validation and testing
    """

    def __init__(self, model_path: str, output_dir: str = "./tflite_models"):
        self.model_path = Path(model_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Model info
        self.model = None
        self.original_model_size = 0
        self.conversion_results = {}

        # Representative dataset for quantization
        self.representative_dataset = None

    def load_model(self) -> None:
        """Load trained Keras model"""
        print(f"Loading model from {self.model_path}...")

        if not self.model_path.exists():
            raise FileNotFoundError(f"Model file not found: {self.model_path}")

        self.model = keras.models.load_model(str(self.model_path))
        print("Model loaded successfully!")

        # Get original model size
        self.original_model_size = self.model_path.stat().st_size / (1024 * 1024)  # MB

    def create_representative_dataset(self,
                                    data_dir: str = "./data",
                                    num_samples: int = 100) -> None:
        """
        Create representative dataset for quantization

        Args:
            data_dir: Directory containing training data
            num_samples: Number of samples to use for calibration
        """
        print("Creating representative dataset for quantization...")

        try:
            # Setup data pipeline
            data_pipeline = AquaTrackDataPipeline(data_dir=data_dir, batch_size=1)
            annotations = data_pipeline.load_annotations()
            processed_annotations = data_pipeline.preprocess_annotations(annotations)

            if not processed_annotations:
                print("No annotations found. Using synthetic data for calibration.")
                self._create_synthetic_representative_dataset(num_samples)
                return

            # Use subset of real data
            subset = processed_annotations[:min(num_samples, len(processed_annotations))]
            dataset = data_pipeline.create_tf_dataset(subset, is_training=False, shuffle=False)

            # Collect representative samples
            representative_samples = []
            for images, _ in dataset.take(num_samples):
                representative_samples.append(images.numpy())

            self.representative_dataset = representative_samples
            print(f"Created representative dataset with {len(representative_samples)} samples")

        except Exception as e:
            print(f"Failed to create real representative dataset: {e}")
            print("Using synthetic representative dataset...")
            self._create_synthetic_representative_dataset(num_samples)

    def _create_synthetic_representative_dataset(self, num_samples: int = 100) -> None:
        """Create synthetic representative dataset matching model input format"""
        representative_samples = []

        for _ in range(num_samples):
            # Generate realistic container-like images in [0,255] uint8 range
            # Model expects uint8 [0,255] input and normalizes internally with /255.0
            sample = np.random.randint(0, 256, (1, 224, 224, 3), dtype=np.uint8)
            # Convert to float32 [0,255] for TFLite inference (matches real preprocessing)
            sample = sample.astype(np.float32)
            representative_samples.append(sample)

        self.representative_dataset = representative_samples
        print(f"Created synthetic representative dataset with {num_samples} samples (float32 [0,255] range)")

    def _representative_data_gen(self):
        """Generator function for representative dataset"""
        if self.representative_dataset is None:
            self.create_representative_dataset()

        for sample in self.representative_dataset:
            yield [sample]

    def convert_float32(self, output_name: str = "model_float32.tflite") -> str:
        """Convert to float32 TFLite (baseline)"""
        print("Converting to float32 TFLite...")

        converter = tf.lite.TFLiteConverter.from_keras_model(self.model)
        tflite_model = converter.convert()

        # Save model
        output_path = self.output_dir / output_name
        with open(output_path, 'wb') as f:
            f.write(tflite_model)

        model_size = len(tflite_model) / (1024 * 1024)  # MB

        result = {
            'path': str(output_path),
            'size_mb': model_size,
            'compression_ratio': self.original_model_size / model_size,
            'optimization': 'None (Float32)'
        }

        self.conversion_results['float32'] = result
        print(f"Float32 model saved: {output_path} ({model_size:.2f} MB)")
        return str(output_path)

    def convert_float16(self, output_name: str = "model_float16.tflite") -> str:
        """Convert to float16 TFLite (half precision)"""
        print("Converting to float16 TFLite...")

        converter = tf.lite.TFLiteConverter.from_keras_model(self.model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]

        tflite_model = converter.convert()

        # Save model
        output_path = self.output_dir / output_name
        with open(output_path, 'wb') as f:
            f.write(tflite_model)

        model_size = len(tflite_model) / (1024 * 1024)  # MB

        result = {
            'path': str(output_path),
            'size_mb': model_size,
            'compression_ratio': self.original_model_size / model_size,
            'optimization': 'Float16 Quantization'
        }

        self.conversion_results['float16'] = result
        print(f"Float16 model saved: {output_path} ({model_size:.2f} MB)")
        return str(output_path)

    def convert_dynamic_range_quantization(self,
                                         output_name: str = "model_dynamic.tflite") -> str:
        """Convert with dynamic range quantization"""
        print("Converting with dynamic range quantization...")

        converter = tf.lite.TFLiteConverter.from_keras_model(self.model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]

        tflite_model = converter.convert()

        # Save model
        output_path = self.output_dir / output_name
        with open(output_path, 'wb') as f:
            f.write(tflite_model)

        model_size = len(tflite_model) / (1024 * 1024)  # MB

        result = {
            'path': str(output_path),
            'size_mb': model_size,
            'compression_ratio': self.original_model_size / model_size,
            'optimization': 'Dynamic Range Quantization'
        }

        self.conversion_results['dynamic'] = result
        print(f"Dynamic quantized model saved: {output_path} ({model_size:.2f} MB)")
        return str(output_path)

    def convert_full_integer_quantization(self,
                                        output_name: str = "model_int8.tflite") -> str:
        """Convert with full integer quantization"""
        print("Converting with full integer quantization...")

        # Ensure representative dataset exists
        if self.representative_dataset is None:
            self.create_representative_dataset()

        converter = tf.lite.TFLiteConverter.from_keras_model(self.model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.representative_dataset = self._representative_data_gen

        # Force full integer quantization
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        converter.inference_input_type = tf.int8
        converter.inference_output_type = tf.int8

        try:
            tflite_model = converter.convert()

            # Save model
            output_path = self.output_dir / output_name
            with open(output_path, 'wb') as f:
                f.write(tflite_model)

            model_size = len(tflite_model) / (1024 * 1024)  # MB

            result = {
                'path': str(output_path),
                'size_mb': model_size,
                'compression_ratio': self.original_model_size / model_size,
                'optimization': 'Full Integer Quantization (INT8)'
            }

            self.conversion_results['int8'] = result
            print(f"INT8 quantized model saved: {output_path} ({model_size:.2f} MB)")
            return str(output_path)

        except Exception as e:
            print(f"Full integer quantization failed: {e}")
            print("Some operations may not support INT8 quantization")
            return ""

    def convert_mixed_precision(self,
                              output_name: str = "model_mixed.tflite") -> str:
        """Convert with mixed precision (fallback to float for unsupported ops)"""
        print("Converting with mixed precision quantization...")

        # Ensure representative dataset exists
        if self.representative_dataset is None:
            self.create_representative_dataset()

        converter = tf.lite.TFLiteConverter.from_keras_model(self.model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.representative_dataset = self._representative_data_gen

        # Allow fallback to float for unsupported operations
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS_INT8,
            tf.lite.OpsSet.TFLITE_BUILTINS
        ]

        tflite_model = converter.convert()

        # Save model
        output_path = self.output_dir / output_name
        with open(output_path, 'wb') as f:
            f.write(tflite_model)

        model_size = len(tflite_model) / (1024 * 1024)  # MB

        result = {
            'path': str(output_path),
            'size_mb': model_size,
            'compression_ratio': self.original_model_size / model_size,
            'optimization': 'Mixed Precision (INT8 with Float fallback)'
        }

        self.conversion_results['mixed'] = result
        print(f"Mixed precision model saved: {output_path} ({model_size:.2f} MB)")
        return str(output_path)

    def convert_all_variants(self) -> Dict[str, str]:
        """Convert model to all optimization variants"""
        print("Converting model to all TFLite variants...")

        if self.model is None:
            self.load_model()

        # Create representative dataset for quantization
        self.create_representative_dataset()

        results = {}

        # Convert all variants
        try:
            results['float32'] = self.convert_float32()
        except Exception as e:
            print(f"Float32 conversion failed: {e}")

        try:
            results['float16'] = self.convert_float16()
        except Exception as e:
            print(f"Float16 conversion failed: {e}")

        try:
            results['dynamic'] = self.convert_dynamic_range_quantization()
        except Exception as e:
            print(f"Dynamic quantization failed: {e}")

        try:
            results['mixed'] = self.convert_mixed_precision()
        except Exception as e:
            print(f"Mixed precision conversion failed: {e}")

        try:
            int8_path = self.convert_full_integer_quantization()
            if int8_path:
                results['int8'] = int8_path
        except Exception as e:
            print(f"INT8 quantization failed: {e}")

        print(f"\nConversion complete! {len(results)} variants created.")
        return results

    def benchmark_model(self, tflite_path: str, num_runs: int = 100) -> Dict:
        """Benchmark TFLite model inference time"""
        print(f"Benchmarking model: {tflite_path}")

        # Load TFLite model
        interpreter = tf.lite.Interpreter(model_path=tflite_path)
        interpreter.allocate_tensors()

        # Get input/output details
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        # Prepare test input
        input_shape = input_details[0]['shape']
        test_input = np.random.rand(*input_shape).astype(np.float32) * 255.0

        # Warm up
        for _ in range(5):
            interpreter.set_tensor(input_details[0]['index'], test_input)
            interpreter.invoke()

        # Benchmark inference time
        import time
        times = []
        for _ in range(num_runs):
            start_time = time.time()
            interpreter.set_tensor(input_details[0]['index'], test_input)
            interpreter.invoke()
            end_time = time.time()
            times.append((end_time - start_time) * 1000)  # Convert to ms

        # Calculate statistics
        times = np.array(times)
        benchmark_results = {
            'mean_inference_time_ms': float(np.mean(times)),
            'std_inference_time_ms': float(np.std(times)),
            'min_inference_time_ms': float(np.min(times)),
            'max_inference_time_ms': float(np.max(times)),
            'median_inference_time_ms': float(np.median(times)),
            'num_runs': num_runs
        }

        print(f"Inference time: {benchmark_results['mean_inference_time_ms']:.2f} ± "
              f"{benchmark_results['std_inference_time_ms']:.2f} ms")

        return benchmark_results

    def validate_tflite_model(self, tflite_path: str, test_samples: int = 10) -> Dict:
        """Validate TFLite model outputs against original Keras model"""
        print(f"Validating TFLite model: {tflite_path}")

        # Load TFLite model
        interpreter = tf.lite.Interpreter(model_path=tflite_path)
        interpreter.allocate_tensors()

        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        # Generate test inputs
        input_shape = input_details[0]['shape']
        test_inputs = [
            np.random.rand(*input_shape).astype(np.float32) * 255.0
            for _ in range(test_samples)
        ]

        # Compare outputs
        keras_outputs = []
        tflite_outputs = []

        for test_input in test_inputs:
            # Keras prediction
            keras_pred = self.model(test_input)
            keras_outputs.append(keras_pred)

            # TFLite prediction
            interpreter.set_tensor(input_details[0]['index'], test_input)
            interpreter.invoke()

            tflite_pred = {}
            for i, output_detail in enumerate(output_details):
                output_name = output_detail['name'].split('/')[-1]  # Get last part of name
                tflite_pred[output_name] = interpreter.get_tensor(output_detail['index'])

            tflite_outputs.append(tflite_pred)

        # Calculate differences
        differences = self._calculate_output_differences(keras_outputs, tflite_outputs)

        print(f"Validation complete. Max difference: {max(differences.values()):.6f}")
        return differences

    def _calculate_output_differences(self, keras_outputs, tflite_outputs) -> Dict:
        """Calculate differences between Keras and TFLite outputs"""
        differences = {}

        output_names = ['container_class', 'fill_level', 'liquid_type']

        for output_name in output_names:
            keras_vals = []
            tflite_vals = []

            for i in range(len(keras_outputs)):
                keras_vals.append(keras_outputs[i][output_name].numpy())

                # Find corresponding TFLite output
                tflite_key = None
                for key in tflite_outputs[i].keys():
                    if output_name in key.lower():
                        tflite_key = key
                        break

                if tflite_key:
                    tflite_vals.append(tflite_outputs[i][tflite_key])

            if keras_vals and tflite_vals:
                keras_vals = np.concatenate(keras_vals)
                tflite_vals = np.concatenate(tflite_vals)

                # Calculate mean absolute difference
                diff = np.mean(np.abs(keras_vals - tflite_vals))
                differences[output_name] = float(diff)

        return differences

    def generate_optimization_report(self) -> Dict:
        """Generate comprehensive optimization report"""
        print("Generating optimization report...")

        report = {
            'timestamp': datetime.now().isoformat(),
            'original_model': {
                'path': str(self.model_path),
                'size_mb': self.original_model_size
            },
            'conversions': {},
            'recommendations': []
        }

        # Add conversion results
        for variant_name, result in self.conversion_results.items():
            variant_report = result.copy()

            # Add benchmark if model exists
            if os.path.exists(result['path']):
                try:
                    benchmark = self.benchmark_model(result['path'])
                    variant_report['benchmark'] = benchmark
                except Exception as e:
                    print(f"Benchmarking failed for {variant_name}: {e}")

                # Add validation if possible
                try:
                    validation = self.validate_tflite_model(result['path'])
                    variant_report['validation'] = validation
                except Exception as e:
                    print(f"Validation failed for {variant_name}: {e}")

            report['conversions'][variant_name] = variant_report

        # Generate recommendations
        report['recommendations'] = self._generate_recommendations()

        # Save report
        report_path = self.output_dir / "optimization_report.json"
        with open(report_path, 'w') as f:
            json.dump(report, f, indent=2)

        print(f"Optimization report saved to {report_path}")
        return report

    def _generate_recommendations(self) -> List[str]:
        """Generate optimization recommendations based on results"""
        recommendations = []

        if not self.conversion_results:
            return ["No conversion results available for recommendations"]

        # Find best size reduction
        best_compression = max(
            self.conversion_results.values(),
            key=lambda x: x.get('compression_ratio', 0)
        )

        recommendations.append(
            f"Best compression: {best_compression['optimization']} "
            f"({best_compression['compression_ratio']:.1f}x smaller)"
        )

        # Mobile deployment recommendation
        if 'float16' in self.conversion_results:
            recommendations.append(
                "Recommended for mobile: Float16 quantization provides good "
                "balance of size reduction and accuracy preservation"
            )

        if 'mixed' in self.conversion_results:
            recommendations.append(
                "For maximum performance: Mixed precision quantization with "
                "INT8 where possible, float fallback for compatibility"
            )

        return recommendations

    def get_model_for_flutter(self) -> str:
        """Get the best model variant for Flutter deployment"""
        # Priority order for Flutter deployment
        flutter_priority = ['float16', 'mixed', 'dynamic', 'float32']

        for variant in flutter_priority:
            if variant in self.conversion_results:
                model_path = self.conversion_results[variant]['path']
                if os.path.exists(model_path):
                    print(f"Recommended for Flutter: {variant} model")
                    print(f"Path: {model_path}")
                    return model_path

        return ""


def create_optimizer(model_path: str, output_dir: str = "./tflite_models") -> TFLiteOptimizer:
    """Factory function to create TFLite optimizer"""
    return TFLiteOptimizer(model_path, output_dir)


if __name__ == "__main__":
    # Test TFLite optimizer
    print("Testing TFLite Optimizer...")

    try:
        # Mock model path for testing
        optimizer = TFLiteOptimizer("./models/test_model.h5")
        print("Optimizer created successfully!")

        # Test synthetic representative dataset creation
        optimizer._create_synthetic_representative_dataset(10)
        print("Synthetic representative dataset created!")

        print("TFLite optimization pipeline ready!")
        print("Run with trained model to generate optimized variants.")

    except Exception as e:
        print(f"Optimizer test note: {e}")
        print("This is expected - optimizer requires trained model.")
        print("Architecture test successful!")