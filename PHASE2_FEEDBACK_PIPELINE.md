# ETML Phase 2 Feedback Pipeline

Phase 2 adds a clean feedback data path for ML categorization corrections.
The system records user corrections and exposes them for future offline
retraining. It does not retrain the model immediately.

## Flow

```text
ML predicts category
User accepts or corrects category
Backend stores feedback metadata
Corrected examples can be exported later
Future retraining scripts can use exported feedback
```

## Stored Expense Feedback Fields

Each expense keeps the fields needed to audit prediction quality:

| Field | Purpose |
|---|---|
| `description` | Original expense text used for prediction |
| `category` | Final saved category shown to the user |
| `predictedCategory` | Original ML prediction |
| `predictionConfidence` | ML confidence score from `0` to `1` |
| `corrected` | Whether the user changed the ML prediction |
| `correctionSource` | `ml` or `manual` |
| `correctedAt` | Timestamp for manual correction, otherwise `null` |

## Correction Rules

When the user accepts the ML prediction:

```json
{
  "category": "Transport",
  "predictedCategory": "Transport",
  "corrected": false,
  "correctionSource": "ml",
  "correctedAt": null
}
```

When the user manually changes a category:

```json
{
  "category": "Transport",
  "predictedCategory": "Other",
  "corrected": true,
  "correctionSource": "manual",
  "correctedAt": "2026-04-28T10:30:00.000Z"
}
```

The backend preserves the original `predictedCategory` and
`predictionConfidence` when a manual correction is made.

## Feedback Export Endpoint

```http
GET /api/expenses/feedback/export
Authorization: Bearer <token>
```

Returns only corrected expenses for the authenticated user.

Example response:

```json
{
  "count": 1,
  "data": [
    {
      "description": "grab ride home",
      "predictedCategory": "Other",
      "correctedCategory": "Transport",
      "confidence": 0.42,
      "correctedAt": "2026-04-28T10:30:00.000Z"
    }
  ]
}
```

This payload is intended as future training data. It should be reviewed,
deduplicated, and merged with curated training data before retraining.

## Feedback Summary Endpoint

```http
GET /api/expenses/feedback/summary
Authorization: Bearer <token>
```

Example response:

```json
{
  "totalCorrections": 12,
  "lowConfidenceCorrections": 5,
  "mostCorrectedPredictedCategory": "Other",
  "correctionRate": 0.24
}
```

Summary fields:

| Field | Meaning |
|---|---|
| `totalCorrections` | Count of manually corrected expenses |
| `lowConfidenceCorrections` | Corrections where confidence was below `0.60` |
| `mostCorrectedPredictedCategory` | Prediction label most often corrected |
| `correctionRate` | Corrected expenses divided by total expenses |

## Flutter Demo UI

The transactions screen includes an `ML Feedback` panel that shows:

- Corrections saved
- Low-confidence fixes
- Correction rate
- A small export action that copies JSON feedback data

The UI wording is intentionally honest:

- Feedback is saved for future model improvement.
- Manual corrections are recorded.
- The app does not claim instant learning or live retraining.

## Future Retraining Notes

A future retraining script can consume the export response by mapping:

```text
description -> text feature
correctedCategory -> target label
confidence -> optional analysis metadata
correctedAt -> audit timestamp
```

Before retraining, validate labels, remove duplicates, and combine feedback
with a balanced curated dataset. Keep the retraining step offline and
versioned so the deployed model remains reproducible.
