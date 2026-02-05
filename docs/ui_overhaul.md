# UI Cleanup and Navigation Overhaul

## Changes Summary

### 1. Theming
- Primary color updated to `#21314C`.
- Header gradients simplified to solid slate color.
- Active tab backgrounds updated to slate.

### 2. Authentication Flow
- Centered all header elements (logo, title, subtitle) in `LoginPage` and `RegisterPage`.
- Fixed tab gesture detection for better navigation experience.

### 3. Portal Structure & Navigation
- Renamed "Dashboard" to "Home" in all portals.
- Integrated `MarketplacePage` from `pet_owner` portal into `UserPortal`.
- Updated all "See all" links to navigate to respective tabs:
    - Shops -> Marketplace
    - Pets (Sold/Donated) -> Pets Page
- Linked profile avatars in headers to the Profile page.
- Linked notification icons to the Notifications sheet.

### 4. Component Updates
- **QuickActions**: "Add Pet" is now icon-only.
- **Pets Page**:
    - Moved category filters out of the header.
    - Updated active category color to slate.
    - Simplified header layout.

### 5. Backend/Mock Data
- Ensured pets are correctly split by `listingType` (FOR_SALE vs FOR_DONATION) on dashboards.

## Files Modified
- `lib/core/theme/app_theme.dart`
- `lib/features/auth/presentation/pages/login_page.dart`
- `lib/features/auth/presentation/pages/register_page.dart`
- `lib/portals/user/user_portal.dart`
- `lib/portals/user/pages/home_page.dart`
- `lib/portals/user/pages/pets_page.dart`
- `lib/portals/pet_owner/pages/dashboard_page.dart`
- `lib/core/widgets/appointment_form_sheet.dart`
