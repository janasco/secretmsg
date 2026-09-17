# ARCHIVED — mobile-android (Capacitor wrapper)

**Do not build on this.** The flagship Android app is
[`../mobile-flutter`](../mobile-flutter) (package
`net.secretmsg.android_app`).

This directory is the legacy Capacitor shell (package `net.secretmsg.app`)
that loads the static `site/public` site in a WebView. It is kept
temporarily so its code (App Links config, splash/clipboard/haptics/push
wiring) can be referenced while the Flutter app matures, then deleted.

- Not built, not deployed, not published to any store.
- `npm run android:*` scripts still resolve here but are unsupported.
