# Feature: Category Card Restyling

## Date: 2026-02-12

## Summary
Restyled category cards in `HomePage` and `DashboardPage` to match the app design mockup.

## Design
- **Color**: `#475569` (slate-600) used for borders, letters, and labels
- **Inactive**: White background, `#475569` border, letter and label in `#475569`
- **Active**: `#475569` filled background, letter turns white, label stays `#475569`
- **Multi-select**: Multiple categories can be selected simultaneously
- **Animation**: Smooth 200ms transition between active/inactive states

## Files Changed
- `lib/portals/user/pages/home_page.dart` — `_CategoriesWidget` (uses `CategoryModel`)
- `lib/portals/pet_owner/pages/dashboard_page.dart` — `_CategoriesWidget` (uses `SpeciesModel`)
