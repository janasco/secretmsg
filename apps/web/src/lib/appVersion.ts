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

export const APK_VERSION = 'v1.3.0';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.3.0-arm64.apk',
    size: '19.1 MB',
    sha256:
      '654fd7817e7a60001b97ebce71f3cc1611b9615a3dc4ce8bbba2b88d53eb5655',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.3.0-arm32.apk',
    size: '16.7 MB',
    sha256:
      '722381e2beb7698e6fe90fa6a0ec2e983e2c20aa8c99298911bd6d883f2490d9',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.3.0-x64.apk',
    size: '20.5 MB',
    sha256:
      '4149aa390e55f4e10c8515ae65e7f40a974869737cb2cfc7ea454954425e91b3',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
