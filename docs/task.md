# Rwanda Pet Lovers - Integration Task Tracker

## 🐛 IMMEDIATE BUG FIX (Pet Listing Visibility)
- [x] Fix `PetListingModel.fromJson` — wrong field mapping (`listerId` → `ownerId`, enum `FOR_SALE`/`FOR_DONATION` → `SELL`/`DONATE`, status `ACTIVE` → `PUBLISHED`)
- [x] Fix `home_page.dart` listing filter — `p.listingType == 'FOR_SALE'` uses wrong value vs backend `SELL`/`DONATE`
- [x] Replace `allPetsProvider` with `forSaleListingsProvider` / `forAdoptionListingsProvider` in homepage sections
- [x] Fix `PetsPage` — add tabs for "For Sale" and "For Adoption" sections using real listings API

## 🎨 UI REFINEMENTS (Pet Listings)
- [x] Remove `.take(5)` limit from "Being Sold" and "For Adoption" sections on homepage
- [x] Remove "See all" links from homepage listing sections
- [x] Left-align section headers and remove emoji prefixes
- [x] Remove "Add to cart" / "Buy Now" and add "Adopt now" for adoption listings in `PetDetailsPage`
- [x] Hide cart icon in `PetDetailsPage` for adoption listings
- [x] Use primary color `0x21314C` for "Adopt now" buttons and adoption badges (removed purple/pink)

---

## MODULE 1: Pets (Core)
- [ ] Fix pet form — all fields should be editable; add missing fields: `locationId`, `nationality`, `birthDate`
- [ ] Align `PetFormSheet` submit payload to match `CreatePetDto` and `UpdatePetDto` fully
- [ ] Show real pet images from backend (no placeholder gaps)
- [ ] Remove mock data from pet cards, detail pages
- [ ] Fix `isForSale`/`isForDonation` getters in `PetModel` to use correct backend enum values (`SELLING_PENDING`, `DONATION_PENDING`)

## MODULE 2: Pet Listings (Sale & Adoption)
- [x] Wire `forSaleListingsProvider` in dashboard/home for "Being Sold" section
- [x] Wire `forAdoptionListingsProvider` in dashboard/home for "Being Donated" section
- [x] Build "For Sale" tab in `PetsPage` using `PetListingModel` data
- [x] Build "For Adoption" tab in `PetsPage` using `PetListingModel` data
- [ ] Implement purchase flow (MVP: accept payment without payment API)
- [ ] Implement adopt flow (request submission + confirmation)
- [x] Show listing-specific detail view (price, currency, listing description, owner)

## MODULE 3: Products & Shop
- [ ] Remove mock data from products provider / home section
- [ ] Ensure `ShopModel` pulls real images and handle missing images with branded placeholder
- [ ] Fix product list / shop list — use real API data

## MODULE 4: Services & Appointments  
- [ ] Remove mock data from services page
- [ ] Fix appointment creation to use real `locationId` from locations endpoint
- [ ] Ensure appointment status displays correctly (PENDING, CONFIRMED, COMPLETED, CANCELLED)

## MODULE 5: Orders
- [ ] Remove mock data from orders page
- [ ] Ensure order status messages are user-friendly
- [ ] Link orders to real product purchase flow

## MODULE 6: Vaccinations
- [x] Vaccination form already integrated — verify record fetch works after add
- [ ] Show vaccination history on pet detail page with real data

---

## CROSS-CUTTING CONCERNS
- [ ] Add unified toast system (animated, styled) for all success/error/info messages
- [ ] Replace all developer-facing error messages with user-friendly variants
- [ ] Add image placeholder widget for missing/loading backend images
- [ ] Separate all API calls from UI — services/providers must be clean layers
- [ ] Add `@Public` vs `@Protected` doc comments to all service methods
- [ ] Ensure `DioClient` auth interceptor sends token on all protected endpoints
- [ ] Consistent use of Riverpod providers — no direct service calls in widgets
