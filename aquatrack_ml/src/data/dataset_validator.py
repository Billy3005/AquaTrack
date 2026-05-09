#!/usr/bin/env python3
"""
Dataset Validator for AquaTrack
Kiểm tra chất lượng và tính hợp lệ của dataset
"""

import os
import json
import hashlib
from PIL import Image, ImageStat
from typing import List, Dict, Tuple
from dataset_collector import ImageSample, DatasetCollector

class DatasetValidator:
    """Validate dataset quality and completeness"""

    def __init__(self, data_dir: str = "./data"):
        self.data_dir = data_dir
        self.collector = DatasetCollector(data_dir)
        self.issues = []

    def validate_image_quality(self, image_path: str) -> Dict:
        """Validate individual image quality"""
        issues = []
        metrics = {}

        try:
            with Image.open(image_path) as img:
                # Basic metrics
                metrics['width'], metrics['height'] = img.size
                metrics['mode'] = img.mode
                metrics['format'] = img.format

                # Resolution check
                min_resolution = 400
                if img.width < min_resolution or img.height < min_resolution:
                    issues.append(f"Low resolution: {img.width}x{img.height} < {min_resolution}")

                # Aspect ratio check
                aspect_ratio = img.width / img.height
                if aspect_ratio < 0.5 or aspect_ratio > 2.0:
                    issues.append(f"Unusual aspect ratio: {aspect_ratio:.2f}")

                # Color mode check
                if img.mode not in ['RGB', 'RGBA']:
                    issues.append(f"Unsupported color mode: {img.mode}")

                # Brightness analysis
                if img.mode in ['RGB', 'RGBA']:
                    stat = ImageStat.Stat(img)
                    avg_brightness = sum(stat.mean) / len(stat.mean)
                    metrics['brightness'] = avg_brightness

                    if avg_brightness < 50:
                        issues.append("Image too dark")
                    elif avg_brightness > 200:
                        issues.append("Image too bright/overexposed")

                # Sharpness estimation (using variance of Laplacian)
                # Simple blur detection
                gray = img.convert('L')
                import numpy as np
                laplacian_var = np.var(np.array(gray))
                metrics['sharpness'] = laplacian_var

                if laplacian_var < 100:
                    issues.append("Image might be blurry")

        except Exception as e:
            issues.append(f"Cannot open image: {str(e)}")

        return {
            'valid': len(issues) == 0,
            'issues': issues,
            'metrics': metrics
        }

    def validate_annotations(self) -> List[str]:
        """Validate annotation consistency"""
        issues = []

        # Load all samples
        samples = self.collector.samples

        if not samples:
            return ["No samples found in dataset"]

        # Check for duplicates by hash
        hashes = {}
        for sample in samples:
            if sample.hash in hashes:
                issues.append(f"Duplicate hash: {sample.filename} and {hashes[sample.hash]}")
            else:
                hashes[sample.hash] = sample.filename

        # Validate annotation values
        for sample in samples:
            # Fill level range
            if not (0.0 <= sample.fill_level <= 1.0):
                issues.append(f"{sample.filename}: Invalid fill_level {sample.fill_level}")

            # Volume consistency
            expected_volume = int(sample.fill_level * 500)  # Rough estimate
            if abs(sample.volume_ml - expected_volume) > 200:
                issues.append(f"{sample.filename}: Volume {sample.volume_ml}ml seems inconsistent with fill_level {sample.fill_level}")

            # Valid container types
            valid_containers = ['glass_small', 'glass_large', 'cup_plastic', 'bottle_500',
                              'bottle_750', 'bottle_1000', 'bottle_1500', 'mug', 'can_330', 'other']
            if sample.container_type not in valid_containers:
                issues.append(f"{sample.filename}: Invalid container_type '{sample.container_type}'")

            # Valid liquid types
            valid_liquids = ['water', 'tea', 'coffee', 'juice', 'smoothie']
            if sample.liquid_type not in valid_liquids:
                issues.append(f"{sample.filename}: Invalid liquid_type '{sample.liquid_type}'")

            # Check if image file exists
            image_path = os.path.join(self.collector.raw_dir, sample.filename)
            if not os.path.exists(image_path):
                issues.append(f"Image file not found: {sample.filename}")

        return issues

    def check_distribution_balance(self) -> List[str]:
        """Check if dataset is balanced across classes"""
        issues = []
        stats = self.collector.get_collection_progress()

        # Check container type balance
        container_stats = stats['container_types']
        total_samples = sum(data['current'] for data in container_stats.values())

        if total_samples == 0:
            return ["No samples in dataset"]

        # Find severely underrepresented classes
        for container, data in container_stats.items():
            if data['current'] == 0:
                issues.append(f"No samples for container type: {container}")
            elif data['progress'] < 0.3:  # Less than 30% of target
                issues.append(f"Underrepresented container: {container} ({data['current']}/{data['target']})")

        # Check liquid type balance
        liquid_stats = stats['liquid_types']
        for liquid, data in liquid_stats.items():
            if data['current'] == 0:
                issues.append(f"No samples for liquid type: {liquid}")
            elif data['progress'] < 0.3:
                issues.append(f"Underrepresented liquid: {liquid} ({data['current']}/{data['target']})")

        # Check overall size
        total_target = sum(data['target'] for data in container_stats.values())
        if total_samples < total_target * 0.5:
            issues.append(f"Dataset too small: {total_samples}/{total_target} samples")

        return issues

    def validate_full_dataset(self) -> Dict:
        """Run complete dataset validation"""
        print("🔍 Running full dataset validation...")

        results = {
            'total_samples': len(self.collector.samples),
            'valid_images': 0,
            'invalid_images': 0,
            'annotation_issues': [],
            'balance_issues': [],
            'image_issues': [],
            'summary': {}
        }

        # Validate annotations
        print("📋 Validating annotations...")
        results['annotation_issues'] = self.validate_annotations()

        # Check distribution balance
        print("⚖️  Checking class balance...")
        results['balance_issues'] = self.check_distribution_balance()

        # Validate image quality
        print("🖼️  Validating image quality...")
        for sample in self.collector.samples:
            image_path = os.path.join(self.collector.raw_dir, sample.filename)
            if os.path.exists(image_path):
                quality_result = self.validate_image_quality(image_path)
                if quality_result['valid']:
                    results['valid_images'] += 1
                else:
                    results['invalid_images'] += 1
                    results['image_issues'].append({
                        'filename': sample.filename,
                        'issues': quality_result['issues']
                    })

        # Generate summary
        total_issues = (len(results['annotation_issues']) +
                       len(results['balance_issues']) +
                       len(results['image_issues']))

        results['summary'] = {
            'total_issues': total_issues,
            'dataset_ready': total_issues < 5 and results['total_samples'] >= 200,
            'image_quality_score': results['valid_images'] / max(1, results['total_samples']),
            'completeness_score': min(1.0, results['total_samples'] / 500)
        }

        return results

    def print_validation_report(self):
        """Print comprehensive validation report"""
        results = self.validate_full_dataset()

        print(f"\n📊 DATASET VALIDATION REPORT")
        print(f"{'='*50}")

        # Summary
        summary = results['summary']
        print(f"📈 Total Samples: {results['total_samples']}")
        print(f"✅ Valid Images: {results['valid_images']}")
        print(f"❌ Invalid Images: {results['invalid_images']}")
        print(f"🎯 Quality Score: {summary['image_quality_score']:.1%}")
        print(f"📊 Completeness: {summary['completeness_score']:.1%}")

        # Issues breakdown
        if results['annotation_issues']:
            print(f"\n📋 Annotation Issues ({len(results['annotation_issues'])}):")
            for issue in results['annotation_issues'][:10]:  # Show first 10
                print(f"  • {issue}")

        if results['balance_issues']:
            print(f"\n⚖️  Balance Issues ({len(results['balance_issues'])}):")
            for issue in results['balance_issues']:
                print(f"  • {issue}")

        if results['image_issues']:
            print(f"\n🖼️  Image Quality Issues ({len(results['image_issues'])}):")
            for item in results['image_issues'][:5]:  # Show first 5
                print(f"  • {item['filename']}: {', '.join(item['issues'])}")

        # Final verdict
        print(f"\n🚀 DATASET STATUS:")
        if summary['dataset_ready']:
            print("✅ READY FOR TRAINING!")
        elif summary['total_issues'] < 10:
            print("⚠️  ALMOST READY - minor issues to fix")
        else:
            print("❌ NOT READY - significant issues need attention")

        return results

def main():
    """Main validation interface"""
    validator = DatasetValidator()

    while True:
        print(f"\n🔍 Dataset Validator")
        print("1. Quick validation")
        print("2. Full validation report")
        print("3. Check single image")
        print("4. Exit")

        choice = input("\nChoice: ").strip()

        if choice == "1":
            issues = validator.validate_annotations()
            if issues:
                print("❌ Annotation issues found:")
                for issue in issues[:10]:
                    print(f"  • {issue}")
            else:
                print("✅ Annotations look good!")

        elif choice == "2":
            validator.print_validation_report()

        elif choice == "3":
            image_path = input("Image path: ").strip().strip('"\'')
            if os.path.exists(image_path):
                result = validator.validate_image_quality(image_path)
                print(f"Quality: {'✅ Good' if result['valid'] else '❌ Issues'}")
                if result['issues']:
                    for issue in result['issues']:
                        print(f"  • {issue}")
                print(f"Metrics: {result['metrics']}")
            else:
                print("❌ File not found")

        elif choice == "4":
            break

        else:
            print("❌ Invalid choice")

if __name__ == "__main__":
    main()