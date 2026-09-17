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

export const APK_VERSION = 'v1.4.3';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.4.3-arm64.apk',
    size: '20.7 MB',
    sha256:
      'aee344e14eda906032e309decd5beecb9e5f99011ecf8c8f226108dc27e6c0ad',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.4.3-arm32.apk',
    size: '18.4 MB',
    sha256:
      '5865188a6f18a64233cb458f7ccd59768b63370ab4c2107b00c90d9f3f60aced',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.4.3-x64.apk',
    size: '22.1 MB',
    sha256:
      'f246d283fdbac08b99d4338034e1f9226bf6f2a20894a9227a322069bf089ddd',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
