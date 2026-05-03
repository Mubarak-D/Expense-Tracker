from pathlib import Path

import joblib


MODEL_PATH = Path(__file__).resolve().parents[1] / "models" / "expense_classifier.joblib"


def load_model():
    """Load the trained classifier from disk."""
    if not MODEL_PATH.exists():
        return None
    return joblib.load(MODEL_PATH)
