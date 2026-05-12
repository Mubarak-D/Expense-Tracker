# ETML Demo Data

Use the demo seed script to make a local ETML install look realistic for
portfolio demos, screenshots, README assets, LinkedIn posts, and walkthrough
videos.

## What Gets Created

The seed command creates one demo account:

```text
Name: Demo User
Email: demo@etml.app
Password: password123
```

It also creates:

- 36 realistic expenses across the current and previous month
- all expense categories: Food, Transport, Bills, Shopping, Health,
  Entertainment, Education, and Other
- accepted ML predictions with high confidence scores
- 10 manual correction examples with low confidence predictions
- one current-month budget goal with a `monthlyLimit` of `50000`
- five recurring monthly templates for Netflix, gym, phone, internet, and
  online learning

## Startup Flow

1. Start MongoDB.

```bash
mongod
```

2. Start the backend.

```bash
cd expense-tracker-backend
npm install
npm run dev
```

3. Run the demo seed script in another terminal.

```bash
cd expense-tracker-backend
npm run seed:demo
```

4. Start the ML service.

```bash
cd expense-ml-service
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
python train_model.py
uvicorn app.main:app --reload
```

5. Start the Flutter app.

```bash
cd etml_mobile
flutter pub get
flutter run -d chrome
```

## Safety

The seed script is repeatable. Before creating data, it deletes only the demo
account and records owned by that account:

- demo expenses
- demo budget goals
- demo recurring expenses
- demo user

It does not delete non-demo users. Running `npm run seed:demo` twice refreshes
the same demo account and does not duplicate demo data.

The script also cleans up the older local demo account,
`demo@etml.local`, if it exists from previous development runs.

## Verify In The App

Log in with:

```text
demo@etml.app
password123
```

Expected behavior:

- the ledger shows realistic Sri Lankan and global-style transactions
- searching for `uber`, `pickme`, `netflix`, `dialog`, `fuel`, or `course`
  returns meaningful results
- category filters have data in every category
- Insights shows current-month totals, category breakdown, and daily trend data
- Budget Goals shows a populated current-month goal that is not over budget
- Recurring Expenses shows five templates
- Feedback summary shows manual corrections and low-confidence predictions

## Verification Commands

Run the seed command twice:

```bash
cd expense-tracker-backend
npm run seed:demo
npm run seed:demo
```

Both runs should report:

```text
Expenses: 36
Manual corrections: 10
Recurring templates: 5
```

Demo login can be verified through the backend:

```bash
curl -X POST http://localhost:5000/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"demo@etml.app\",\"password\":\"password123\"}"
```
