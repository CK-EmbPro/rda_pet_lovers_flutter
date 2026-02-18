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

**Fix**: Implemented a comprehensive `_extractString()` helper method and applied it to **ALL** string fields in `ServiceModel` and `ProviderInfo`.
- Handles `String` (returns as-is)
- Handles `Map` (returns specific key like `id` or `name` or `fullName`)
- Handles `null` (returns null)
- Added specific fallback for `ProviderInfo.fullName`: tries `fullName` -> `user.firstName` -> 'Provider'.

This ensures the app will never crash even if the backend returns fully populated objects for relationship fields (like `providerId`, `categoryId`, `user`).

**File**: `data/models/service_model.dart`
