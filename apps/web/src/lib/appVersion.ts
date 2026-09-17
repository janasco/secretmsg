/**
 * Single source of truth for the published Android build.
 *
 * When shipping a new APK: build it, copy it into
 * `apps/web/public/downloads/`, then bump the four values below.
 * DownloadPage and LandingPage both read from here, so the version
 * can never drift between pages again.
 */

export const APK_VERSION = 'v1.3.0';
export const APK_FILE = 'secretmsg-android-v1.3.0.apk';
export const APK_SIZE = '52.7 MB';
export const APK_SHA256 =
  'ab942c97fed9bbc171194e6e658aec7ed5011d3b06e0a913a62247d435be14d7';
