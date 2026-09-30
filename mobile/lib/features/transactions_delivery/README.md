# Transactions & Delivery

Component 4 uses the ASP.NET Core API for material transactions, product orders,
delivery selection, and status history.

Run configuration:

```text
flutter run --dart-define=ECOLOOP_API_URL=http://10.0.2.2:5252/api \
  --dart-define=ECOLOOP_BUSINESS_ID=<current-business-guid>
```

`ECOLOOP_BUSINESS_ID` is a temporary integration point until the team's JWT
authentication feature supplies the current business from authenticated claims.

The location screen uses `flutter_map` with free OpenStreetMap tiles, so no map
API key or billing account is needed. Tiles only need an internet connection.

## Component 4 additions — 24 September 2026

- Buyer can edit proposed quantity/unit/price while a material request is Pending.
  Seller acceptance confirms those proposed terms. Updates recalculate the total
  and append a history entry; accepted/terminal requests cannot be rewritten.
- Pickup addresses belong to the seller; seller-delivery destinations belong to
  the buyer. Location edits are allowed before Ready, with history and timestamps.
  A record cannot be marked Ready without an address. I HAVE pickup initially
  copies the listing address. Product/other pickup addresses can be set by the
  seller from the detail screen before Ready.
- Home > Track Order > bookmark icon opens saved-location CRUD. Checkout can
  select a saved address. Deliveries retain text snapshots, so deleting or editing
  the address book does not change historical orders.
- Histories now have Previous/Next page controls. Details display material terms,
  retry failed loads, and provide view-location/route and permitted editing actions.
- Requests time out and surface readable network/server/conflict errors. Owned
  HTTP clients are disposed; asynchronous state changes check mounted state.
- Optimistic concurrency checks cover transaction/order status and UpdatedAt,
  and inventory Quantity/IsAvailable. Cancellation starts a serializable database
  transaction before reading order/stock. A failed concurrent save rolls back
  history and stock together; clients receive 409 and must reload, not auto-retry.

### Database setup

`AddSavedDeliveryLocations` creates the saved-address table. It was applied to the
local development database during implementation. On other developer databases:

```powershell
cd backend
dotnet ef database update
```

The design-time DbContext factory avoids executing API startup/demo seeding during
migration tooling. No existing order/listing records are rewritten by this migration.

### Maps and route configuration

The map is OpenStreetMap (via `flutter_map`) and needs no key.

For driving distance, duration and a route polyline, the backend geocodes typed
addresses with OpenStreetMap Nominatim and routes with OSRM. Both are free and need
no key; coordinates (`lat, lng`) skip the geocoding step. The location screen's
“Driving distance from me” action uses current GPS as origin and the
entered/selected location as destination. This is a driving estimate, not live
delivery tracking.

The public servers are rate-limited and meant for light use (Nominatim allows about
one request per second). To point at self-hosted instances, set
`Routing__NominatimBaseUrl` / `Routing__OsrmBaseUrl` on the backend.

Provider docs: https://project-osrm.org/docs/v5.24.0/api/ and
https://nominatim.org/release-docs/latest/api/Search/

### New endpoints

| Endpoint | Purpose |
|---|---|
| `PUT /api/material-transactions/{id}` | Edit Pending request terms |
| `PUT /api/material-transactions/{id}/delivery` | Edit permitted location |
| `PUT /api/product-orders/{id}/delivery` | Edit permitted location |
| `GET/POST /api/delivery-locations` | List/create saved locations |
| `GET/PUT/DELETE /api/delivery-locations/{id}` | Saved-location CRUD |
| `POST /api/delivery-routes` | Driving estimate and encoded route geometry |

Editing requests send the exact `expectedUpdatedAt` string returned by the API
(null before the first transaction/order update). A stale version is rejected.

### Team handoffs still required

- Group JWT/authentication remains absent. Business/actor IDs still use the existing
  demo contract; party checks are NOT authenticated authorization. Replace these
  with the shared business claim before exposing the API beyond local development.
- Material and product catalogs are now connected to transaction/checkout screens.
  The group must still agree authenticated I NEED initiation/offer policy.
- Product publishing and inventory management use the existing backend APIs;
  seller product-management screens remain Component 3 work.
- Material quantity reservation/fulfilment policy requires Component 2 agreement;
  this implementation does not change the listing's text quantity or close listings.
- React foundation/admin screens and identity architecture remain group dependencies.
- Maps tiles, GPS and real Google responses still require configured device testing.

### Verification

Backend tests cover allowed/stale/forbidden edits, saved-location ownership and
snapshot preservation, stale cancellation rollback, competing material decisions,
full product endings and I NEED completion. Service tests use SQLite; route-provider
tests use an HTTP stub, not a paid external request. Flutter tests cover API paging,
edit version tokens, error/timeout handling and location entry without a map key.
An HTTP smoke check against local PostgreSQL verified saved-location CRUD, 409
stale updates, 404 for another business ID, and unconfigured-route 503. Its temporary
saved-location row was deleted afterward. Concurrent PostgreSQL races and real
device/Google Maps behavior have not been runtime-verified.

Final checks on 24 September 2026: backend tests **21 passed**, Flutter tests
**8 passed**, and focused Flutter analysis of Component 4 and its tests reported
**no issues**. Whole-app analysis earlier in this implementation also identified
existing deprecation notices in the shared theme and teammate marketplace/home code;
those are outside this change's scope.


## Project integration - 27 September 2026

- Home quick actions open material posting, products, and transaction history.
- Materials and Home load published records with real business IDs, units,
  descriptions, and delivery availability. Loading failures provide retry.
- Material posting sends multipart data (one optional image) to the API.
  My Listings reads the configured business's Active/Completed records and persists
  edits, completion and deletion. Returning to the marketplace refreshes the list.
- Products replaces the placeholder tab: live catalog, search, stock-limited quantity
  selection and Buy Now open Component 4 checkout. Each checkout orders one selected
  product; this UI does not implement a multi-product cart. Returning refreshes stock.
- Activity opens all four buyer/seller histories and saved locations. Products has
  a My orders shortcut. Own products/listings cannot start a self-purchase in the UI.
- `core/config/app_config.dart` is the shared API/business configuration.
  `Component4Config` is a compatibility alias. This remains a development identity,
  not a login session: there is no auth implementation in this checkout.

### Run and test the connected flows

1. Start the backend from `backend` using `dotnet run --launch-profile http`.
2. Start Flutter from `mobile` with `flutter run`. Android emulator defaults to
   `http://10.0.2.2:5252/api` and business `22222222-2222-2222-2222-222222222222`.
   For a physical phone use `--dart-define=ECOLOOP_API_URL=http://<PC-LAN-IP>:5252/api`
   and bind the development backend to that reachable interface.
3. Use a second emulator/build with
   `--dart-define=ECOLOOP_BUSINESS_ID=11111111-1111-1111-1111-111111111111`
   for the other business. Both development businesses already exist in startup seeding.
4. Post a material under one business; open it from the other business and submit
   a transaction. Use Activity on each side for status changes and delivery locations.
5. Product records need stock created via the existing product and inventory APIs.
   No fake products or orders are inserted by the mobile catalog. Buy Now opens
   checkout; verify the order under Activity and seller actions under Received Orders.

Verification: 24 backend tests and 15 Flutter tests passed. Added coverage includes
catalog-to-transaction identity, catalog stock after checkout/cancellation, persisted
My Listings statuses, multipart posting, product quantity navigation and blocked
self/out-of-stock purchases. Live read-only HTTP checks against local PostgreSQL
succeeded for materials, products, completed listings, buyer histories and saved
locations. At verification the database had one active material and no products.
Full two-device interaction and configured Google Maps remain unverified. No database
migration was needed for these integration changes.
