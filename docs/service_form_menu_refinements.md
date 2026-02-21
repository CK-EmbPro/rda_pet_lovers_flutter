# Service Form & Menu Refinements

**Date:** 2026-02-21  
**Status:** Complete — 0 compile errors

---

## Changes

### 1. Removed "Requires Subscription" Toggle — `service_form_sheet.dart`

**Rationale:** The `SUBSCRIPTION` payment type option already implies the service requires a subscription. Having a separate toggle was redundant and confusing.

- Removed the `_SubscriptionToggle` widget class entirely.
- Changed `_requiresSubscription` from a mutable state field to a computed getter: `bool get _requiresSubscription => _paymentType == 'SUBSCRIPTION';`
- This value is still sent correctly to the backend on create/update.

### 2. Restyled Service Card Popup Menu — `my_services_page.dart`

**Rationale:** The old popup menu used a square rounded container with `Icons.more_vert`, which looked inconsistent with the rest of the app. The My Pets page uses a cleaner circular semi-transparent backdrop.

**Changes made to `_ServicePopupMenu`:**
- Wrapped `PopupMenuButton` in a circular `Container` with `BoxShape.circle` and `Colors.black.withValues(alpha: 0.15)` — matches My Pets pattern.
- Changed icon to `Icons.more_horiz` (horizontal dots) with white color.
- Set `padding: EdgeInsets.zero`.
- Updated popup items to use `Icons.edit`, `Icons.visibility`/`Icons.visibility_off`, and `Icons.delete` — matching My Pets item style exactly.
- Changed spacing from `SizedBox(width: 10)` to `SizedBox(width: 8)` to match My Pets.
