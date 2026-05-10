#!/usr/bin/env python3
"""
AquaTrack Model Evaluator
Comprehensive evaluation framework with metrics and visualization
"""

import tensorflow as tf
from tensorflow import keras
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import json
import os
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Union
from sklearn.metrics import (
    accuracy_score, precision_recall_fscore_support,
    confusion_matrix, classification_report,
    mean_absolute_error, mean_squared_error, r2_score
)
import sys

# Add parent directories to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'models'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'data'))

from aquatrack_model import AquaTrackModel
from data_pipeline import AquaTrackDataPipeline


class AquaTrackEvaluator:
    """
    Comprehensive evaluation framework for AquaTrack model

    Features:
    - Multi-output performance metrics
    - Confusion matrices and classification reports
    - Regression analysis for fill level
    - Error analysis and visualization
    - Performance comparison across container/liquid types
    - Model calibration analysis
    """

    def __init__(self, model_path: str, data_dir: str = "./data"):
        self.model_path = Path(model_path)
        self.data_dir = Path(data_dir)
        self.model = None
        self.data_pipeline = None

        # Class mappings
        self.container_classes = [
            'glass_small', 'glass_large', 'cup_plastic', 'bottle_500',
            'bottle_750', 'bottle_1000', 'bottle_1500', 'mug',
            'can_330', 'other'
        ]
        self.liquid_classes = ['water', 'tea', 'coffee', 'juice', 'smoothie']

        # Results storage
        self.evaluation_results = {}
        self.predictions = None
        self.ground_truth = None

    def load_model(self) -> None:
        """Load trained model"""
        print(f"Loading model from {self.model_path}...")

        if not self.model_path.exists():
            raise FileNotFoundError(f"Model file not found: {self.model_path}")

        self.model = keras.models.load_model(str(self.model_path))
        print("Model loaded successfully!")

    def setup_data(self, batch_size: int = 32) -> None:
        """Setup data pipeline for evaluation"""
        print("Setting up data pipeline...")

        self.data_pipeline = AquaTrackDataPipeline(
            data_dir=str(self.data_dir),
            batch_size=batch_size
        )

    def predict_on_dataset(self, dataset: tf.data.Dataset) -> Tuple[Dict, Dict]:
        """
        Make predictions on dataset and collect ground truth

        Returns:
            predictions: Dict with model outputs
            ground_truth: Dict with true labels
        """
        if self.model is None:
            raise ValueError("Model not loaded. Call load_model() first.")

        print("Making predictions on dataset...")

        # Collect predictions and ground truth
        all_predictions = {
            'container_class': [],
            'fill_level': [],
            'liquid_type': []
        }

        all_ground_truth = {
            'container_class': [],
            'fill_level': [],
            'liquid_type': []
        }

        # Predict batch by batch
        for batch_images, batch_labels in dataset:
            # Get predictions
            batch_preds = self.model(batch_images)

            # Store predictions
            all_predictions['container_class'].extend(batch_preds['container_class'].numpy())
            all_predictions['fill_level'].extend(batch_preds['fill_level'].numpy().flatten())
            all_predictions['liquid_type'].extend(batch_preds['liquid_type'].numpy())

            # Store ground truth
            all_ground_truth['container_class'].extend(batch_labels['container_class'].numpy())
            all_ground_truth['fill_level'].extend(batch_labels['fill_level'].numpy())
            all_ground_truth['liquid_type'].extend(batch_labels['liquid_type'].numpy())

        # Convert to numpy arrays
        predictions = {
            'container_class_probs': np.array(all_predictions['container_class']),
            'container_class_pred': np.argmax(all_predictions['container_class'], axis=1),
            'fill_level_pred': np.array(all_predictions['fill_level']),
            'liquid_type_probs': np.array(all_predictions['liquid_type']),
            'liquid_type_pred': np.argmax(all_predictions['liquid_type'], axis=1)
        }

        ground_truth = {
            'container_class_true': np.array(all_ground_truth['container_class']),
            'fill_level_true': np.array(all_ground_truth['fill_level']),
            'liquid_type_true': np.array(all_ground_truth['liquid_type'])
        }

        print(f"Predictions collected for {len(ground_truth['container_class_true'])} samples")

        self.predictions = predictions
        self.ground_truth = ground_truth

        return predictions, ground_truth

    def calculate_classification_metrics(self,
                                       y_true: np.ndarray,
                                       y_pred: np.ndarray,
                                       y_probs: np.ndarray,
                                       class_names: List[str]) -> Dict:
        """Calculate comprehensive classification metrics"""

        # Basic metrics
        accuracy = accuracy_score(y_true, y_pred)
        precision, recall, f1, support = precision_recall_fscore_support(
            y_true, y_pred, average='weighted'
        )

        # Per-class metrics
        precision_per_class, recall_per_class, f1_per_class, support_per_class = \
            precision_recall_fscore_support(y_true, y_pred, average=None)

        # Confusion matrix
        cm = confusion_matrix(y_true, y_pred)

        # Top-k accuracy
        top_2_accuracy = self.calculate_top_k_accuracy(y_true, y_probs, k=2)
        top_3_accuracy = self.calculate_top_k_accuracy(y_true, y_probs, k=3)

        return {
            'accuracy': float(accuracy),
            'precision_weighted': float(precision),
            'recall_weighted': float(recall),
            'f1_weighted': float(f1),
            'top_2_accuracy': float(top_2_accuracy),
            'top_3_accuracy': float(top_3_accuracy),
            'per_class_metrics': {
                class_names[i]: {
                    'precision': float(precision_per_class[i]),
                    'recall': float(recall_per_class[i]),
                    'f1': float(f1_per_class[i]),
                    'support': int(support_per_class[i])
                } for i in range(len(class_names))
            },
            'confusion_matrix': cm.tolist(),
            'classification_report': classification_report(
                y_true, y_pred, target_names=class_names, output_dict=True
            )
        }

    def calculate_regression_metrics(self, y_true: np.ndarray, y_pred: np.ndarray) -> Dict:
        """Calculate regression metrics for fill level prediction"""

        # Basic regression metrics
        mae = mean_absolute_error(y_true, y_pred)
        mse = mean_squared_error(y_true, y_pred)
        rmse = np.sqrt(mse)
        r2 = r2_score(y_true, y_pred)

        # Custom metrics for fill level
        absolute_errors = np.abs(y_true - y_pred)

        # Accuracy within tolerance levels
        acc_5_percent = np.mean(absolute_errors < 0.05)  # 5% tolerance
        acc_10_percent = np.mean(absolute_errors < 0.10)  # 10% tolerance
        acc_15_percent = np.mean(absolute_errors < 0.15)  # 15% tolerance

        # Percentile errors
        error_percentiles = np.percentile(absolute_errors, [50, 75, 90, 95, 99])

        return {
            'mae': float(mae),
            'mse': float(mse),
            'rmse': float(rmse),
            'r2_score': float(r2),
            'accuracy_5_percent': float(acc_5_percent),
            'accuracy_10_percent': float(acc_10_percent),
            'accuracy_15_percent': float(acc_15_percent),
            'median_absolute_error': float(error_percentiles[0]),
            'error_75th_percentile': float(error_percentiles[1]),
            'error_90th_percentile': float(error_percentiles[2]),
            'error_95th_percentile': float(error_percentiles[3]),
            'error_99th_percentile': float(error_percentiles[4]),
            'max_error': float(np.max(absolute_errors)),
            'std_error': float(np.std(absolute_errors))
        }

    def calculate_top_k_accuracy(self, y_true: np.ndarray, y_probs: np.ndarray, k: int) -> float:
        """Calculate top-k accuracy"""
        top_k_preds = np.argsort(y_probs, axis=1)[:, -k:]
        return np.mean([y_true[i] in top_k_preds[i] for i in range(len(y_true))])

    def evaluate_comprehensive(self, dataset: tf.data.Dataset) -> Dict:
        """Run comprehensive evaluation on dataset"""
        print("Running comprehensive evaluation...")

        # Get predictions
        predictions, ground_truth = self.predict_on_dataset(dataset)

        # Container classification metrics
        container_metrics = self.calculate_classification_metrics(
            ground_truth['container_class_true'],
            predictions['container_class_pred'],
            predictions['container_class_probs'],
            self.container_classes
        )

        # Liquid classification metrics
        liquid_metrics = self.calculate_classification_metrics(
            ground_truth['liquid_type_true'],
            predictions['liquid_type_pred'],
            predictions['liquid_type_probs'],
            self.liquid_classes
        )

        # Fill level regression metrics
        fill_metrics = self.calculate_regression_metrics(
            ground_truth['fill_level_true'],
            predictions['fill_level_pred']
        )

        # Combined metrics (all predictions correct)
        combined_accuracy = self.calculate_combined_accuracy()

        # Error analysis
        error_analysis = self.analyze_prediction_errors()

        # Compile results
        self.evaluation_results = {
            'timestamp': datetime.now().isoformat(),
            'dataset_size': len(ground_truth['container_class_true']),
            'container_classification': container_metrics,
            'liquid_classification': liquid_metrics,
            'fill_level_regression': fill_metrics,
            'combined_accuracy': combined_accuracy,
            'error_analysis': error_analysis
        }

        print("Comprehensive evaluation completed!")
        return self.evaluation_results

    def calculate_combined_accuracy(self) -> Dict:
        """Calculate accuracy when all three outputs are correct"""
        if self.predictions is None or self.ground_truth is None:
            return {}

        # Correct predictions for each task
        container_correct = (
            self.ground_truth['container_class_true'] ==
            self.predictions['container_class_pred']
        )

        fill_correct = (
            np.abs(self.ground_truth['fill_level_true'] -
                  self.predictions['fill_level_pred']) < 0.1  # 10% tolerance
        )

        liquid_correct = (
            self.ground_truth['liquid_type_true'] ==
            self.predictions['liquid_type_pred']
        )

        # Combined accuracy
        all_correct = container_correct & fill_correct & liquid_correct
        combined_accuracy = np.mean(all_correct)

        # Partial accuracy combinations
        container_fill = np.mean(container_correct & fill_correct)
        container_liquid = np.mean(container_correct & liquid_correct)
        fill_liquid = np.mean(fill_correct & liquid_correct)

        return {
            'all_three_correct': float(combined_accuracy),
            'container_and_fill': float(container_fill),
            'container_and_liquid': float(container_liquid),
            'fill_and_liquid': float(fill_liquid),
            'at_least_two_correct': float(np.mean(
                (container_correct + fill_correct + liquid_correct) >= 2
            ))
        }

    def analyze_prediction_errors(self) -> Dict:
        """Analyze patterns in prediction errors"""
        if self.predictions is None or self.ground_truth is None:
            return {}

        errors = {}

        # Container classification errors by class
        container_errors = {}
        for i, class_name in enumerate(self.container_classes):
            mask = self.ground_truth['container_class_true'] == i
            if np.sum(mask) > 0:
                class_accuracy = np.mean(
                    self.predictions['container_class_pred'][mask] == i
                )
                container_errors[class_name] = {
                    'accuracy': float(class_accuracy),
                    'sample_count': int(np.sum(mask))
                }

        # Liquid classification errors by class
        liquid_errors = {}
        for i, class_name in enumerate(self.liquid_classes):
            mask = self.ground_truth['liquid_type_true'] == i
            if np.sum(mask) > 0:
                class_accuracy = np.mean(
                    self.predictions['liquid_type_pred'][mask] == i
                )
                liquid_errors[class_name] = {
                    'accuracy': float(class_accuracy),
                    'sample_count': int(np.sum(mask))
                }

        # Fill level errors by range
        fill_ranges = {
            'empty (0-0.2)': (0.0, 0.2),
            'low (0.2-0.4)': (0.2, 0.4),
            'medium (0.4-0.6)': (0.4, 0.6),
            'high (0.6-0.8)': (0.6, 0.8),
            'full (0.8-1.0)': (0.8, 1.0)
        }

        fill_errors = {}
        for range_name, (min_val, max_val) in fill_ranges.items():
            mask = (
                (self.ground_truth['fill_level_true'] >= min_val) &
                (self.ground_truth['fill_level_true'] < max_val)
            )
            if np.sum(mask) > 0:
                range_mae = np.mean(np.abs(
                    self.ground_truth['fill_level_true'][mask] -
                    self.predictions['fill_level_pred'][mask]
                ))
                fill_errors[range_name] = {
                    'mae': float(range_mae),
                    'sample_count': int(np.sum(mask))
                }

        return {
            'container_errors_by_class': container_errors,
            'liquid_errors_by_class': liquid_errors,
            'fill_level_errors_by_range': fill_errors
        }

    def create_visualizations(self, output_dir: Optional[str] = None) -> Dict[str, str]:
        """Create evaluation visualizations"""
        if output_dir is None:
            output_dir = "./evaluation_plots"

        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)

        plot_files = {}

        if self.predictions is None or self.ground_truth is None:
            print("No predictions available. Run evaluation first.")
            return plot_files

        # Set style
        plt.style.use('default')
        sns.set_palette("husl")

        # 1. Container confusion matrix
        plt.figure(figsize=(10, 8))
        cm = confusion_matrix(
            self.ground_truth['container_class_true'],
            self.predictions['container_class_pred']
        )
        sns.heatmap(
            cm, annot=True, fmt='d', cmap='Blues',
            xticklabels=self.container_classes,
            yticklabels=self.container_classes
        )
        plt.title('Container Classification Confusion Matrix')
        plt.ylabel('True Label')
        plt.xlabel('Predicted Label')
        plt.xticks(rotation=45, ha='right')
        plt.yticks(rotation=0)
        plt.tight_layout()

        container_cm_path = output_dir / "container_confusion_matrix.png"
        plt.savefig(container_cm_path, dpi=300, bbox_inches='tight')
        plt.close()
        plot_files['container_confusion_matrix'] = str(container_cm_path)

        # 2. Fill level regression plot
        plt.figure(figsize=(10, 8))
        plt.scatter(
            self.ground_truth['fill_level_true'],
            self.predictions['fill_level_pred'],
            alpha=0.6, s=50
        )
        plt.plot([0, 1], [0, 1], 'r--', lw=2, label='Perfect Prediction')
        plt.xlabel('True Fill Level')
        plt.ylabel('Predicted Fill Level')
        plt.title('Fill Level Prediction Scatter Plot')
        plt.legend()
        plt.grid(True, alpha=0.3)

        fill_scatter_path = output_dir / "fill_level_scatter.png"
        plt.savefig(fill_scatter_path, dpi=300, bbox_inches='tight')
        plt.close()
        plot_files['fill_level_scatter'] = str(fill_scatter_path)

        # 3. Fill level error distribution
        plt.figure(figsize=(10, 6))
        errors = np.abs(
            self.ground_truth['fill_level_true'] -
            self.predictions['fill_level_pred']
        )
        plt.hist(errors, bins=50, alpha=0.7, edgecolor='black')
        plt.axvline(np.mean(errors), color='red', linestyle='--',
                   label=f'Mean Error: {np.mean(errors):.3f}')
        plt.xlabel('Absolute Error')
        plt.ylabel('Frequency')
        plt.title('Fill Level Prediction Error Distribution')
        plt.legend()
        plt.grid(True, alpha=0.3)

        error_hist_path = output_dir / "fill_level_error_histogram.png"
        plt.savefig(error_hist_path, dpi=300, bbox_inches='tight')
        plt.close()
        plot_files['fill_level_error_histogram'] = str(error_hist_path)

        # 4. Liquid confusion matrix
        plt.figure(figsize=(8, 6))
        cm_liquid = confusion_matrix(
            self.ground_truth['liquid_type_true'],
            self.predictions['liquid_type_pred']
        )
        sns.heatmap(
            cm_liquid, annot=True, fmt='d', cmap='Greens',
            xticklabels=self.liquid_classes,
            yticklabels=self.liquid_classes
        )
        plt.title('Liquid Type Classification Confusion Matrix')
        plt.ylabel('True Label')
        plt.xlabel('Predicted Label')
        plt.tight_layout()

        liquid_cm_path = output_dir / "liquid_confusion_matrix.png"
        plt.savefig(liquid_cm_path, dpi=300, bbox_inches='tight')
        plt.close()
        plot_files['liquid_confusion_matrix'] = str(liquid_cm_path)

        print(f"Visualizations saved to {output_dir}")
        return plot_files

    def save_results(self, output_path: str) -> None:
        """Save evaluation results to JSON file"""
        if not self.evaluation_results:
            print("No evaluation results to save. Run evaluation first.")
            return

        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        with open(output_path, 'w') as f:
            json.dump(self.evaluation_results, f, indent=2)

        print(f"Evaluation results saved to {output_path}")

    def print_summary(self) -> None:
        """Print evaluation summary"""
        if not self.evaluation_results:
            print("No evaluation results available. Run evaluation first.")
            return

        results = self.evaluation_results

        print("\n" + "="*60)
        print("AQUATRACK MODEL EVALUATION SUMMARY")
        print("="*60)

        print(f"Dataset Size: {results['dataset_size']} samples")
        print(f"Evaluation Date: {results['timestamp']}")

        print("\n📦 CONTAINER CLASSIFICATION:")
        container = results['container_classification']
        print(f"  Accuracy: {container['accuracy']:.3f}")
        print(f"  F1-Score: {container['f1_weighted']:.3f}")
        print(f"  Top-2 Accuracy: {container['top_2_accuracy']:.3f}")

        print("\n🥤 LIQUID CLASSIFICATION:")
        liquid = results['liquid_classification']
        print(f"  Accuracy: {liquid['accuracy']:.3f}")
        print(f"  F1-Score: {liquid['f1_weighted']:.3f}")
        print(f"  Top-2 Accuracy: {liquid['top_2_accuracy']:.3f}")

        print("\n📏 FILL LEVEL REGRESSION:")
        fill = results['fill_level_regression']
        print(f"  Mean Absolute Error: {fill['mae']:.3f}")
        print(f"  R² Score: {fill['r2_score']:.3f}")
        print(f"  10% Tolerance Accuracy: {fill['accuracy_10_percent']:.3f}")

        print("\n🎯 COMBINED PERFORMANCE:")
        combined = results['combined_accuracy']
        print(f"  All Three Correct: {combined['all_three_correct']:.3f}")
        print(f"  At Least Two Correct: {combined['at_least_two_correct']:.3f}")

        print("\n" + "="*60)


def create_evaluator(model_path: str, data_dir: str = "./data") -> AquaTrackEvaluator:
    """Factory function to create evaluator"""
    return AquaTrackEvaluator(model_path, data_dir)


if __name__ == "__main__":
    # Test evaluator setup
    print("Testing AquaTrack Evaluator...")

    # Note: This will fail without a trained model, but tests architecture
    try:
        # Mock model path for testing
        evaluator = AquaTrackEvaluator("./models/test_model.h5")
        print("Evaluator created successfully!")
        print("Ready for model evaluation when model is available.")

    except Exception as e:
        print(f"Evaluator test note: {e}")
        print("This is expected - evaluator requires trained model.")
        print("Architecture test successful!")