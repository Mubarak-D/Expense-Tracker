from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.model_loader import MODEL_PATH, load_model
from app.schemas import PredictionRequest, PredictionResponse


app = FastAPI(
    title="Expense Tracker ML Categorization Service",
    version="1.0.0",
    description="Predicts an expense category from a text description.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5500",
        "http://127.0.0.1:5500",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return {
        "service": "Expense Tracker ML Categorization Service",
        "status": "running",
    }


@app.post("/predict", response_model=PredictionResponse)
def predict_expense_category(request: PredictionRequest):
    description = request.description.strip()

    if not description:
        raise HTTPException(status_code=400, detail="Description cannot be empty.")

    model = load_model()
    if model is None:
        raise HTTPException(
            status_code=500,
            detail=f"Model file not found at {MODEL_PATH}. Run python train_model.py first.",
        )

    labels = model.classes_
    probabilities = model.predict_proba([description])[0]
    best_index = probabilities.argmax()

    # Convert NumPy values from scikit-learn into plain Python JSON values.
    all_probabilities = {
        str(label): round(float(probability), 4)
        for label, probability in zip(labels, probabilities)
    }

    return {
        "category": str(labels[best_index]),
        "confidence": round(float(probabilities[best_index]), 4),
        "all_probabilities": all_probabilities,
    }
