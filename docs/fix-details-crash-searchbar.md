# Fix: Details Pages Crash & Search Bar Update

## Date: 2026-02-16

## Issues Fixed

### 1. Container Margin Assertion Failure
**Error**: `'margin == null || margin.isNonNegative': is not true`

**Root Cause**: Both `PetDetailsPage` and `ProductDetailsPage` used negative `EdgeInsets` on their content containers to create a visual overlap with the header image:
- `PetDetailsPage` line 95: `margin: EdgeInsets.only(top: -24)`
- `ProductDetailsPage` line 101: `margin: EdgeInsets.only(top: -20)`

Flutter's `Container` widget asserts that margin values must be non-negative.

**Fix**: Replaced `margin` with `transform: Matrix4.translationValues(0, -24, 0)` which achieves the same visual overlap without violating the assertion.

### 2. ShopDetailsPage Search Bar
**Issue**: Search bar style didn't match the homepage/dashboard pattern.

**Fix**: Replaced with the homepage-style search bar featuring:
- White container with subtle shadow
- Search icon on the left
- Filter (tune) icon button on the right with `AppColors.inputFill` background
- No outer border (cleaner look)

## Files Modified
- `portals/common/pages/pet_details_page.dart`
- `portals/common/pages/product_details_page.dart`
- `portals/common/pages/shop_details_page.dart`
