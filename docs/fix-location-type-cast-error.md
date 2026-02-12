# Fix: Location Type Cast Error in Filter Sheet

## Date: 2026-02-12

## Problem
Opening the Filter Sheet displayed:
```
Error loading locations: An unexpected error occurred: type 'String' is not a subtype of type Map<String, dynamic> in type cast
```

## Root Cause
The backend `GET /locations/districts` endpoint returns a **flat list of strings** (e.g. `["Kicukiro", "Nyarugenge"]`), but `LocationService.getDistricts` was casting each item to `Map<String, dynamic>` for `LocationModel.fromJson()`.

## Fix
Updated `LocationService.getDistricts` in `lib/data/services/location_service.dart` to detect each item's type:
- **String**: Create a `LocationModel` directly from the name.
- **Map**: Parse normally via `LocationModel.fromJson()`.

## Files Changed
- `lib/data/services/location_service.dart`
