# ETML - Expense Tracker with ML Categorization

ETML is a full-stack expense tracker with machine-learning category
prediction, manual correction feedback, and a polished Flutter dashboard.

The project is organized as a monorepo:

```text
ETML/
|-- expense-ml-service/       FastAPI + scikit-learn categorization service
|-- expense-tracker-backend/  Node.js/Express/MongoDB API
|-- etml_mobile/              Flutter app
|-- PHASE2_FEEDBACK_PIPELINE.md
|-- PHASE3_INSIGHTS_DASHBOARD.md
|-- PHASE4_BUDGET_GOALS.md
|-- PHASE5_RECURRING_EXPENSES.md
|-- PHASE6_LEDGER_FILTERS.md
`-- README.md
```

## Current Features

- User registration and login with JWT authentication
- Secure token storage in the Flutter app
- Expense creation and transaction listing
- ML category prediction from expense descriptions
- Manual category correction
- Correction metadata for future retraining
- Feedback export and summary endpoints
- Flutter ML feedback card and export action
- Flutter Insights dashboard with monthly totals, category breakdown, and
  last-30-days trend
- Monthly budget goals with progress and achievement states
- Recurring expense templates that can be posted into the ledger
- Local ledger search and category filters

## Architecture

```text
Flutter app
   |
   | REST + JWT
   v
Node.js backend
   |
   | /predict
   v
FastAPI ML service
   |
   v
scikit-learn expense classifier
```

The model does not retrain automatically when a user corrects a category.
Corrections are stored as feedback data and can be exported for future offline
retraining.

## Backend

```bash
cd expense-tracker-backend
npm install
cp .env.example .env
npm run dev
```

Important endpoints:

```http
POST /api/auth/register
POST /api/auth/login
GET  /api/expenses
POST /api/expenses
PUT  /api/expenses/:id
GET  /api/expenses/stats
GET  /api/expenses/feedback/export
GET  /api/expenses/feedback/summary
POST /api/goals
GET  /api/goals/current
GET  /api/recurring-expenses
POST /api/recurring-expenses
POST /api/recurring-expenses/:id/post
DELETE /api/recurring-expenses/:id
```

## ML Service

```bash
cd expense-ml-service
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
python train_model.py
uvicorn app.main:app --reload
```

Default service URL:

```text
http://127.0.0.1:8000
```

## Flutter App

```bash
cd etml_mobile
flutter pub get
flutter run -d chrome
```

For web builds:

```bash
flutter build web
```

## Verification

Useful checks:

```bash
cd etml_mobile
flutter analyze
flutter test
flutter build web
```

```bash
cd expense-tracker-backend
node --check src/server.js
```

```bash
cd expense-ml-service
python -m compileall app
```

## Documentation

- `PHASE2_FEEDBACK_PIPELINE.md` documents correction metadata, export, and
  summary behavior.
- `PHASE3_INSIGHTS_DASHBOARD.md` documents the Flutter Insights dashboard.
- `PHASE4_BUDGET_GOALS.md` documents monthly budget goals and progress.
- `PHASE5_RECURRING_EXPENSES.md` documents recurring expense templates.
- `PHASE6_LEDGER_FILTERS.md` documents local ledger search and filters.
