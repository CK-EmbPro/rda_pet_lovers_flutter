# Fix: Pet Creation birthDate Validation Error

**Date:** 2026-02-16

## Issue
Creating a pet with a `birthDate` failed with:
```
Invalid value for argument `birthDate`: premature end of input. Expected ISO-8601 DateTime.
```

## Root Cause
Dart's `DateTime.toIso8601String()` outputs `2026-02-03T00:00:00.000` (no `Z` suffix) for local dates. Prisma requires a full ISO-8601 DateTime with timezone indicator.

## Fix
**File:** `rwanda-pet-lovers-backend/src/modules/pets/pets.service.ts`

In both `create()` and `update()` methods, added a pre-processing step to convert `birthDate` strings to proper `Date` objects before passing to Prisma:

```typescript
if (data.birthDate && !(data.birthDate instanceof Date)) {
    data.birthDate = new Date(data.birthDate);
}
```

This ensures any valid date string is normalized to a JavaScript `Date` object, which Prisma can serialize correctly.
