# Pet Listing Visibility Fix

**Date:** 2026-02-19  
**Module:** Pet Listings, Home Page, Pets Page  
**Type:** Bug Fix + UI Integration

---

## Problem

Pets listed for sale or donation were completely invisible to users — both guests on the dashboard and pet owners. The "Being Sold" and "Being Donated" sections on the home page always appeared empty.

## Root Causes (4 bugs found)

| # | File | Bug | Backend Value | Old Frontend Value |
|---|------|-----|---------------|--------------------|
| 1 | `pet_listing_service.dart` | `fromJson` mapped `listerId` instead of `ownerId` | `ownerId` | `listerId` |
| 2 | `pet_listing_service.dart` | Status mapped as `ACTIVE` instead of `PUBLISHED` | `PUBLISHED` | `ACTIVE` |
| 3 | `home_page.dart` | Used `allPetsProvider` and compared `listingType == 'FOR_SALE'` (wrong provider + wrong enum) | — | — |
| 4 | `pets_page.dart` | No "For Sale" or "For Adoption" tabs — only general pet directory | — | — |

---

## Changes Made

### 1. `pet_listing_service.dart` — Fixed Model Parsing
- `listerId` → `ownerId` (correct backend field)  
- `status: 'ACTIVE'` → `status: 'PUBLISHED'` (correct backend enum)
- `listingType: 'FOR_SALE'` → `'SELL'` and `'FOR_DONATION'` → `'DONATE'`
- Added convenience getters: `petName`, `petImage`, `petSpecies`, `ownerName`, `ownerAvatar`, `displayPrice`
- Added `locationId`, `viewCount`, `inquiryCount`, `publishedAt`, `expiresAt` fields

### 2. `home_page.dart` — Switched to Real Listing API
- Removed `allPetsProvider` from listing sections
- Now uses `forSaleListingsProvider` and `forAdoptionListingsProvider`
- Added `_PetListingCard` widget with: pet image, price/free badge (color-coded), species, owner avatar + name

### 3. `pets_page.dart` — Complete Rewrite with 3 Tabs
- Added `TabController` with 3 tabs: **All Pets**, **🏷️ For Sale**, **💜 Adoption**
- "For Sale" tab pulls from `/pet-listings/for-sale` (public endpoint)
- "Adoption" tab pulls from `/pet-listings/for-adoption` (public endpoint)
- Added pull-to-refresh on listing tabs
- Added `_ListingGridCard` — shows pet image, price badge, species, owner
- Species filter chips work for the All Pets tab

### 4. `pet_form_sheet.dart` — Minor Lint Fixes
- `activeColor` → `activeThumbColor` (deprecated API update)
- Unnecessary cast removed in error handling
- Fixed null-aware pattern in image list

---

## Analysis Result

```
Before: 14 issues (1 critical error — AutoDisposeProviderListenable undefined)
After:   3 issues  (info only — pre-existing null-aware style hints)
Errors:  0
```
