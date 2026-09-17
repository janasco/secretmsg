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

export const APK_VERSION = 'v1.4.1';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.4.1-arm64.apk',
    size: '20.5 MB',
    sha256:
      'f6fbad86dee733df4c5442cb1e245ac716051c33c3ad230c7a408200671cf751',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.4.1-arm32.apk',
    size: '18.2 MB',
    sha256:
      'f42440d0a53c1167eaee7d4653b9e340b82bb10f740d7356fc6ed69bae94903d',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.4.1-x64.apk',
    size: '22.0 MB',
    sha256:
      'eb7ff81c4e06f16ea9ed349f3180a0cb6a143b553087357737e2df7b5909b467',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
