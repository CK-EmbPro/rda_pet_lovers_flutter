# Adoption Role Assignment Fix

## Problem
After a successful pet adoption, the adopting user's role remained `USER` instead of being upgraded to `PET_OWNER`. The user had to log out and back in to get the correct role reflected.

## Root Cause Analysis

### Backend — Missing Role Assignment in `adopt()`
The `create()` method in `pets.service.ts` correctly assigns the `PET_OWNER` role when a user registers a pet. However, neither the `adopt()` nor `transferOwnership()` methods did the same — they changed pet ownership in the DB but **never touched `user_roles`**.

| Method | File | Role assigned? |
|--------|------|---------------|
| `create()` | `pets.service.ts` | ✅ Yes |
| `adopt()` | `pet-listings.service.ts` | ❌ **Missing** |
| `transferOwnership()` | `pets.service.ts` | ❌ **Missing** |

### Frontend — No Auth Refresh After Adoption
Even with the backend fixed, the in-memory auth state (Riverpod `authStateProvider`) was never refreshed after adoption. The app showed stale roles until the next login.

## Fixes Applied

### 1. `src/modules/pet-listings/pet-listings.service.ts` — `adopt()`
Added `userRole.upsert` after the ownership transaction:
```typescript
const petOwnerRole = await this.prisma.role.findUnique({ where: { name: 'PET_OWNER' } });
if (petOwnerRole) {
  await this.prisma.userRole.upsert({
    where: { userId_roleId: { userId: adopterId, roleId: petOwnerRole.id } },
    create: { userId: adopterId, roleId: petOwnerRole.id },
    update: {}, // no-op if already exists
  });
}
```

### 2. `src/modules/pets/pets.service.ts` — `transferOwnership()`
Same `userRole.upsert` pattern added for `toUserId` after transaction.

### 3. `lib/portals/common/pages/pet_details_page.dart` — Adoption success handler
Replaced `refreshUser()` with a **forced logout flow**:
1. Invalidate listing caches (`forAdoptionListingsProvider`, `allPetsProvider`)
2. Show a non-dismissible congratulations `AlertDialog` explaining the re-login requirement
3. On "Log In Now" button press → call `authStateProvider.notifier.logout()` (clears tokens + Riverpod state)
4. Navigate to `/login` via `context.go('/login')`

This ensures:
- The adopter sees the correct `PET_OWNER` portal immediately on next login
- No stale token or in-memory role state edge cases
- Clear UX communication of why re-login is needed

## Files Changed
| File | Change |
|------|--------|
| `src/modules/pet-listings/pet-listings.service.ts` | `adopt()` — assign PET_OWNER to adopter via upsert |
| `src/modules/pets/pets.service.ts` | `transferOwnership()` — assign PET_OWNER to new owner via upsert |
| `lib/portals/common/pages/pet_details_page.dart` | Force logout + re-login dialog after adoption success |

