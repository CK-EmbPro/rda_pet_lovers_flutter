# Pet Registration Form Alignment with Backend DTOs

**Date:** 2026-02-16

## Summary

Rewrote the pet registration form (`pet_form_sheet.dart`) to fully align with the backend `CreatePetDto` and added image upload support via a new `StorageService`.

## Changes Made

### New Files
- **`lib/data/services/storage_service.dart`** — Upload service for single/multiple files to `POST /storage/upload` and `POST /storage/upload/multiple` endpoints.

### Modified Files
- **`lib/core/api/dio_client.dart`** — Added `storageUpload` and `storageUploadMultiple` to `ApiEndpoints`.
- **`lib/portals/pet_owner/widgets/pet_form_sheet.dart`** — Full rewrite:
  - Replaced single `XFile` photo with `List<XFile>` multi-image picker (horizontal scroll row with delete buttons)
  - Added Camera + Gallery source picker bottom sheet
  - Added `birthDate` date picker field
  - Added `nationality` text field
  - On submit: uploads images to storage → passes returned URLs to `createPet(images: urls)`
  - Removed unused `_locationController` (locationId was text-based before, needs proper location dropdown in future)

## Backend DTO Alignment

| CreatePetDto Field | Form Support |
|---|---|
| name | ✅ |
| speciesId | ✅ |
| breedId | ✅ |
| gender | ✅ |
| weightKg | ✅ |
| ageYears | ✅ |
| birthDate | ✅ (NEW) |
| nationality | ✅ (NEW) |
| images[] | ✅ (NEW — multi-image with upload) |
| videos[] | ❌ (not yet implemented) |
| description | ✅ |
| healthSummary | ✅ |
