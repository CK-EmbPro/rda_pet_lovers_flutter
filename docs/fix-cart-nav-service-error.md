# Fix: Cart Navigation & Service Details Error

## Date: 2026-02-16

## Issues Fixed

### 1. Cart Icon & Buy Now Navigation (PetDetailsPage)
**Problem**: The cart icon in the app bar and the "Buy Now" button used `context.push('$portalRoute/cart')` which opened a standalone cart page without the bottom navigation bar.

**Fix**: Changed both to `context.go('$portalRoute?tab=cart')` which navigates to the portal's cart tab, keeping the taskbar (bottom navigation) visible.

**File**: `portals/common/pages/pet_details_page.dart` (lines 78, 473)

### 2. Service Details Type Cast Error
**Error**: `type '_Map<String, dynamic>' is not a subtype of type 'String?' in type cast`

**Root Cause**: The backend returns Map objects (e.g., `{ id: "...", name: "..." }`) for fields like `categoryId`, `paymentType`, `paymentMethod`, `description`, and `serviceType` — but `ServiceModel.fromJson` cast them directly with `as String?`.

**Fix**: Added a `_extractString()` helper method that safely handles `String`, `Map`, and `null` values:
- If `String` → returns as-is
- If `Map` → extracts a specified key (default: `'name'`, or `'id'` for IDs)
- If `null` → returns null

Applied to: `serviceType`, `description`, `categoryId`, `paymentMethod`, `paymentType`

**File**: `data/models/service_model.dart`
