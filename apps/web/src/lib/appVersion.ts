/**
 * Single source of truth for the published Android build.
 *
 * When shipping a new APK: build it with
 * `flutter build apk --release --split-per-abi`, copy the per-ABI outputs
 * into `apps/web/public/downloads/`, then bump the values below.
 * DownloadPage and LandingPage both read from here, so the version
 * can never drift between pages again.
 *
 * Note: Workers static assets cap files at 25 MiB, so we ship per-ABI
 * APKs (arm64 for modern phones) instead of one universal APK.
 */

export interface ApkVariant {
  /** Human label shown on the download page. */
  label: string;
  file: string;
  size: string;
  sha256: string;
}

export const APK_VERSION = 'v1.6.1';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.6.1-arm64.apk',
    size: '21.5 MB',
    sha256:
      '9014289118ee55f8ef586c8bae00886fa9089bed62dd659de5fe9386f177a9a2',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.6.1-arm32.apk',
    size: '19.3 MB',
    sha256:
      'b0dc0cb5e9200191dffed416d3fb36d43856f91a53744379cac5332086f3f60aced',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.6.1-x64.apk',
    size: '23.0 MB',
    sha256:
      'bdefa85a9a7170ca2f47573a88d36d25d826945428ab739b4b923eab54481b6e',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
