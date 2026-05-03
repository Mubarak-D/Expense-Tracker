from pydantic import BaseModel


class PredictionRequest(BaseModel):
    description: str


class PredictionResponse(BaseModel):
    category: str
    confidence: float
    all_probabilities: dict[str, float]
