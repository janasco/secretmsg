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

export const APK_VERSION = 'v1.6.0';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.6.0-arm64.apk',
    size: '21.5 MB',
    sha256:
      'f15da19d6fafde8c6b7fccda542ecde9df97a6cb3e69815772ed1bf0d7f36aa5',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.6.0-arm32.apk',
    size: '19.3 MB',
    sha256:
      'cd89e82751ebcb248bc8167de5bb2884e32032e3f2b2e762ba9d3c615da72713',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.6.0-x64.apk',
    size: '23.0 MB',
    sha256:
      '6d0db62fbf309d309e03a2862537fa0eeac26f5f3e59527c2092dac8f71b07a9',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
