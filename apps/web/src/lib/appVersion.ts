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

export const APK_VERSION = 'v1.4.2';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.4.2-arm64.apk',
    size: '20.6 MB',
    sha256:
      'cb9a1b81d5d2b4c6f9a50462bae730fdd5f21d84acd99f11b970989bea045e12',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.4.2-arm32.apk',
    size: '18.2 MB',
    sha256:
      '14da114a68d947bbcc83ea83fef9cd068a28761d4e052335e703827c86aa2200',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.4.2-x64.apk',
    size: '22.0 MB',
    sha256:
      'cad9e43895622a8f9fcc59e67920b5cb4f73144fc1091d78023f324a23f6bb60',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
