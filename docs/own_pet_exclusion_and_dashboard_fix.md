# Own Pet Exclusion and Dashboard Fix

## Issue Description
1. Users were seeing their own pets in the public listing sections (Being Sold, Being Donated) on the dashboard.
2. The dashboard was incorrectly using `allPetsProvider` which fetches raw Pet entities instead of Listing entities.
3. The dashboard had incorrect filtering logic using `listingType == 'FOR_SALE'` which didn't match backend values.

## Changes Implemented

### Backend
- **DTO**: Added `excludeOwnerId` to `QueryListingsDto`.
- **Service**: Updated `PetListingsService.findAll` to handle the `excludeOwnerId` filter using Prisma.
- **Controller**: Updated `PetListingsController` to automatically pass the logged-in user's ID as `excludeOwnerId` for all public listing endpoints.

### Frontend
- **Providers**: Added `forAdoptionListingsProvider` and `forSaleListingsProvider` to the dashboard's watched providers.
- **Dashboard Logic**: Removed incorrect model-level filtering. Now uses the dedicated listing providers which return the correct data from the backend.
- **UI Components**: Updated `_buildPetListingsHorizontalList` to handle `PetListingModel` incorrectly and display correct labels.

## Verification Result
- Backend rebuilt successfully with code for automatic exclusion.
- Dashboard now correctly displays listings from other users using the dedicated listing API endpoints.
