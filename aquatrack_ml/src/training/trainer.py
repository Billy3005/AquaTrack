#!/usr/bin/env python3
"""
AquaTrack Model Trainer
Complete training pipeline with multi-output optimization
"""

import tensorflow as tf
from tensorflow import keras
import numpy as np
import json
import os
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import sys

# Add parent directories to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'models'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'data'))

from aquatrack_model import AquaTrackModel
from data_pipeline import AquaTrackDataPipeline


class AquaTrackTrainer:
    """
    Trainer class for AquaTrack multi-output model

    Handles:
    - Model creation and compilation
    - Data loading and preprocessing
    - Training with callbacks and monitoring
    - Model evaluation and validation
    - Checkpointing and saving
    """

    def __init__(self,
                 data_dir: str = "./data",
                 experiment_name: Optional[str] = None,
                 output_dir: str = "./models"):
        self.data_dir = Path(data_dir)
        self.output_dir = Path(output_dir)

        # Create experiment name if not provided
        if experiment_name is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            experiment_name = f"aquatrack_{timestamp}"

        self.experiment_name = experiment_name
        self.experiment_dir = self.output_dir / experiment_name

        # Create directories
        self.experiment_dir.mkdir(parents=True, exist_ok=True)
        (self.experiment_dir / "checkpoints").mkdir(exist_ok=True)
        (self.experiment_dir / "logs").mkdir(exist_ok=True)

        # Initialize components
        self.model_builder = None
        self.model = None
        self.data_pipeline = None
        self.train_dataset = None
        self.val_dataset = None
        self.test_dataset = None

        # Training history
        self.history = None

    def setup_data(self,
                   batch_size: int = 32,
                   train_ratio: float = 0.8,
                   val_ratio: float = 0.1,
                   test_ratio: float = 0.1) -> None:
        """Setup data pipeline and load datasets"""
        print("Setting up data pipeline...")

        # Initialize data pipeline
        self.data_pipeline = AquaTrackDataPipeline(
            data_dir=str(self.data_dir),
            batch_size=batch_size
        )

        # Load and preprocess annotations
        annotations = self.data_pipeline.load_annotations()
        processed_annotations = self.data_pipeline.preprocess_annotations(annotations)

        if not processed_annotations:
            raise ValueError("No valid annotations found. Please collect dataset first.")

        # Analyze dataset
        stats = self.data_pipeline.analyze_dataset(processed_annotations)
        print(f"Dataset statistics: {stats}")

        # Split data
        train_data, val_data, test_data = self.data_pipeline.split_annotations(
            processed_annotations, train_ratio, val_ratio, test_ratio
        )

        # Create datasets
        self.train_dataset = self.data_pipeline.create_tf_dataset(
            train_data, is_training=True, shuffle=True
        )
        self.val_dataset = self.data_pipeline.create_tf_dataset(
            val_data, is_training=False, shuffle=False
        )
        self.test_dataset = self.data_pipeline.create_tf_dataset(
            test_data, is_training=False, shuffle=False
        )

        # Calculate class weights for imbalanced data
        self.class_weights = self.data_pipeline.get_class_weights(train_data)

        # Save dataset info
        dataset_info = {
            'total_samples': len(processed_annotations),
            'train_samples': len(train_data),
            'val_samples': len(val_data),
            'test_samples': len(test_data),
            'batch_size': batch_size,
            'stats': stats,
            'class_weights': {k: v.tolist() for k, v in self.class_weights.items()}
        }

        with open(self.experiment_dir / "dataset_info.json", 'w') as f:
            json.dump(dataset_info, f, indent=2)

        print(f"Data setup complete: {len(train_data)} train, {len(val_data)} val, {len(test_data)} test")

    def setup_model(self,
                   learning_rate: float = 0.001,
                   container_weight: float = 1.0,
                   fill_weight: float = 2.0,
                   liquid_weight: float = 1.0) -> None:
        """Setup model and compile with loss functions"""
        print("Setting up model...")

        # Create model
        self.model_builder = AquaTrackModel()
        self.model = self.model_builder.create_model()

        # Compile with weighted losses
        self.model_builder.compile_model(
            learning_rate=learning_rate,
            container_weight=container_weight,
            fill_weight=fill_weight,
            liquid_weight=liquid_weight
        )

        # Print model summary
        print(f"Model created with {self.model.count_params():,} parameters")

        # Save model architecture
        model_info = {
            'total_parameters': int(self.model.count_params()),
            'trainable_parameters': int(sum([tf.keras.utils.count_params(w) for w in self.model.trainable_weights])),
            'input_shape': self.model_builder.input_shape,
            'container_classes': self.model_builder.container_classes,
            'liquid_classes': self.model_builder.liquid_classes,
            'learning_rate': learning_rate,
            'loss_weights': {
                'container_class': container_weight,
                'fill_level': fill_weight,
                'liquid_type': liquid_weight
            }
        }

        with open(self.experiment_dir / "model_info.json", 'w') as f:
            json.dump(model_info, f, indent=2)

    def create_callbacks(self,
                        patience: int = 10,
                        reduce_lr_patience: int = 5,
                        min_lr: float = 1e-7) -> List[keras.callbacks.Callback]:
        """Create training callbacks"""
        callbacks = []

        # Model checkpoint
        checkpoint_path = str(self.experiment_dir / "checkpoints" / "best_model.h5")
        checkpoint_callback = keras.callbacks.ModelCheckpoint(
            checkpoint_path,
            monitor='val_loss',
            save_best_only=True,
            save_weights_only=False,
            mode='min',
            verbose=1
        )
        callbacks.append(checkpoint_callback)

        # Early stopping
        early_stopping = keras.callbacks.EarlyStopping(
            monitor='val_loss',
            patience=patience,
            restore_best_weights=True,
            verbose=1
        )
        callbacks.append(early_stopping)

        # Learning rate reduction
        reduce_lr = keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=reduce_lr_patience,
            min_lr=min_lr,
            verbose=1
        )
        callbacks.append(reduce_lr)

        # TensorBoard logging
        log_dir = str(self.experiment_dir / "logs")
        tensorboard = keras.callbacks.TensorBoard(
            log_dir=log_dir,
            histogram_freq=1,
            write_graph=True,
            write_images=True
        )
        callbacks.append(tensorboard)

        # Custom logging callback
        class MetricsLogger(keras.callbacks.Callback):
            def __init__(self, log_file):
                super().__init__()
                self.log_file = log_file
                self.metrics_history = []

            def on_epoch_end(self, epoch, logs=None):
                logs = logs or {}
                epoch_metrics = {'epoch': epoch + 1}
                epoch_metrics.update(logs)
                self.metrics_history.append(epoch_metrics)

                # Save metrics history
                with open(self.log_file, 'w') as f:
                    json.dump(self.metrics_history, f, indent=2)

        metrics_logger = MetricsLogger(str(self.experiment_dir / "training_metrics.json"))
        callbacks.append(metrics_logger)

        return callbacks

    def train(self,
             epochs: int = 100,
             patience: int = 10,
             reduce_lr_patience: int = 5,
             validation_freq: int = 1) -> keras.callbacks.History:
        """
        Train the model

        Args:
            epochs: Maximum number of training epochs
            patience: Early stopping patience
            reduce_lr_patience: Learning rate reduction patience
            validation_freq: Validation frequency (1 = every epoch)

        Returns:
            Training history
        """
        print(f"Starting training for {epochs} epochs...")

        # Ensure data and model are setup
        if self.train_dataset is None:
            raise ValueError("Data not setup. Call setup_data() first.")
        if self.model is None:
            raise ValueError("Model not setup. Call setup_model() first.")

        # Create callbacks
        callbacks = self.create_callbacks(patience, reduce_lr_patience)

        # Prepare class weights for multi-output model
        class_weight_dict = {
            'container_class': {i: self.class_weights['container'][i] for i in range(len(self.class_weights['container']))},
            'liquid_type': {i: self.class_weights['liquid'][i] for i in range(len(self.class_weights['liquid']))}
            # Note: fill_level is regression, no class weights needed
        }

        print(f"Using class weights: container={len(self.class_weights['container'])} classes, liquid={len(self.class_weights['liquid'])} classes")

        # Train model
        self.history = self.model.fit(
            self.train_dataset,
            epochs=epochs,
            validation_data=self.val_dataset,
            validation_freq=validation_freq,
            callbacks=callbacks,
            class_weight=class_weight_dict,
            verbose=1
        )

        print("Training completed!")

        # Save final model
        final_model_path = str(self.experiment_dir / "final_model.h5")
        self.model.save(final_model_path)
        print(f"Final model saved to {final_model_path}")

        return self.history

    def evaluate(self, dataset: Optional[tf.data.Dataset] = None) -> Dict:
        """Evaluate model on test dataset"""
        if dataset is None:
            dataset = self.test_dataset

        if dataset is None:
            raise ValueError("No test dataset available. Setup data first.")

        print("Evaluating model on test dataset...")

        # Evaluate model
        test_results = self.model.evaluate(dataset, verbose=1, return_dict=True)

        # Additional metrics calculation
        predictions = self.model.predict(dataset)
        metrics = self.calculate_detailed_metrics(dataset, predictions)

        # Combine results
        evaluation_results = {
            'test_loss_metrics': test_results,
            'detailed_metrics': metrics,
            'timestamp': datetime.now().isoformat()
        }

        # Save evaluation results
        with open(self.experiment_dir / "evaluation_results.json", 'w') as f:
            json.dump(evaluation_results, f, indent=2)

        print("Evaluation completed!")
        return evaluation_results

    def calculate_detailed_metrics(self,
                                 dataset: tf.data.Dataset,
                                 predictions: Dict) -> Dict:
        """Calculate additional metrics for multi-output model"""
        # Collect all ground truth labels
        all_container_labels = []
        all_fill_levels = []
        all_liquid_labels = []

        for _, labels_batch in dataset:
            all_container_labels.extend(labels_batch['container_class'].numpy())
            all_fill_levels.extend(labels_batch['fill_level'].numpy())
            all_liquid_labels.extend(labels_batch['liquid_type'].numpy())

        all_container_labels = np.array(all_container_labels)
        all_fill_levels = np.array(all_fill_levels)
        all_liquid_labels = np.array(all_liquid_labels)

        # Predictions
        container_preds = np.argmax(predictions['container_class'], axis=1)
        fill_preds = predictions['fill_level'].flatten()
        liquid_preds = np.argmax(predictions['liquid_type'], axis=1)

        # Calculate metrics
        from sklearn.metrics import accuracy_score, classification_report, mean_absolute_error, r2_score

        metrics = {}

        # Container classification metrics
        container_accuracy = accuracy_score(all_container_labels, container_preds)
        metrics['container_accuracy'] = float(container_accuracy)

        # Fill level regression metrics
        fill_mae = mean_absolute_error(all_fill_levels, fill_preds)
        fill_r2 = r2_score(all_fill_levels, fill_preds)
        metrics['fill_level_mae'] = float(fill_mae)
        metrics['fill_level_r2'] = float(fill_r2)

        # Liquid classification metrics
        liquid_accuracy = accuracy_score(all_liquid_labels, liquid_preds)
        metrics['liquid_accuracy'] = float(liquid_accuracy)

        # Combined accuracy (all predictions correct)
        correct_container = (all_container_labels == container_preds)
        correct_fill = np.abs(all_fill_levels - fill_preds) < 0.1  # 10% tolerance
        correct_liquid = (all_liquid_labels == liquid_preds)
        combined_accuracy = np.mean(correct_container & correct_fill & correct_liquid)
        metrics['combined_accuracy'] = float(combined_accuracy)

        return metrics

    def convert_to_tflite(self,
                         model_path: Optional[str] = None,
                         output_name: Optional[str] = None,
                         quantize: bool = True) -> str:
        """Convert trained model to TFLite format"""
        if model_path is None:
            model_path = str(self.experiment_dir / "final_model.h5")

        if output_name is None:
            output_name = f"{self.experiment_name}.tflite"

        output_path = str(self.experiment_dir / output_name)

        print(f"Converting model to TFLite: {output_path}")

        self.model_builder.convert_to_tflite(
            model_path=model_path,
            output_path=output_path,
            quantize=quantize
        )

        return output_path

    def load_best_model(self) -> None:
        """Load the best model from checkpoints"""
        checkpoint_path = str(self.experiment_dir / "checkpoints" / "best_model.h5")
        if os.path.exists(checkpoint_path):
            self.model = keras.models.load_model(checkpoint_path)
            print(f"Loaded best model from {checkpoint_path}")
        else:
            print("No checkpoint found. Using current model.")

    def get_experiment_summary(self) -> Dict:
        """Get summary of experiment results"""
        summary = {
            'experiment_name': self.experiment_name,
            'experiment_dir': str(self.experiment_dir),
            'timestamp': datetime.now().isoformat()
        }

        # Load saved info files
        info_files = [
            'dataset_info.json',
            'model_info.json',
            'training_metrics.json',
            'evaluation_results.json'
        ]

        for info_file in info_files:
            file_path = self.experiment_dir / info_file
            if file_path.exists():
                with open(file_path, 'r') as f:
                    summary[info_file.replace('.json', '')] = json.load(f)

        return summary


def create_trainer(data_dir: str = "./data",
                  experiment_name: Optional[str] = None,
                  output_dir: str = "./models") -> AquaTrackTrainer:
    """Factory function to create trainer"""
    return AquaTrackTrainer(data_dir, experiment_name, output_dir)


if __name__ == "__main__":
    # Test trainer setup
    print("Testing AquaTrack Trainer...")

    try:
        # Create trainer
        trainer = create_trainer()

        print("Trainer created successfully!")
        print(f"Experiment: {trainer.experiment_name}")
        print(f"Output dir: {trainer.experiment_dir}")

        # Try to setup data (will fail if no annotations, but that's OK)
        try:
            trainer.setup_data(batch_size=16)  # Small batch for testing
            print("Data setup successful!")

            # Setup model
            trainer.setup_model(learning_rate=0.01)  # Higher LR for testing
            print("Model setup successful!")

            print("✅ Trainer test successful! Ready for training when dataset is available.")

        except ValueError as e:
            if "No valid annotations" in str(e):
                print("No dataset found - this is expected. Collect data first.")
                print("✅ Trainer architecture test successful!")
            else:
                raise

    except Exception as e:
        print(f"❌ Trainer test failed: {e}")
        import traceback
        traceback.print_exc()