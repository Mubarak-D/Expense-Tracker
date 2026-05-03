# Expense Tracker ML Categorization Service

A Python FastAPI microservice that predicts an expense category from a short text description.

This is Phase 1 of the Expense Tracker project. It only includes the machine learning service. The Node.js backend and Flutter app are intentionally not included yet.

## Tech Stack

- Python
- FastAPI
- scikit-learn
- pandas
- joblib
- uvicorn

## Folder Structure

```text
expense-ml-service/
|-- app/
|   |-- main.py
|   |-- schemas.py
|   `-- model_loader.py
|-- data/
|   `-- expenses.csv
|-- models/
|   `-- .gitkeep
|-- .gitignore
|-- train_model.py
|-- requirements.txt
`-- README.md
```

## Categories

The model predicts one of these categories:

- Food
- Transport
- Bills
- Shopping
- Health
- Entertainment
- Education
- Other

## How The Model Works

The training script loads labeled expense descriptions from `data/expenses.csv`.

It then:

1. Cleans the text by lowercasing it and removing unnecessary symbols.
2. Splits the data into training and test sets.
3. Trains a scikit-learn pipeline with:
   - `TfidfVectorizer` for text features
   - `MultinomialNB` for classification
4. Prints accuracy and a classification report.
5. Saves the trained model to `models/expense_classifier.joblib`.

## Setup

Run these commands from inside the `expense-ml-service` folder:

```bash
python -m venv venv
```

On Windows PowerShell:

```bash
.\venv\Scripts\Activate.ps1
```

On macOS or Linux:

```bash
source venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

## Train The Model

```bash
python train_model.py
```

This creates:

```text
models/expense_classifier.joblib
```

The trained model file is ignored by Git because it is generated from the dataset and training script.

## Run FastAPI

```bash
uvicorn app.main:app --reload
```

The service will run at:

```text
http://127.0.0.1:8000
```

Interactive API docs are available at:

```text
http://127.0.0.1:8000/docs
```

## API Endpoints

### Health Check

```http
GET /
```

Example response:

```json
{
  "service": "Expense Tracker ML Categorization Service",
  "status": "running"
}
```

### Predict Category

```http
POST /predict
```

Example request:

```json
{
  "description": "uber ride home"
}
```

Example response:

```json
{
  "category": "Transport",
  "confidence": 0.88,
  "all_probabilities": {
    "Bills": 0.01,
    "Education": 0.01,
    "Entertainment": 0.02,
    "Food": 0.02,
    "Health": 0.01,
    "Other": 0.02,
    "Shopping": 0.03,
    "Transport": 0.88
  }
}
```

## Validation

- Empty descriptions return HTTP 400.
- If the trained model file does not exist, `/predict` returns a clear error telling you to run `python train_model.py` first.

## Future Improvements

- Add more real transaction data.
- Add merchant normalization.
- Add confidence thresholds for uncertain predictions.
- Add model versioning.
- Add automated tests.
- Add a Node.js backend that calls this service.
- Add a Flutter app for user expense entry.
