import re
from pathlib import Path

import joblib
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import train_test_split
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline


BASE_DIR = Path(__file__).resolve().parent
DATA_PATH = BASE_DIR / "data" / "expenses.csv"
MODEL_DIR = BASE_DIR / "models"
MODEL_PATH = MODEL_DIR / "expense_classifier.joblib"


def clean_text(text: str) -> str:
    """Normalize expense descriptions before vectorizing them."""
    text = str(text).lower()
    text = re.sub(r"[^a-z0-9\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def load_training_data() -> pd.DataFrame:
    data = pd.read_csv(DATA_PATH)
    data["description"] = data["description"].apply(clean_text)
    return data


def train_model() -> Pipeline:
    data = load_training_data()

    x_train, x_test, y_train, y_test = train_test_split(
        data["description"],
        data["category"],
        test_size=0.2,
        random_state=42,
        stratify=data["category"],
    )

    model = Pipeline(
        steps=[
            ("tfidf", TfidfVectorizer(min_df=1)),
            ("classifier", MultinomialNB()),
        ]
    )

    model.fit(x_train, y_train)

    predictions = model.predict(x_test)
    accuracy = accuracy_score(y_test, predictions)

    print(f"Accuracy: {accuracy:.4f}")
    print("\nClassification Report:")
    print(classification_report(y_test, predictions))

    MODEL_DIR.mkdir(exist_ok=True)
    joblib.dump(model, MODEL_PATH)
    print(f"\nModel saved to: {MODEL_PATH}")

    return model


if __name__ == "__main__":
    train_model()
