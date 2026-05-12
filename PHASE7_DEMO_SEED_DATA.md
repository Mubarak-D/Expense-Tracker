# Phase 7 - Demo Seed Data

This phase adds a repeatable backend seed command that turns a fresh local ETML
database into a portfolio-ready demo environment.

## Command

```bash
cd expense-tracker-backend
npm run seed:demo
```

The script uses `MONGO_URI` from `.env`. If `MONGO_URI` is not set, it falls
back to:

```text
mongodb://localhost:27017/etml
```

## Demo Login

```text
Email: demo@etml.local
Password: password123
```

These can be overridden before running the command:

```bash
DEMO_SEED_EMAIL=demo@example.com DEMO_SEED_PASSWORD=password123 npm run seed:demo
```

PowerShell:

```powershell
$env:DEMO_SEED_EMAIL='demo@example.com'
$env:DEMO_SEED_PASSWORD='password123'
npm run seed:demo
```

## Seeded Content

- One dedicated demo user
- Eighteen realistic expenses across the current and previous month
- Three manual ML correction examples for feedback export and summary views
- A current-month budget goal with visible progress
- Three active monthly recurring expense templates
- Category variety across food, transport, bills, shopping, health,
  entertainment, and education

## Safety

The seed command only replaces data for the configured demo email. It removes
that demo user's expenses, goals, and recurring templates, then recreates the
demo account from scratch. Other users are left untouched.
