#!/usr/bin/env python3
"""
Quick Start Dataset Collector - ASCII version
Simplified collection tool for immediate testing
"""

import os
import sys
import json
from datetime import datetime

# Add src path for imports
sys.path.append('./src/data')

def show_quick_guide():
    """Show collection quick reference"""
    print("\n=== QUICK COLLECTION GUIDE ===")
    print("1. Take photo of container with liquid")
    print("2. Note container type and fill level")
    print("3. Run this script to annotate")
    print("4. Repeat!")
    print("\nContainers:")
    print("  1=glass_small(200ml)  2=glass_large(350ml)")
    print("  3=cup_plastic(500ml)  4=bottle_500(500ml)")
    print("  5=bottle_750(750ml)   6=bottle_1000(1000ml)")
    print("  7=bottle_1500(1500ml) 8=mug(300ml)")
    print("  9=can_330(330ml)      0=other(300ml)")
    print("\nLiquids:")
    print("  1=water  2=tea  3=coffee  4=juice  5=smoothie")
    print("\nFill Levels:")
    print("  1=empty(5%)   2=low(25%)    3=medium(50%)")
    print("  4=high(75%)   5=full(95%)")

def collect_sample():
    """Simple collection workflow"""
    print("\n--- ADD NEW SAMPLE ---")

    # Get image path
    image_path = input("Image path (drag & drop): ").strip().strip('"\'')
    if not os.path.exists(image_path):
        print("ERROR: File not found!")
        return False

    show_quick_guide()

    # Get container info
    containers = {
        '1': ('glass_small', 200), '2': ('glass_large', 350),
        '3': ('cup_plastic', 500), '4': ('bottle_500', 500),
        '5': ('bottle_750', 750), '6': ('bottle_1000', 1000),
        '7': ('bottle_1500', 1500), '8': ('mug', 300),
        '9': ('can_330', 330), '0': ('other', 300)
    }

    container_key = input("Container type (1-9,0): ").strip()
    if container_key not in containers:
        print("ERROR: Invalid container!")
        return False

    container_type, base_volume = containers[container_key]

    # Get liquid type
    liquids = {'1': 'water', '2': 'tea', '3': 'coffee', '4': 'juice', '5': 'smoothie'}
    liquid_key = input("Liquid type (1-5): ").strip()
    if liquid_key not in liquids:
        print("ERROR: Invalid liquid!")
        return False

    liquid_type = liquids[liquid_key]

    # Get fill level
    fill_presets = {
        '1': (0.05, 'empty'), '2': (0.25, 'low'), '3': (0.50, 'medium'),
        '4': (0.75, 'high'), '5': (0.95, 'full')
    }

    fill_key = input("Fill level (1-5): ").strip()
    if fill_key not in fill_presets:
        print("ERROR: Invalid fill level!")
        return False

    fill_level, fill_desc = fill_presets[fill_key]
    volume_ml = int(base_volume * fill_level)

    # Create sample record
    sample = {
        'original_path': image_path,
        'container_type': container_type,
        'container_volume': base_volume,
        'fill_level': fill_level,
        'liquid_type': liquid_type,
        'estimated_volume_ml': volume_ml,
        'notes': f"Quick collected - {fill_desc}",
        'timestamp': datetime.now().isoformat()
    }

    # Save to collection log
    log_file = './data/annotations/quick_collection_log.json'
    os.makedirs(os.path.dirname(log_file), exist_ok=True)

    # Load existing log
    samples = []
    if os.path.exists(log_file):
        with open(log_file, 'r') as f:
            samples = json.load(f)

    samples.append(sample)

    # Save updated log
    with open(log_file, 'w') as f:
        json.dump(samples, f, indent=2)

    print(f"SUCCESS: Added {container_type} {fill_desc} with {liquid_type} ({volume_ml}ml)")
    print(f"Total samples: {len(samples)}")

    return True

def show_progress():
    """Show collection progress"""
    log_file = './data/annotations/quick_collection_log.json'

    if not os.path.exists(log_file):
        print("No samples collected yet!")
        return

    with open(log_file, 'r') as f:
        samples = json.load(f)

    print(f"\n=== COLLECTION PROGRESS ===")
    print(f"Total samples: {len(samples)}")

    # Count by container type
    containers = {}
    liquids = {}

    for sample in samples:
        container = sample['container_type']
        liquid = sample['liquid_type']

        containers[container] = containers.get(container, 0) + 1
        liquids[liquid] = liquids.get(liquid, 0) + 1

    print("\nBy Container:")
    for container, count in sorted(containers.items()):
        print(f"  {container}: {count}")

    print("\nBy Liquid:")
    for liquid, count in sorted(liquids.items()):
        print(f"  {liquid}: {count}")

    if len(samples) >= 10:
        print("\nREADY FOR: Basic model testing")
    if len(samples) >= 50:
        print("READY FOR: Initial training")
    if len(samples) >= 200:
        print("READY FOR: Production training")

def main():
    """Main collection interface"""
    print("=== AquaTrack Quick Dataset Collector ===")
    print("Simple tool to get started with data collection")

    while True:
        print(f"\nOPTIONS:")
        print("1. Add new sample")
        print("2. Show progress")
        print("3. Collection guide")
        print("4. Exit")

        choice = input("\nChoice: ").strip()

        if choice == "1":
            collect_sample()
        elif choice == "2":
            show_progress()
        elif choice == "3":
            show_quick_guide()
        elif choice == "4":
            print("Happy collecting!")
            break
        else:
            print("Invalid choice!")

if __name__ == "__main__":
    main()