/**
 * Single source of truth for the published Android build.
 *
 * When shipping a new APK: build it with `scripts/build_sideload.sh`, copy the
 * per-ABI outputs into `apps/web/public/downloads/`, then bump the values below.
 * Use that script and not a bare `flutter build apk --release --split-per-abi`:
 * the script selects the dedicated sideload signing key, and a build without it
 * falls back to the debug key, whose signature no Play-installed copy of the app
 * can ever be upgraded onto. DownloadPage and LandingPage both read from here, so
 * the version can never drift between pages again.
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

export const APK_VERSION = 'v1.6.10';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.6.10-arm64.apk',
    size: '13.1 MB',
    sha256:
      '87f535e4bb059070888d2387c3bec036a565ea92e3da07355db37733ac0ce9f0',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.6.10-arm32.apk',
    size: '12.7 MB',
    sha256:
      '9c7e95dcf71dd17d127473eed422889d39a2a09624004824a380c14d3e1f13e8',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.6.10-x64.apk',
    size: '13.3 MB',
    sha256:
      'dcecd06fd1e670f1e5fdd076c93f22fa64bccf74af26bdfb404c9682306b7946',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
