# Fix: Re-listing Adopted Pets + Toast Mismatch

**Date:** 2026-02-20

## Problem 1: Adopted Pet Cannot Be Re-listed

After adoption, the pet's `donationStatus` was set to `ADOPTED`, preventing the new owner from listing it again for donation. The backend's `listForDonation()` check rejected with:"Pet is already listed for donation or adopted".

### Root Cause

In `pet-listings.service.ts` → `adopt()`, the pet update set `donationStatus: DonationStatus.ADOPTED`. This is wrong because the **listing** (not the pet) should carry the ADOPTED status. The pet should be clean for the new owner.

### Fix

Changed `adopt()` to reset both `donationStatus` and `sellingStatus` to `ACTIVE` after ownership transfer:

```diff
 this.prisma.pet.update({
     where: { id: listing.petId },
     data: {
         ownerId: adopterId,
-        donationStatus: DonationStatus.ADOPTED,
+        donationStatus: DonationStatus.ACTIVE,
+        sellingStatus: SellingStatus.ACTIVE,
     },
 }),
```

---

## Problem 2: Toast Message Mismatch

When a user listed a pet for donation, the toast showed **"Pet updated successfully!"** instead of a relevant message.

### Root Cause

`pet_form_sheet.dart:477` hardcoded the same success toast for all update scenarios.

### Fix

Made the toast context-aware:

| Action | Old Toast | New Toast |
|--------|-----------|-----------|
| Register new pet | 🎉 Pet registered! | *(unchanged)* |
| List for donation | Pet updated successfully! ❌ | 🐾 Pet listed for donation! ✅ |
| List for sale | Pet updated successfully! ❌ | 🏷️ Pet listed for sale! ✅ |
| General update | Pet updated successfully! | *(unchanged)* |

## Files Modified

| File | Change |
|------|--------|
| `pet-listings.service.ts` | Reset donationStatus/sellingStatus to ACTIVE in adopt() |
| `pet_form_sheet.dart` | Context-aware toast messages |
