# ETML Phase 2 - Expense Tracker Backend API

This folder contains the Node.js backend for **ETML - Expense Tracker with ML Categorization**.

Phase 1 is the existing Python FastAPI ML microservice at the repository root. This Phase 2 backend handles authentication, protected expense management, category prediction integration, user corrections, and dashboard statistics.

## Tech Stack

- Node.js
- Express.js
- MongoDB
- Mongoose
- JWT
- bcrypt
- dotenv
- cors
- axios
- express-validator

## Architecture

The backend is intentionally simple and production-minded:

- `app.js` configures Express middleware and routes.
- `server.js` loads environment variables, connects to MongoDB, and starts HTTP listening.
- Controllers handle HTTP request/response logic.
- Models define MongoDB documents and validation rules.
- Middleware handles JWT authentication, request validation, and centralized errors.
- Services isolate external ML calls and statistics aggregation.

The backend calls the Phase 1 FastAPI service:

```text
POST http://localhost:8000/predict
```

If the ML service is unavailable, expense creation still succeeds with category `Other` and confidence `0`.

## Folder Structure

```text
expense-tracker-backend/
|-- src/
|   |-- config/
|   |   `-- db.js
|   |-- controllers/
|   |   |-- authController.js
|   |   `-- expenseController.js
|   |-- middleware/
|   |   |-- authMiddleware.js
|   |   |-- errorMiddleware.js
|   |   `-- validateRequest.js
|   |-- models/
|   |   |-- Expense.js
|   |   `-- User.js
|   |-- routes/
|   |   |-- authRoutes.js
|   |   `-- expenseRoutes.js
|   |-- services/
|   |   |-- mlService.js
|   |   `-- statsService.js
|   |-- utils/
|   |   |-- asyncHandler.js
|   |   `-- generateToken.js
|   |-- app.js
|   `-- server.js
|-- .env.example
|-- .gitignore
|-- package.json
`-- README.md
```

## Environment Variables

Create a local `.env` file from `.env.example`:

```env
PORT=5000
MONGO_URI=mongodb://localhost:27017/etml
JWT_SECRET=replace_with_secure_secret
JWT_EXPIRES_IN=7d
ML_SERVICE_URL=http://localhost:8000
```

Do not commit `.env`.

## Run Locally

Install dependencies:

```bash
npm install
```

Start MongoDB locally, then start the backend:

```bash
npm start
```

For development with auto-reload:

```bash
npm run dev
```

Health check:

```bash
curl http://localhost:5000/health
```

## API Endpoints

### Auth

| Method | Path | Auth | Description |
|---|---|---:|---|
| POST | `/api/auth/register` | No | Register user |
| POST | `/api/auth/login` | No | Login user |
| GET | `/api/auth/me` | Yes | Get current authenticated user |

### Expenses

| Method | Path | Auth | Description |
|---|---|---:|---|
| GET | `/api/expenses` | Yes | List user's expenses |
| POST | `/api/expenses` | Yes | Create expense with ML prediction |
| PUT | `/api/expenses/:id` | Yes | Update expense |
| DELETE | `/api/expenses/:id` | Yes | Delete expense |
| GET | `/api/expenses/stats` | Yes | Dashboard statistics |

`GET /api/expenses` supports:

- `month=YYYY-MM`
- `category=Food`
- `sort=asc` or `sort=desc`

## Example Requests

### Register

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Ahamed","email":"ahamed@example.com","password":"password123"}'
```

### Login

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ahamed@example.com","password":"password123"}'
```

Example response:

```json
{
  "user": {
    "id": "USER_ID",
    "name": "Ahamed",
    "email": "ahamed@example.com"
  },
  "token": "JWT_TOKEN"
}
```

### Create Expense

```bash
curl -X POST http://localhost:5000/api/expenses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer JWT_TOKEN" \
  -d '{"amount":1200,"description":"uber ride home","date":"2026-04-28"}'
```

Example response:

```json
{
  "expense": {
    "amount": 1200,
    "description": "uber ride home",
    "category": "Transport",
    "predictedCategory": "Transport",
    "predictionConfidence": 0.88,
    "corrected": false,
    "date": "2026-04-28T00:00:00.000Z"
  }
}
```

### Get Expenses

```bash
curl "http://localhost:5000/api/expenses?month=2026-04&category=Transport&sort=desc" \
  -H "Authorization: Bearer JWT_TOKEN"
```

### Update Category Correction

```bash
curl -X PUT http://localhost:5000/api/expenses/EXPENSE_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer JWT_TOKEN" \
  -d '{"category":"Food"}'
```

If the manual category differs from `predictedCategory`, `corrected` becomes `true`.

### Get Stats

```bash
curl http://localhost:5000/api/expenses/stats \
  -H "Authorization: Bearer JWT_TOKEN"
```

Example response:

```json
{
  "monthlyTotal": 12500,
  "categoryBreakdown": [
    { "category": "Food", "total": 5000 },
    { "category": "Transport", "total": 2500 }
  ],
  "topCategory": { "category": "Food", "total": 5000 },
  "dailyAverage": 416.67,
  "last30Days": [
    { "date": "2026-04-01", "total": 1200 }
  ],
  "thisMonthTotal": 12500,
  "lastMonthTotal": 9000,
  "monthComparisonPercentage": 38.89
}
```

### Delete Expense

```bash
curl -X DELETE http://localhost:5000/api/expenses/EXPENSE_ID \
  -H "Authorization: Bearer JWT_TOKEN"
```

## ML Integration

The backend calls:

```text
POST ${ML_SERVICE_URL}/predict
```

Request:

```json
{
  "description": "uber ride home"
}
```

Expected response:

```json
{
  "category": "Transport",
  "confidence": 0.88,
  "all_probabilities": {
    "Food": 0.02,
    "Transport": 0.88
  }
}
```

Only known categories are accepted. Unknown categories, timeouts, network failures, or service errors fall back to `Other`.

## Error Format

Errors use:

```json
{
  "success": false,
  "message": "Error message"
}
```

Stack traces are omitted when `NODE_ENV=production`.

## Future Improvements

- Add automated integration tests.
- Add refresh tokens.
- Add pagination for expenses.
- Store user correction events separately for future ML retraining.
- Add rate limiting and request logging.
- Add API documentation with OpenAPI.
- Add deployment configuration when the backend is ready for hosting.
