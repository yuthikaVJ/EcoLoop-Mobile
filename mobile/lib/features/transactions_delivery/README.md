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
