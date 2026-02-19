# Homepage Listing Section Updates

**Date:** 2026-02-19  
**Module:** Home Page — Being Sold & For Adoption sections  
**Type:** UI Change

## Changes

1. **Removed `.take(5)` limit** — Both "Being Sold" and "For Adoption" sections now show **all** listings returned by the API (up to the provider's limit of 50)
2. **Removed "See all" links** — The `_buildPetsSectionHeader` method no longer includes a `TextButton` with "See all". It now only shows the section title.

## Files Modified

- `home_page.dart` — lines 265, 291 (removed `.take(5)`), lines 806–820 (simplified header, removed onSeeAll callback)
