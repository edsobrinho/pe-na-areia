---
kind: external_dependency
name: Google Maps API key for Flutter frontend maps
slug: google-maps
category: external_dependency
category_hints:
    - vendor_identity
    - client_constraint
scope:
    - '**'
---

### Google Maps
- Role: map rendering in the Flutter frontend (location selection screen with draggable pin).
- Integration point: API key configured in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`.
- Client constraint: requires a Google Maps API key; the README notes the free tier covers development/low-volume usage.
- Verify exact key injection locations against the current Flutter Google Maps plugin docs.