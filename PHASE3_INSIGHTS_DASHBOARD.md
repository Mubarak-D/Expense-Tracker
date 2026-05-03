# ETML Insights Dashboard

The Insights dashboard adds a focused spending overview to the Flutter app.
It uses the existing backend endpoint:

```http
GET /api/expenses/stats
Authorization: Bearer <token>
```

## Screen

The dashboard is available as the first tab in the main app shell:

```text
Insights
Add
Ledger
```

It shows:

- Monthly spending total
- This month compared with last month
- Top spending category
- Daily average spend
- Last 30 days spending trend
- Category breakdown

## UI Principles

The screen keeps the existing ETML visual language:

- Dark futuristic surfaces
- Glass-style panels
- Subtle fade and slide motion
- Clear hierarchy for totals and labels
- Lightweight custom charts with no extra dependency

## States

The screen handles the expected product states:

- Loading skeleton while stats are fetched
- Empty state when no expenses exist
- Error state with retry when the backend is unavailable
- Pull-to-refresh for manual reloads

Empty-state copy:

```text
No expenses yet
Add your first expense to unlock spending insights.
```

## Data Source

The Flutter app parses the stats response into:

- `ExpenseStats`
- `CategorySpend`
- `DailySpend`

State is exposed through `expenseStatsProvider`, keeping API fetching out of
the screen widgets.

## Notes

This phase does not add budget goals, change the ML model, or introduce live
retraining. It only visualizes spending data that the backend already provides.
