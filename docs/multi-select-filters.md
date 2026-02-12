# Feature: Multi-Select Filters in FilterSheet

## Date: 2026-02-12

## Summary
Refactored the `FilterSheet` to support selecting **multiple** breeds, ages, and locations simultaneously instead of only one at a time.

## Changes

### `lib/core/widgets/filter_sheet.dart`
- Changed `selectedBreed` (single `String?`) → `selectedBreeds` (`Set<String>`)
- Changed `selectedAge` (single `String?`) → `selectedAges` (`Set<String>`)
- Changed `selectedLocation` (single `String?`) → `selectedLocations` (`Set<String>`)
- Tapping a chip toggles it on/off (add/remove from set)
- Added filter count badges next to each section header
- Added "Clear All" button in the header when any filters are active
- Added checkmark icon on selected chips for clear visual feedback
- Added active filter count summary above the Apply button
- `onApply` now emits lists (`breeds`, `ages`, `locations`) instead of single values
