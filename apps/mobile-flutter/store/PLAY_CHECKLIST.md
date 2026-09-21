# Google Play Release Checklist — SecretMsg Android

## Status legend: [ ] todo · [x] done

### 1. Signing (BLOCKER)
- [ ] Generate upload keystore: `keytool -genkeypair -v -keystore secretmsg-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias secretmsg-upload`
- [ ] Store passwords in password manager (loss = upload-key reset via Google support)
- [ ] Create `android/key.properties` (gitignored): storeFile/storePassword/keyAlias/keyPassword
- [ ] Rebuild AAB + verify `apksigner verify --print-certs`
- [ ] Enroll in Play App Signing on first upload

### 2. Build
- [x] `flutter build appbundle --release` works (debug-signed until §1)
- [x] minSdk 24, targetSdk 36, versioned per-ABI codes
- [ ] Rebuild AAB after §1, keep versionCode increasing (`+N` every release)

### 3. Store assets (in this folder)
- [x] `feature-graphic.png` (1024x500)
- [x] High-res icon (512x512, `apps/web/public/icons/play-store-512.png`)
- [ ] Phone screenshots x4+ (1080x1920+): inbox, Drop, dice, sticker studio
- [ ] 7" + 10" tablet screenshots (or opt out of tablet listing)

### 4. Listing content
- [ ] Short description (80 chars), full description, category (Social), tags
- [ ] Privacy policy URL: https://secretmsg.net/p/privacy
- [ ] Contact email + website: https://secretmsg.net

### 5. Policy questionnaires
- [ ] Data safety form: location NO, personal info (handle/PIN hash — account data), messages (user content), diagnostics (crash only if added). Data encrypted in transit (HTTPS), deletable (in-app purge)
- [ ] Content rating (Everyone? Anonymous messaging with user-generated content — answer honestly: unrestricted chat pushes Teen+)
- [ ] Target audience + Families policy check
- [ ] Government apps / health / financial: N/A

### 6. Release mechanics
- [ ] Closed testing track first (20+ testers x 14 days for new accounts)
- [ ] Pre-launch report review, fix crashes
- [ ] Staged rollout 20% -> 100%
- [ ] `android_latest` feed already drives in-app update prompts

### 7. Secrets that must exist before billing works
- [ ] GOOGLE_PLAY_SA_EMAIL / GOOGLE_PLAY_SA_KEY (Play Console → API access → service account)
- [ ] GOOGLE_PLAY_PACKAGE_NAME = net.secretmsg.android_app (already set)
- [ ] Test with license-test accounts before production
