#!/usr/bin/env python3
"""
Mobile-friendly dataset collector
Simplified interface for quick photo annotation
"""

import os
import sys
from datetime import datetime
from dataset_collector import DatasetCollector

class MobileCollector:
    """Simplified mobile-friendly interface"""

    def __init__(self):
        self.collector = DatasetCollector()

        # Quick reference mappings
        self.containers = {
            '1': ('glass_small', 200),
            '2': ('glass_large', 350),
            '3': ('cup_plastic', 500),
            '4': ('bottle_500', 500),
            '5': ('bottle_750', 750),
            '6': ('bottle_1000', 1000),
            '7': ('bottle_1500', 1500),
            '8': ('mug', 300),
            '9': ('can_330', 330),
            '0': ('other', 300)
        }

        self.liquids = {
            '1': 'water',
            '2': 'tea',
            '3': 'coffee',
            '4': 'juice',
            '5': 'smoothie'
        }

        self.fill_presets = {
            '1': (0.05, 'empty'),
            '2': (0.25, 'low'),
            '3': (0.50, 'medium'),
            '4': (0.75, 'high'),
            '5': (0.95, 'full')
        }

    def show_quick_reference(self):
        """Show quick reference for mobile input"""
        print("\n=== QUICK REFERENCE ===")
        print("📱 Containers:")
        for key, (name, size) in self.containers.items():
            print(f"  {key} = {name} ({size}ml)")

        print("\n🥤 Liquids:")
        for key, name in self.liquids.items():
            print(f"  {key} = {name}")

        print("\n📏 Fill Levels:")
        for key, (level, desc) in self.fill_presets.items():
            print(f"  {key} = {desc} ({level:.0%})")

    def quick_add(self, image_path: str):
        """Quick annotation workflow"""
        print(f"\n📸 Adding: {os.path.basename(image_path)}")

        # Container selection
        self.show_quick_reference()
        container_key = input("\n📦 Container (1-9,0): ").strip()
        if container_key not in self.containers:
            print("❌ Invalid container")
            return False

        container_type, base_volume = self.containers[container_key]

        # Liquid selection
        liquid_key = input("🥤 Liquid (1-5): ").strip()
        if liquid_key not in self.liquids:
            print("❌ Invalid liquid")
            return False

        liquid_type = self.liquids[liquid_key]

        # Fill level selection
        fill_key = input("📏 Fill level (1-5): ").strip()
        if fill_key not in self.fill_presets:
            print("❌ Invalid fill level")
            return False

        fill_level, fill_desc = self.fill_presets[fill_key]

        # Calculate actual volume
        volume_ml = int(base_volume * fill_level)

        # Add sample
        success = self.collector.add_sample(
            image_path=image_path,
            container_type=container_type,
            fill_level=fill_level,
            liquid_type=liquid_type,
            volume_ml=volume_ml,
            notes=f"Mobile collected - {fill_desc}",
            collector="mobile_app"
        )

        if success:
            print(f"✅ Added: {container_type} {fill_desc} with {liquid_type} ({volume_ml}ml)")
            return True
        else:
            print("❌ Failed to add sample")
            return False

    def batch_mode(self):
        """Process multiple images quickly"""
        print("\n=== BATCH MODE ===")
        print("Drag and drop images or enter paths (empty to finish)")

        count = 0
        while True:
            image_path = input(f"\n📸 Image {count + 1} (or Enter to finish): ").strip()

            if not image_path:
                break

            # Remove quotes if present (from drag-drop)
            image_path = image_path.strip('"\'')

            if not os.path.exists(image_path):
                print(f"❌ File not found: {image_path}")
                continue

            if self.quick_add(image_path):
                count += 1

        print(f"\n✅ Processed {count} images")
        return count

    def show_progress(self):
        """Show collection progress"""
        self.collector.print_collection_status()

        priorities = self.collector.get_collection_priorities()
        if priorities:
            print(f"\n🎯 Next Priorities:")
            for priority in priorities[:5]:  # Top 5
                print(f"  {priority}")

def main():
    """Mobile collector main interface"""
    collector = MobileCollector()

    while True:
        print(f"\n📱 AquaTrack Mobile Collector")
        print("1. Quick add single image")
        print("2. Batch mode (multiple images)")
        print("3. Show progress")
        print("4. Quick reference")
        print("5. Exit")

        choice = input("\nChoice: ").strip()

        if choice == "1":
            image_path = input("📸 Image path: ").strip().strip('"\'')
            if os.path.exists(image_path):
                collector.quick_add(image_path)
            else:
                print("❌ File not found")

        elif choice == "2":
            collector.batch_mode()

        elif choice == "3":
            collector.show_progress()

        elif choice == "4":
            collector.show_quick_reference()

        elif choice == "5":
            break

        else:
            print("❌ Invalid choice")

if __name__ == "__main__":
    main()