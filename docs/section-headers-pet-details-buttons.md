# Section Headers & Pet Details Buttons Update

**Date:** 2026-02-19  
**Module:** Home Page + Pet Details Page  
**Type:** UI Change

## Changes

### Home Page (`home_page.dart`)
- Removed emoji prefixes from "Being Sold" and "For Adoption" section headers
- Added `Align(alignment: Alignment.centerLeft)` to ensure left alignment

### Pet Details Page (`pet_details_page.dart`)
- **Adoption pets** (`pet.isForDonation == true`): Bottom action bar now shows a single full-width purple "Adopt Now" button with a `volunteer_activism` icon
- **Sale pets**: Retains the existing "Add to Cart" + "Buy Now" two-button layout
