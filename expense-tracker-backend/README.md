# ETML Backend API

Node.js/Express API for ETML. It handles authentication, expense storage,
ML category prediction calls, dashboard statistics, and feedback export for
future model retraining.

## Setup

```bash
npm install
cp .env.example .env
npm run dev
```

Seed a complete demo account for local demos and screenshots:

```bash
npm run seed:demo
```

Default demo login:

```text
demo@etml.app
password123
```

Example `.env`:

```text
MONGO_URI=mongodb://localhost:27017/etml
JWT_SECRET=replace_me
JWT_EXPIRES_IN=7d
ML_SERVICE_URL=http://127.0.0.1:8000
PORT=5000
```

## Endpoints

Authentication:

```http
POST /api/auth/register
POST /api/auth/login
```

Expenses:

```http
GET    /api/expenses
POST   /api/expenses
PUT    /api/expenses/:id
DELETE /api/expenses/:id
```

Dashboard and feedback:

```http
GET /api/expenses/stats
GET /api/expenses/feedback/export
GET /api/expenses/feedback/summary
```

All expense, stats, and feedback endpoints require:

```http
Authorization: Bearer <token>
```

## ML Feedback Rules

When ML prediction is accepted:

```json
{
  "corrected": false,
  "correctionSource": "ml",
  "correctedAt": null
}
```

When the user manually changes the category:

```json
{
  "corrected": true,
  "correctionSource": "manual",
  "correctedAt": "2026-04-28T10:30:00.000Z"
}
```

The backend preserves the original `predictedCategory` and
`predictionConfidence` so corrections can be exported for future offline
retraining.
