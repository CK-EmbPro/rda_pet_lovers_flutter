# Services Module Integration

**Date:** 2025  
**Status:** Complete — 0 compile errors  

---

## Overview

Comprehensive integration of the services module to align the mobile app with the backend's `ServiceEntity`, `CreateServiceDto`, and `UpdateServiceDto`. All frontend models, API calls, providers, and UI components now use the backend's exact field names.

---

## Files Changed

### 1. `lib/data/models/service_model.dart`
- **Renamed fields:** `fee` → `basePrice`, `paymentMethod` → `paymentType`, `isActive` → `isAvailable`
- **Added fields:** `serviceCode`, `currency`, `requiresSubscription`, `priceYoungPet`, `priceOldPet`
- **Removed:** `serviceType` (fake field, not on backend entity)
- **Added:** `ServiceCategory` model class
- **Added:** `paymentTypeLabel` getter (human-readable label for `PAY_UPFRONT`, `PAY_AFTER`, `SUBSCRIPTION`)
- **Updated:** `fromJson` with robust null-safe parsing; `toCreateDto()` sends correct DTO keys

### 2. `lib/data/services/service_api_service.dart`
- **Added import:** `pet_service.dart show PaginatedResponse` to resolve type usage
- **Added:** `getCategories()` → calls public `/services/categories` endpoint
- **Fixed:** `getAll()` and `getMyServices()` now correctly unwrap `{data, meta}` paginated response
- **Fixed:** `create()` and `update()` send correct DTO field names: `paymentType`, `priceYoungPet`, `priceOldPet`, `categoryId`, `requiresSubscription`

### 3. `lib/data/providers/service_providers.dart`
- **Added import:** `pet_service.dart show PaginatedResponse`
- **Added:** `serviceApiCategoriesProvider` — fetches `List<ServiceCategory>` from the services API  
  _(renamed from `serviceCategoriesProvider` to avoid naming collision with `category_providers.dart`)_
- **Removed:** `serviceType` from `ServiceQueryParams` (not a backend field); replaced with `paymentType`
- **Updated:** `ServiceCrudNotifier.createService()` signature matches new API params

### 4. `lib/portals/provider/widgets/service_form_sheet.dart`
- **Removed:** Fake `serviceType` dropdown
- **Added fields:** `priceYoungPet`, `priceOldPet`, `requiresSubscription` toggle
- **Added:** Category dropdown wired to `serviceApiCategoriesProvider`
- **Added:** Visual payment type selector with all 3 backend options (`PAY_UPFRONT`, `PAY_AFTER`, `SUBSCRIPTION`)
- **Fixed:** Pre-population of all fields when editing an existing service
- **Fixed:** Submit payload matches backend DTO exactly

### 5. `lib/portals/provider/pages/my_services_page.dart`
- **Fixed:** All `isActive` → `isAvailable`
- **Removed:** Redundant "Edit Details" button from card view
- **Replaced:** Separate edit/delete icon buttons in list view with 3-dot `PopupMenuButton` (matches My Pets page pattern)
- **Added:** Inline toggle availability in the 3-dot menu
- **Improved:** Payment type, duration, and category display

### 6. `lib/portals/common/pages/service_details_page.dart`
- **Fixed:** `service.fee` → `service.basePrice` with `service.currency`
- **Fixed:** `service.isActive` → `service.isAvailable`
- **Fixed:** `service.paymentMethod` → `service.paymentTypeLabel`
- **Fixed:** `service.serviceType` / `service.displayServiceType` → `service.category?.name`
- **Fixed:** `provider.businessName` → `provider.title`
- **Updated:** `_getIconForType()` to use category name substring matching instead of exact enum switch

### 7. `lib/portals/user/pages/services_page.dart`
- **Removed:** `serviceType` param from `ServiceQueryParams` (undefined)
- **Fixed:** `service.provider?.specialty` → `service.provider?.title`
- **Fixed:** `service.displayServiceType` → `service.category?.name ?? service.paymentTypeLabel`
- **Fixed:** `service.fee` → `service.basePrice` with `service.currency`
- **Fixed:** Null-safe access on paginated `.data` property

### 8. `lib/portals/user/pages/home_page.dart`
- **Fixed:** `service.fee` → `service.basePrice` with `service.currency`

### 9. `lib/portals/provider/pages/provider_reports_page.dart`
- **Fixed:** `apt.service!.fee` → `apt.service!.basePrice` (×2 occurrences)

### 10. `lib/portals/pet_owner/pages/dashboard_page.dart`
- **Fixed:** `service.fee` → `service.basePrice` with `service.currency`

### 11. `lib/core/widgets/appointment_form_sheet.dart`
- **Fixed:** `ServiceModel.empty()` (no longer exists) replaced with null-safe `cast<ServiceModel?>().firstWhere(...)` returning `null` as orElse

---

## Backend Field Mapping Reference

| Frontend (new) | Backend DTO | Type |
|---|---|---|
| `basePrice` | `basePrice` | `double` |
| `paymentType` | `paymentType` | `'PAY_UPFRONT' \| 'PAY_AFTER' \| 'SUBSCRIPTION'` |
| `isAvailable` | `isAvailable` | `bool` |
| `requiresSubscription` | `requiresSubscription` | `bool` |
| `priceYoungPet` | `priceYoungPet` | `double?` |
| `priceOldPet` | `priceOldPet` | `double?` |
| `categoryId` | `categoryId` | `String?` |
| `serviceCode` | `serviceCode` | `String` |
| `currency` | `currency` | `String` (default `'RWF'`) |

---

## Verification

- `flutter analyze --no-pub` → **0 errors** (16 info/warning items only)
- All user-facing service field displays updated to use correct backend values
