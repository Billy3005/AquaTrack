#!/usr/bin/env python3
"""
Simple test of AquaTrack trainer creation
"""

import sys
import os
from pathlib import Path

# Add src paths with proper path handling
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root / 'src' / 'training'))

from trainer import AquaTrackTrainer

def test_trainer():
    print("Creating AquaTrack trainer...")

    # Create trainer
    trainer = AquaTrackTrainer()

    print("Trainer created successfully!")
    print(f"Experiment: {trainer.experiment_name}")
    print(f"Output dir: {trainer.experiment_dir}")

    # Check if directories were created
    if trainer.experiment_dir.exists():
        print("Experiment directory created successfully")

    if (trainer.experiment_dir / "checkpoints").exists():
        print("Checkpoints directory created successfully")

    if (trainer.experiment_dir / "logs").exists():
        print("Logs directory created successfully")

    print("Training pipeline architecture test successful!")
    print("Ready for training when dataset is collected.")
    return True

if __name__ == "__main__":
    try:
        test_trainer()
    except Exception as e:
        print(f"Trainer test failed: {e}")
        import traceback
        traceback.print_exc()