# ETML Phase 4 Budget Goals

Phase 4 adds a monthly budget goal and lightweight achievement experience.
It is intentionally simple: users can set one goal for a month, track progress,
and see a small motivational state based on spending.

This phase does not add notifications, complex gamification, automatic ML
retraining, or budget recommendations.

## Backend

Budget goals are exposed under:

```http
/api/goals
```

All goal routes require JWT authentication.

### Create Or Update Goal

```http
POST /api/goals
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "month": "2026-04",
  "monthlyLimit": 50000
}
```

If `month` is omitted, the backend uses the current UTC month. Each user can
have one goal per month.

### Current Goal Progress

```http
GET /api/goals/current?month=2026-04
Authorization: Bearer <token>
```

Example response:

```json
{
  "goalSet": true,
  "month": "2026-04",
  "monthlyLimit": 50000,
  "totalSpent": 32000,
  "remaining": 18000,
  "progressPercentage": 64,
  "status": "on_track",
  "achievement": {
    "title": "Budget Guardian",
    "description": "You are staying within your monthly spending goal.",
    "unlocked": true
  }
}
```

If no goal exists:

```json
{
  "goalSet": false,
  "month": "2026-04",
  "message": "No budget goal set for this month."
}
```

## Status Logic

| Progress | Status | Achievement |
|---|---|---|
| Below 80% | `on_track` | Budget Guardian |
| 80% to 100% | `warning` | Careful Spender |
| Above 100% | `over_budget` | Reset Plan |

## Flutter

The Insights screen includes a `Budget Goal` card.

When no goal exists, it shows:

```text
Set a monthly goal to track your spending progress.
```

When a goal exists, it shows:

- Monthly limit
- Total spent
- Remaining amount
- Animated progress bar
- Status badge
- Achievement tile
- Update Goal action

The card uses the existing ETML dark glass style and keeps the language
motivating without shaming the user.

## Verification

Backend smoke checks should cover:

- Creating/updating a goal
- Fetching current progress
- `on_track`, `warning`, and `over_budget` statuses
- User isolation
- Rejection of invalid `monthlyLimit`

Flutter checks:

```bash
cd etml_mobile
flutter analyze
flutter test
flutter build web
```
