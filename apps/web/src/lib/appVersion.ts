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

export const APK_VERSION = 'v1.6.9';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.6.9-arm64.apk',
    size: '21.6 MB',
    sha256:
      '701c75a27231ae8def37e19c5170263bd3ef8e75ccf0656500a21ddf84ff1058',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.6.9-arm32.apk',
    size: '19.3 MB',
    sha256:
      'df865d6e7fb737c6b7af33f10a3af5cf4fbe70fb9b8a9006de202c1a08e2c7f7',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.6.9-x64.apk',
    size: '23.0 MB',
    sha256:
      '0e46915bcebce6eb21f2fd6bd2653e53bc368108464768b178999b7ba6656f9d',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
