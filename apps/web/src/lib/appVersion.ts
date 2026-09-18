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

export const APK_VERSION = 'v1.6.6';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.6.6-arm64.apk',
    size: '21.5 MB',
    sha256:
      'fe96bc66a3d47e9c9ec801633dbfb4f7dd5ef0faf20d76ff6694298c5330deaa',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.6.6-arm32.apk',
    size: '19.3 MB',
    sha256:
      '1ff3f9d0aefd3fd77ef502ece6ecc480432d63226d3224bb5688ea11abb0db8b',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.6.6-x64.apk',
    size: '23.0 MB',
    sha256:
      'dc64f2c8e4594a2e0345a1b9905cffa5eee6d99dfa033187a816c051e5060458',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
