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

export const APK_VERSION = 'v1.4.7';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.4.7-arm64.apk',
    size: '21.2 MB',
    sha256:
      '9d9dea14aebd96769c34841c65b7cf5fe40610b9a6aa4e53267ec4832b5065f0',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.4.7-arm32.apk',
    size: '19.0 MB',
    sha256:
      '775f0373e7919be0b84f0f307b27f00caab6111c9101e2d3a7810f92f378ad5f',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.4.7-x64.apk',
    size: '22.7 MB',
    sha256:
      '966abbfe2fe7a7a7845df8ffa84885e11923725716322e40d8034a9e8f398e5c',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
