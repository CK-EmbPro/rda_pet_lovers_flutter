# Fix: PET_OWNER Role Not Assigned After Adoption

**Date:** 2026-02-20

## Problem

After a successful adoption, the user's role was not being upgraded to `PET_OWNER` in the database. The user was redirected to login but still had only the `USER` role, causing them to land back on the guest portal.

## Root Cause

The `Role` table has two fields:
- `name` — human-readable string (e.g. `'Pet Owner'`, `'Shop Owner'`)
- `roleType` — enum value (e.g. `PET_OWNER`, `SHOP_OWNER`)

The seed data (`scripts/seeds/roles.seed.ts`) creates roles with human-readable names:
```ts
{ name: 'Pet Owner', roleType: 'PET_OWNER' }
```

But the adoption code was looking up by the wrong field:
```ts
// BUG: 'PET_OWNER' doesn't match seed name 'Pet Owner'
await this.prisma.role.findUnique({ where: { name: 'PET_OWNER' } });
```

This returned `null`, so the `if (petOwnerRole)` guard silently skipped the role assignment.

## Fix

Changed all 3 occurrences to use `roleType` (the enum field) instead of `name`:

```ts
// FIXED
await this.prisma.role.findFirst({ where: { roleType: 'PET_OWNER' } });
```

(`findFirst` is used because `roleType` is not a `@unique` field in the schema.)

## Files Modified

| File | Location |
|------|----------|
| `pet-listings.service.ts` | `adopt()` method — line 163 |
| `pets.service.ts` | `create()` method — line 189 |
| `pets.service.ts` | `transferOwnership()` method — line 493 |

## Note

`orders.service.ts` already used the correct approach (`roleType: RoleType.PET_OWNER`), so no change was needed there.
