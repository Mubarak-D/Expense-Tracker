# ETML Phase 6 Ledger Filters

Phase 6 adds lightweight ledger filtering in the Flutter app.

The backend already supports expense filters through query parameters, but this
phase focuses on the mobile workflow: users can quickly narrow the visible
ledger by text and category without reloading data from the API.

## Flutter

The Transactions screen now includes:

- Search by description or category
- Category filter chips
- Filter-aware empty state
- Visible-spend total based on the filtered result set

The filters are local to the loaded transaction list. Pull-to-refresh still
reloads the full ledger from the backend.

## Behavior

Search checks:

- Expense description
- Saved category
- Predicted category

The category filter uses the existing ETML category list:

- Food
- Transport
- Bills
- Shopping
- Health
- Entertainment
- Education
- Other

## Verification

Flutter checks:

```bash
cd etml_mobile
flutter analyze
flutter test
```
