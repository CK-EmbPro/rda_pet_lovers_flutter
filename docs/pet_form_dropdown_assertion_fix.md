# Dropdown Assertion Fix — Pet Form Edit Mode

## Problem
Opening a pet in edit mode caused a Flutter assertion failure:

```
'items == null || items.isEmpty || value == null ||
items.where((item) { return item.value == value; }).length == 1'
```

**Root cause:** The location, species, and breed dropdowns were passing the raw API response list directly to `DropdownButton`. If the API returned duplicate location/species/breed IDs (e.g. from a nested response), Flutter's `DropdownButton` assertion trips because the pre-populated value matches 2+ items. Similarly, if the list loads after `_selectedLocationId` is set in `initState`, a stale value that no longer exists in the list causes a "0 matches" variant of the same error.

## Fix Applied

### `lib/portals/pet_owner/widgets/pet_form_sheet.dart`

**All three dynamic dropdowns (Location, Species, Breed) were updated with:**

1. **Deduplication** — filter out items with the same ID before building `DropdownMenuItem` list:
   ```dart
   final seen = <String>{};
   final uniqueLocations = locations.where((l) => seen.add(l.id)).toList();
   ```

2. **Guard value** — only pass current selected ID as the dropdown `value` if it exists in the deduplicated list; otherwise pass `null` to show the hint:
   ```dart
   uniqueLocations.any((l) => l.id == _selectedLocationId)
       ? _selectedLocationId
       : null
   ```

3. **Post-frame state reset** — for location, clears `_selectedLocationId` after the frame if the value is not found (avoids triggering setState during build):
   ```dart
   WidgetsBinding.instance.addPostFrameCallback((_) {
     if (mounted) setState(() => _selectedLocationId = null);
   });
   ```

## Files Changed
| File | Change |
|------|--------|
| `lib/portals/pet_owner/widgets/pet_form_sheet.dart` | Deduplication + guard for location, species, breed dropdowns |
