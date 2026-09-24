# Standards: native-app

Loaded after `core.md`. `web.md` does not apply. Dark mode with system preference detection lives in `core.md`.

## Build and release
- [ ] **Expo SDK + EAS Build / Submit / Update:** builds and store submissions run from EAS; OTA updates have a written rollback plan. Evidence: EAS build URL and the rollback steps. (verified: 2026-09)
- [ ] **App-size budget:** a size ceiling per platform, checked on every release build. Evidence: build size vs budget.
- [ ] **Device matrix:** tested on the oldest and newest supported OS versions and one small screen. Evidence: matrix table with results.
- [ ] **Crash reporting:** crashes reach a dashboard with symbolicated stack traces. Evidence: one test crash visible. (verified: 2026-09)

## Store review readiness
- [ ] **iOS privacy manifest + Android data-safety form:** both filled and consistent with what the app collects. Evidence: `PrivacyInfo.xcprivacy` path and the Play Console form. (verified: 2026-09)
- [ ] **In-app account deletion:** reachable from settings when the app has accounts. Evidence: screen path.
- [ ] **Demo account for reviewers:** credentials in the review notes. Evidence: the note text.

## Platform features
- [ ] **Push via expo-notifications:** permission asked in context, not at launch; token rotation handled server-side. Evidence: the permission trigger and the token refresh handler. (verified: 2026-09)
- [ ] **Deep links:** universal links / app links verified (AASA and `assetlinks.json` served); every callback parameter is validated. Evidence: `curl` of both files and a test with a malformed parameter.
- [ ] **Offline:** read-only cache or a write queue with a stated conflict policy. Evidence: airplane-mode test result.
- [ ] **Secure storage:** tokens in Keychain/Keystore; no secrets in the bundle; TLS only. Evidence: storage call site and a `strings` scan of the bundle. Also cleartext traffic disabled (`android:usesCleartextTraffic="false"`, no ATS exceptions in `Info.plist`). Evidence: grep of both manifests → 0 exceptions. Source: OWASP MASVS-NETWORK-1 https://mas.owasp.org/MASVS/controls/MASVS-NETWORK-1/ (unverified).

## Interaction
- [ ] **Interactive Feedback:** Subtle visual feedback on mobile interactions (Aesthetic Tech)

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
