#!/usr/bin/env python3
"""
AquaTrack ML Training Environment Setup
ASCII version for Windows compatibility
"""

import os
import sys
import subprocess

def check_python_version():
    """Check Python version compatibility"""
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        raise RuntimeError(f"Python 3.8+ required, got {version.major}.{version.minor}")
    print(f"[+] Python {version.major}.{version.minor}.{version.micro} OK")

def create_project_structure():
    """Create ML training project folder structure"""
    base_dir = os.path.dirname(os.path.abspath(__file__))

    folders = [
        'data/raw',                    # Original images
        'data/processed',              # Augmented/preprocessed
        'data/annotations',            # Label files
        'models/checkpoints',          # Training checkpoints
        'models/final',                # Final trained models
        'notebooks',                   # Jupyter experiments
        'src/data',                    # Data processing scripts
        'src/models',                  # Model architecture
        'src/training',                # Training scripts
        'src/evaluation',              # Evaluation scripts
        'logs',                        # Training logs
        'experiments',                 # Experiment configs
    ]

    created_folders = []
    for folder in folders:
        path = os.path.join(base_dir, folder)
        os.makedirs(path, exist_ok=True)
        created_folders.append(folder)
        print(f"[+] Created: {folder}")

    # Create .gitkeep files in empty dirs
    for folder in folders:
        gitkeep_path = os.path.join(base_dir, folder, '.gitkeep')
        if not os.path.exists(gitkeep_path):
            with open(gitkeep_path, 'w') as f:
                f.write('# Keep this directory in git\n')

    return created_folders

def create_config_files():
    """Create initial configuration files"""
    base_dir = os.path.dirname(os.path.abspath(__file__))

    # Training config
    config_content = '''# AquaTrack ML Training Configuration
model:
  input_size: [224, 224, 3]
  num_container_classes: 10
  num_liquid_classes: 5
  backbone: 'mobilenetv2'  # mobilenetv2, resnet50, efficientnet

dataset:
  train_split: 0.7
  val_split: 0.2
  test_split: 0.1
  batch_size: 32
  augmentation: true

training:
  epochs: 100
  learning_rate: 0.001
  optimizer: 'adam'
  early_stopping_patience: 10
  reduce_lr_patience: 5

paths:
  raw_data: './data/raw'
  processed_data: './data/processed'
  annotations: './data/annotations'
  models: './models'
  logs: './logs'
'''

    config_path = os.path.join(base_dir, 'config.yaml')
    with open(config_path, 'w') as f:
        f.write(config_content)
    print("[+] Created config.yaml")

def main():
    """Main setup function"""
    print("=== AquaTrack ML Training Environment Setup ===\n")

    try:
        check_python_version()
        created_folders = create_project_structure()
        create_config_files()

        print(f"\n[+] Setup complete! Created {len(created_folders)} directories")
        print("\nNext steps:")
        print("  1. Install dependencies: pip install -r requirements.txt")
        print("  2. Collect training dataset (photos of containers)")
        print("  3. Annotate images (container type, fill level, liquid)")
        print("  4. Run training script")
        print("  5. Convert trained model to TFLite")

        return True

    except Exception as e:
        print(f"\n[-] Setup failed: {e}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)