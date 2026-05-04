# ETML Phase 5 Recurring Expenses

Phase 5 adds simple monthly recurring expense templates for bills,
subscriptions, rent, and other repeat spending.

The feature keeps templates separate from posted expenses. A recurring template
only affects spending totals after the user posts it, which creates a normal
expense that appears in the ledger, budget progress, and insights.

## Backend

Recurring expenses are exposed under:

```http
/api/recurring-expenses
```

All recurring expense routes require JWT authentication.

### List Templates

```http
GET /api/recurring-expenses
Authorization: Bearer <token>
```

### Create Template

```http
POST /api/recurring-expenses
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "amount": 2500,
  "description": "Monthly rent",
  "category": "Bills",
  "nextRunDate": "2026-05-10T00:00:00.000Z"
}
```

### Post Template Now

```http
POST /api/recurring-expenses/:id/post
Authorization: Bearer <token>
```

Posting creates a normal expense from the template, updates `lastPostedAt`, and
advances `nextRunDate` by one month.

### Delete Template

```http
DELETE /api/recurring-expenses/:id
Authorization: Bearer <token>
```

## Flutter

The Transactions screen includes a `Recurring` panel.

Users can:

- Create a monthly recurring expense template
- Choose amount, description, category, and next run date
- Post a template into the ledger immediately
- Remove a template

After posting a template, the app refreshes the affected local state:

- Ledger transactions
- Insights stats
- Budget goal progress

## Verification

Backend smoke checks should cover:

- Creating a recurring template
- Listing templates
- Posting a template into expenses
- Advancing the next run date
- Deleting a template
- Rejecting invalid amounts and invalid categories

Flutter checks:

```bash
cd etml_mobile
flutter analyze
flutter test
```
