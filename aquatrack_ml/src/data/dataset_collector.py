#!/usr/bin/env python3
"""
AquaTrack Dataset Collection Tool
Hỗ trợ thu thập và tổ chức dataset cho training
"""

import os
import json
import hashlib
from datetime import datetime
from dataclasses import dataclass, asdict
from typing import List, Dict, Optional
import shutil

@dataclass
class ImageSample:
    """Metadata cho một sample image"""
    filename: str
    container_type: str      # glass_small, bottle_500, etc.
    fill_level: float        # 0.0 - 1.0
    liquid_type: str         # water, tea, coffee, juice, smoothie
    volume_ml: int          # Actual volume in ml
    lighting: str           # indoor, outdoor, artificial, natural
    background: str         # clean, cluttered, textured
    angle: str              # front, side, top, angled
    quality: str            # good, medium, poor
    notes: str              # Additional notes
    collected_date: str     # ISO timestamp
    collector: str          # Who collected this sample
    hash: str               # File hash for deduplication

class DatasetCollector:
    """Tool for collecting and organizing training dataset"""

    # Target distribution for balanced dataset
    TARGET_DISTRIBUTION = {
        'container_types': {
            'glass_small': 60,     # 200ml glasses
            'glass_large': 60,     # 350ml glasses
            'cup_plastic': 50,     # 500ml plastic cups
            'bottle_500': 70,      # 500ml bottles (popular)
            'bottle_750': 50,      # 750ml bottles
            'bottle_1000': 60,     # 1L bottles (popular)
            'bottle_1500': 40,     # 1.5L bottles
            'mug': 50,             # Coffee mugs 300ml
            'can_330': 40,         # Cans 330ml
            'other': 30,           # Edge cases
        },
        'fill_levels': {
            'empty': 0.05,         # 0-10%
            'low': 0.25,           # 10-40%
            'medium': 0.50,        # 40-70%
            'high': 0.80,          # 70-90%
            'full': 0.95,          # 90-100%
        },
        'liquid_types': {
            'water': 200,          # Most common
            'tea': 80,             # Common
            'coffee': 80,          # Common
            'juice': 60,           # Medium
            'smoothie': 40,        # Less common
        }
    }

    def __init__(self, data_dir: str = "./data"):
        self.data_dir = data_dir
        self.raw_dir = os.path.join(data_dir, "raw")
        self.annotations_dir = os.path.join(data_dir, "annotations")

        # Create directories
        os.makedirs(self.raw_dir, exist_ok=True)
        os.makedirs(self.annotations_dir, exist_ok=True)

        # Load existing dataset
        self.samples: List[ImageSample] = self._load_existing_samples()

    def _load_existing_samples(self) -> List[ImageSample]:
        """Load existing annotated samples"""
        samples = []
        metadata_file = os.path.join(self.annotations_dir, "dataset_metadata.json")

        if os.path.exists(metadata_file):
            with open(metadata_file, 'r') as f:
                data = json.load(f)
                for sample_data in data:
                    samples.append(ImageSample(**sample_data))

        return samples

    def add_sample(self,
                   image_path: str,
                   container_type: str,
                   fill_level: float,
                   liquid_type: str,
                   volume_ml: int,
                   lighting: str = "indoor",
                   background: str = "clean",
                   angle: str = "front",
                   quality: str = "good",
                   notes: str = "",
                   collector: str = "manual"):
        """Add new sample to dataset"""

        if not os.path.exists(image_path):
            raise FileNotFoundError(f"Image not found: {image_path}")

        # Calculate file hash
        with open(image_path, 'rb') as f:
            file_hash = hashlib.md5(f.read()).hexdigest()

        # Check for duplicates
        for existing in self.samples:
            if existing.hash == file_hash:
                print(f"[!] Duplicate detected: {image_path} (matches {existing.filename})")
                return False

        # Generate filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        ext = os.path.splitext(image_path)[1]
        filename = f"{container_type}_{fill_level:.2f}_{liquid_type}_{timestamp}{ext}"

        # Copy image to raw directory
        dest_path = os.path.join(self.raw_dir, filename)
        shutil.copy2(image_path, dest_path)

        # Create sample metadata
        sample = ImageSample(
            filename=filename,
            container_type=container_type,
            fill_level=fill_level,
            liquid_type=liquid_type,
            volume_ml=volume_ml,
            lighting=lighting,
            background=background,
            angle=angle,
            quality=quality,
            notes=notes,
            collected_date=datetime.now().isoformat(),
            collector=collector,
            hash=file_hash
        )

        self.samples.append(sample)
        self._save_metadata()

        print(f"[+] Added sample: {filename}")
        return True

    def _save_metadata(self):
        """Save dataset metadata to JSON"""
        metadata_file = os.path.join(self.annotations_dir, "dataset_metadata.json")

        with open(metadata_file, 'w') as f:
            json.dump([asdict(sample) for sample in self.samples], f, indent=2)

    def get_collection_progress(self) -> Dict:
        """Get current collection progress vs targets"""
        current_stats = {
            'container_types': {},
            'liquid_types': {},
            'total_samples': len(self.samples)
        }

        # Count by container type
        for container in self.TARGET_DISTRIBUTION['container_types'].keys():
            count = sum(1 for s in self.samples if s.container_type == container)
            target = self.TARGET_DISTRIBUTION['container_types'][container]
            current_stats['container_types'][container] = {
                'current': count,
                'target': target,
                'progress': count / target if target > 0 else 0,
                'needed': max(0, target - count)
            }

        # Count by liquid type
        for liquid in self.TARGET_DISTRIBUTION['liquid_types'].keys():
            count = sum(1 for s in self.samples if s.liquid_type == liquid)
            target = self.TARGET_DISTRIBUTION['liquid_types'][liquid]
            current_stats['liquid_types'][liquid] = {
                'current': count,
                'target': target,
                'progress': count / target if target > 0 else 0,
                'needed': max(0, target - count)
            }

        return current_stats

    def print_collection_status(self):
        """Print collection progress report"""
        stats = self.get_collection_progress()

        print(f"\n=== Dataset Collection Status ===")
        print(f"Total samples: {stats['total_samples']}")

        print(f"\nContainer Types Progress:")
        for container, data in stats['container_types'].items():
            progress_bar = "█" * int(data['progress'] * 20) + "░" * (20 - int(data['progress'] * 20))
            print(f"  {container:12} [{progress_bar}] {data['current']:3}/{data['target']:3} ({data['progress']:.1%}) - Need {data['needed']}")

        print(f"\nLiquid Types Progress:")
        for liquid, data in stats['liquid_types'].items():
            progress_bar = "█" * int(data['progress'] * 20) + "░" * (20 - int(data['progress'] * 20))
            print(f"  {liquid:10} [{progress_bar}] {data['current']:3}/{data['target']:3} ({data['progress']:.1%}) - Need {data['needed']}")

    def get_collection_priorities(self) -> List[str]:
        """Get priority list for next collections"""
        stats = self.get_collection_progress()
        priorities = []

        # Find container types that need more samples
        for container, data in stats['container_types'].items():
            if data['needed'] > 0:
                priorities.append(f"📷 {container} ({data['needed']} needed)")

        return priorities

def main():
    """Interactive dataset collection"""
    collector = DatasetCollector()

    while True:
        print("\n=== AquaTrack Dataset Collector ===")
        print("1. Show collection status")
        print("2. Add new sample")
        print("3. Show priorities")
        print("4. Exit")

        choice = input("\nChoose option: ").strip()

        if choice == "1":
            collector.print_collection_status()

        elif choice == "2":
            print("\nAdd new sample:")
            try:
                image_path = input("Image path: ").strip()
                container_type = input("Container type: ").strip()
                fill_level = float(input("Fill level (0.0-1.0): "))
                liquid_type = input("Liquid type: ").strip()
                volume_ml = int(input("Volume (ml): "))

                collector.add_sample(
                    image_path=image_path,
                    container_type=container_type,
                    fill_level=fill_level,
                    liquid_type=liquid_type,
                    volume_ml=volume_ml
                )
            except Exception as e:
                print(f"Error: {e}")

        elif choice == "3":
            priorities = collector.get_collection_priorities()
            print("\nCollection Priorities:")
            for priority in priorities:
                print(f"  {priority}")

        elif choice == "4":
            break

        else:
            print("Invalid option")

if __name__ == "__main__":
    main()