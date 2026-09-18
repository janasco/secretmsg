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

export const APK_VERSION = 'v1.6.7';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.6.7-arm64.apk',
    size: '21.6 MB',
    sha256:
      '344d85f04eb1b22cdc078bda67cddb7e0e5df47fef7eba2b3c4fe4407de4b1eb',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.6.7-arm32.apk',
    size: '19.3 MB',
    sha256:
      '16e7d9ae5355428f3cdcc0e26dbc4f4cb68c50c34888aefd46c037049de70ed8',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.6.7-x64.apk',
    size: '23.0 MB',
    sha256:
      '39b01668310e2c90727e85cb48e0e9cb01bf44bfbc53c63ae42a18688d992814',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
