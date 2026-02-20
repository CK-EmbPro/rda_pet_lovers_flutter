# Fix: Error Handling and Toast Accuracy

**Date:** 2026-02-20

## Problem

Frontend was showing success toasts (e.g. "Pet updated successfully!") even when the backend returned 400/404 errors. This happened because:

1. `PetCrudNotifier` methods (`listForSale`, `listForDonation`, `cancelListing`) catch all errors internally and return `false`
2. `pet_form_sheet.dart` never checked the return values — always proceeded to show success toast
3. Backend error messages (like "Pet is already listed for donation") were silently swallowed

## Root Cause (Backend)

`pets.service.ts` → `listForDonation()` and `listForSale()` used overly strict status checks:
```ts
// BEFORE: rejects ADOPTED/SOLD — too strict
if (pet.donationStatus !== DonationStatus.ACTIVE) { throw... }

// AFTER: only blocks actively-pending listings
if (pet.donationStatus === DonationStatus.DONATION_PENDING) { throw... }
```

## Fix (Frontend)

**`pet_form_sheet.dart`:**
- Now checks return values of `listForSale()`, `listForDonation()`, `cancelListing()`
- If any returns `false`, extracts the error from provider state using new `_extractProviderError()` helper
- Shows error toast with the actual backend message instead of a false success

## Files Modified

| File | Change |
|------|--------|
| `pets.service.ts` | Relaxed validation: `!== ACTIVE` → `=== PENDING` for 3 checks |
| `pet_form_sheet.dart` | Check listing return values, extract backend errors, context-aware toasts |
