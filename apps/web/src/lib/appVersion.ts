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

export const APK_VERSION = 'v1.6.8';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.6.8-arm64.apk',
    size: '21.6 MB',
    sha256:
      'ec33991385cc51cf22c17d8976cbbe7f453c7adf2b8172176f30258346d9373e',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.6.8-arm32.apk',
    size: '19.3 MB',
    sha256:
      '7c7342dcede5329c7818f2ded2e068d851f85f0d1b3badd2d31d53174d83aa3c',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.6.8-x64.apk',
    size: '23.0 MB',
    sha256:
      '76b495df0938b7a3fc8652739b2e2a69e499fc65d750ce496c502d5a379ebe8d',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
