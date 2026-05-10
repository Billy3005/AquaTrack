#!/usr/bin/env python3
"""
Data Pipeline for AquaTrack Model Training
Handles preprocessing, augmentation, and data loading
"""

import tensorflow as tf
import numpy as np
import json
import os
from typing import Dict, List, Tuple, Optional, Union
from pathlib import Path
import cv2
from PIL import Image
import albumentations as A


class AquaTrackDataPipeline:
    """
    Data pipeline for AquaTrack model training

    Handles:
    - Data loading from annotations
    - Image preprocessing and normalization
    - Data augmentation for training
    - Batch creation for training/validation
    """

    def __init__(self,
                 data_dir: str = "./data",
                 target_size: Tuple[int, int] = (224, 224),
                 batch_size: int = 32):
        self.data_dir = Path(data_dir)
        self.target_size = target_size
        self.batch_size = batch_size

        # Class mappings (sync with model)
        self.container_classes = [
            'glass_small', 'glass_large', 'cup_plastic', 'bottle_500',
            'bottle_750', 'bottle_1000', 'bottle_1500', 'mug',
            'can_330', 'other'
        ]
        self.liquid_classes = ['water', 'tea', 'coffee', 'juice', 'smoothie']

        # Create label encoders
        self.container_to_id = {cls: i for i, cls in enumerate(self.container_classes)}
        self.liquid_to_id = {cls: i for i, cls in enumerate(self.liquid_classes)}

        # Training augmentations
        self.train_augment = A.Compose([
            # Geometric transformations
            A.Rotate(limit=15, p=0.7),
            A.HorizontalFlip(p=0.5),
            A.RandomScale(scale_limit=0.2, p=0.7),
            A.Affine(scale=0.1, translate_percent=0.1, rotate=10, p=0.7),

            # Color augmentations
            A.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.3, hue=0.1, p=0.8),
            A.RandomBrightnessContrast(brightness_limit=0.2, contrast_limit=0.2, p=0.7),
            A.HueSaturationValue(hue_shift_limit=10, sat_shift_limit=30, val_shift_limit=20, p=0.7),

            # Noise and blur
            A.GaussNoise(noise_scale_factor=0.1, p=0.3),
            A.GaussianBlur(blur_limit=3, p=0.3),
            A.MotionBlur(blur_limit=3, p=0.2),

            # Occlusion simulation
            A.CoarseDropout(num_holes_range=(1, 3), hole_height_range=(16, 32), hole_width_range=(16, 32), p=0.3),

            # Final resize only - model handles normalization (/255.0)
            A.Resize(height=self.target_size[0], width=self.target_size[1])
        ])

        # Validation augmentations (minimal)
        self.val_augment = A.Compose([
            A.Resize(height=self.target_size[0], width=self.target_size[1])
            # No normalization - model handles /255.0 conversion
        ])

    def load_annotations(self, annotation_file: Optional[str] = None) -> List[Dict]:
        """Load annotations from JSON file"""
        if annotation_file is None:
            # Try multiple possible annotation files
            possible_files = [
                self.data_dir / "annotations" / "annotations.json",
                self.data_dir / "annotations" / "quick_collection_log.json",
                self.data_dir / "dataset.json"
            ]

            for file_path in possible_files:
                if file_path.exists():
                    annotation_file = str(file_path)
                    break

            if annotation_file is None:
                raise FileNotFoundError("No annotation file found. Please create annotations first.")

        with open(annotation_file, 'r') as f:
            annotations = json.load(f)

        print(f"Loaded {len(annotations)} annotations from {annotation_file}")
        return annotations

    def preprocess_annotations(self, annotations: List[Dict]) -> List[Dict]:
        """
        Preprocess and validate annotations

        Expected format:
        {
            "original_path": "path/to/image.jpg",
            "container_type": "bottle_500",
            "fill_level": 0.75,
            "liquid_type": "water",
            "estimated_volume_ml": 375,
            ...
        }
        """
        valid_annotations = []

        for ann in annotations:
            try:
                # Validate required fields
                required_fields = ['original_path', 'container_type', 'fill_level', 'liquid_type']
                if not all(field in ann for field in required_fields):
                    print(f"Skipping annotation missing required fields: {ann}")
                    continue

                # Validate class values
                if ann['container_type'] not in self.container_classes:
                    print(f"Unknown container type: {ann['container_type']}")
                    continue

                if ann['liquid_type'] not in self.liquid_classes:
                    print(f"Unknown liquid type: {ann['liquid_type']}")
                    continue

                # Validate fill level
                fill_level = float(ann['fill_level'])
                if not (0.0 <= fill_level <= 1.0):
                    print(f"Invalid fill level: {fill_level}")
                    continue

                # Check if image file exists
                img_path = ann['original_path']
                if not os.path.exists(img_path):
                    # Try relative to data directory
                    alt_path = self.data_dir / "raw" / os.path.basename(img_path)
                    if alt_path.exists():
                        ann['image_path'] = str(alt_path)
                    else:
                        print(f"Image not found: {img_path}")
                        continue
                else:
                    ann['image_path'] = img_path

                # Encode labels
                ann['container_id'] = self.container_to_id[ann['container_type']]
                ann['liquid_id'] = self.liquid_to_id[ann['liquid_type']]
                ann['fill_level_norm'] = fill_level

                valid_annotations.append(ann)

            except Exception as e:
                print(f"Error processing annotation {ann}: {e}")
                continue

        print(f"Valid annotations: {len(valid_annotations)}/{len(annotations)}")
        return valid_annotations

    def load_image(self, image_path: str) -> np.ndarray:
        """Load and preprocess image"""
        try:
            # Load with OpenCV (BGR -> RGB)
            image = cv2.imread(image_path)
            if image is None:
                # Fallback to PIL
                pil_img = Image.open(image_path).convert('RGB')
                image = np.array(pil_img)
            else:
                image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

            return image
        except Exception as e:
            raise ValueError(f"Cannot load image {image_path}: {e}")

    def augment_image(self, image: np.ndarray, is_training: bool = True) -> np.ndarray:
        """Apply augmentations to image"""
        if is_training:
            augmented = self.train_augment(image=image)
        else:
            augmented = self.val_augment(image=image)

        return augmented['image']

    def create_tf_dataset(self,
                         annotations: List[Dict],
                         is_training: bool = True,
                         shuffle: bool = True) -> tf.data.Dataset:
        """
        Create TensorFlow dataset from annotations

        Returns dataset with:
        - images: (batch_size, height, width, 3)
        - labels: dict with 'container_class', 'fill_level', 'liquid_type'
        """

        def load_and_preprocess(image_path_tensor, container_id_tensor, fill_level_tensor, liquid_id_tensor):
            """Load and preprocess single sample - fixed tf.py_function signature"""
            # Extract data
            image_path = image_path_tensor.numpy().decode('utf-8')
            container_id = container_id_tensor.numpy()
            fill_level = fill_level_tensor.numpy()
            liquid_id = liquid_id_tensor.numpy()

            # Load image
            image = self.load_image(image_path)

            # Apply augmentations
            image = self.augment_image(image, is_training)

            # Ensure correct shape and dtype
            image = tf.cast(image, tf.float32)

            return image, container_id, fill_level, liquid_id

        # Create dataset from annotations
        dataset_dict = {
            'image_path': [ann['image_path'] for ann in annotations],
            'container_id': [ann['container_id'] for ann in annotations],
            'fill_level_norm': [ann['fill_level_norm'] for ann in annotations],
            'liquid_id': [ann['liquid_id'] for ann in annotations]
        }

        dataset = tf.data.Dataset.from_tensor_slices(dataset_dict)

        # Shuffle if training
        if shuffle and is_training:
            dataset = dataset.shuffle(buffer_size=len(annotations))

        # Map preprocessing function with proper signature
        dataset = dataset.map(
            lambda x: tf.py_function(
                load_and_preprocess,
                [x['image_path'], x['container_id'], x['fill_level_norm'], x['liquid_id']],
                [tf.float32, tf.int32, tf.float32, tf.int32]
            ),
            num_parallel_calls=tf.data.AUTOTUNE
        )

        # Set shapes for proper batching
        dataset = dataset.map(
            lambda image, container_id, fill_level, liquid_id: (
                tf.ensure_shape(image, [224, 224, 3]),
                {
                    'container_class': tf.cast(container_id, tf.int32),
                    'fill_level': tf.expand_dims(tf.cast(fill_level, tf.float32), 0),
                    'liquid_type': tf.cast(liquid_id, tf.int32)
                }
            )
        )

        # Batch
        dataset = dataset.batch(self.batch_size)

        # Prefetch for performance
        dataset = dataset.prefetch(tf.data.AUTOTUNE)

        return dataset

    def split_annotations(self,
                         annotations: List[Dict],
                         train_ratio: float = 0.8,
                         val_ratio: float = 0.1,
                         test_ratio: float = 0.1) -> Tuple[List[Dict], List[Dict], List[Dict]]:
        """
        Split annotations into train/val/test sets

        Uses stratified split to maintain class balance
        """
        if abs(train_ratio + val_ratio + test_ratio - 1.0) > 1e-6:
            raise ValueError("Split ratios must sum to 1.0")

        # Shuffle annotations
        np.random.shuffle(annotations)

        n_total = len(annotations)
        n_train = int(n_total * train_ratio)
        n_val = int(n_total * val_ratio)

        train_data = annotations[:n_train]
        val_data = annotations[n_train:n_train + n_val]
        test_data = annotations[n_train + n_val:]

        print(f"Data split: Train={len(train_data)}, Val={len(val_data)}, Test={len(test_data)}")

        return train_data, val_data, test_data

    def get_class_weights(self, annotations: List[Dict]) -> Dict[str, np.ndarray]:
        """Calculate class weights for imbalanced dataset"""
        from sklearn.utils.class_weight import compute_class_weight

        # Container class weights
        container_labels = [ann['container_id'] for ann in annotations]
        container_weights = compute_class_weight(
            'balanced',
            classes=np.unique(container_labels),
            y=container_labels
        )

        # Liquid class weights
        liquid_labels = [ann['liquid_id'] for ann in annotations]
        liquid_weights = compute_class_weight(
            'balanced',
            classes=np.unique(liquid_labels),
            y=liquid_labels
        )

        return {
            'container_class': container_weights,
            'liquid_type': liquid_weights
        }

    def analyze_dataset(self, annotations: List[Dict]) -> Dict:
        """Analyze dataset statistics"""
        stats = {
            'total_samples': len(annotations),
            'container_distribution': {},
            'liquid_distribution': {},
            'fill_level_stats': {},
        }

        # Container distribution
        for container in self.container_classes:
            count = sum(1 for ann in annotations if ann['container_type'] == container)
            stats['container_distribution'][container] = count

        # Liquid distribution
        for liquid in self.liquid_classes:
            count = sum(1 for ann in annotations if ann['liquid_type'] == liquid)
            stats['liquid_distribution'][liquid] = count

        # Fill level statistics
        fill_levels = [ann['fill_level'] for ann in annotations]
        stats['fill_level_stats'] = {
            'mean': np.mean(fill_levels),
            'std': np.std(fill_levels),
            'min': np.min(fill_levels),
            'max': np.max(fill_levels)
        }

        return stats


def create_data_pipeline(data_dir: str = "./data",
                        target_size: Tuple[int, int] = (224, 224),
                        batch_size: int = 32) -> AquaTrackDataPipeline:
    """Factory function to create data pipeline"""
    return AquaTrackDataPipeline(data_dir, target_size, batch_size)


if __name__ == "__main__":
    # Test data pipeline
    print("Testing AquaTrack Data Pipeline...")

    try:
        pipeline = create_data_pipeline()

        # Try to load annotations
        try:
            annotations = pipeline.load_annotations()
            processed = pipeline.preprocess_annotations(annotations)

            if processed:
                print(f"Successfully processed {len(processed)} samples")

                # Analyze dataset
                stats = pipeline.analyze_dataset(processed)
                print(f"Dataset stats: {stats}")

                # Create small test dataset
                test_annotations = processed[:min(5, len(processed))]
                dataset = pipeline.create_tf_dataset(test_annotations, is_training=True)

                print("Testing data loading...")
                for batch_images, batch_labels in dataset.take(1):
                    print(f"Batch images shape: {batch_images.shape}")
                    print(f"Container labels shape: {batch_labels['container_class'].shape}")
                    print(f"Fill level shape: {batch_labels['fill_level'].shape}")
                    print(f"Liquid labels shape: {batch_labels['liquid_type'].shape}")

                print("✅ Data pipeline test successful!")

            else:
                print("No valid annotations found. Please collect data first.")

        except FileNotFoundError as e:
            print(f"No annotations found: {e}")
            print("Please collect dataset first using data collection tools.")

    except Exception as e:
        print(f"❌ Data pipeline test failed: {e}")
        import traceback
        traceback.print_exc()