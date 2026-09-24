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

Google Maps keys are intentionally not stored in source control:

- Android: set the `GOOGLE_MAPS_API_KEY` environment variable before building.
- iOS: define `GOOGLE_MAPS_API_KEY` in the local Xcode build configuration.

The location form remains usable as an address/coordinate field, but Google map
tiles require a valid key with the Maps SDK enabled for the target platform.

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

Without a native map key, the location screen supports text/GPS without constructing
the native map. After configuring the platform key, build with:

```text
--dart-define=ECOLOOP_MAPS_ENABLED=true
```

For driving distance, duration and a route polyline, configure the backend environment
variable `GoogleMaps__RoutesApiKey` with a server key enabled for Google Routes API.
The backend calls Google; this server key is never sent to Flutter. The location
screen's “Driving distance from me” action explicitly uses current GPS as origin
and the entered/selected location as destination. This is a driving estimate, not
live delivery tracking. Missing configuration returns 503 with a useful message.

Provider contract: https://developers.google.com/maps/documentation/routes/compute_route_directions

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
- Component 2 must provide real listing GUIDs/business/unit/availability. The
  confirmation page now maps I NEED owner as buyer and current business as seller,
  and rejects placeholder IDs before sending a request. The group must agree the
  authenticated I NEED initiation/offer policy. No marketplace was rebuilt here.
- Component 3 must navigate to `ProductCheckoutPage(items: ...)` with real products.
  Product stock coordination benefits from the shared Inventory concurrency tokens;
  independent product/inventory validation and shopping screens remain team work.
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
