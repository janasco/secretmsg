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

export const APK_VERSION = 'v1.6.3';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.6.3-arm64.apk',
    size: '21.5 MB',
    sha256:
      '76dd0285980723db036a14178d830592e771b96c39a9dd828d8cde4e272d2c45',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.6.3-arm32.apk',
    size: '19.3 MB',
    sha256:
      'c1e2576740373330a5cd154a8b2afb13fa7bb93c23d8649afea0832e93a3bcf3',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.6.3-x64.apk',
    size: '23.0 MB',
    sha256:
      'b8f05898e7bafd34de9a8eac497be2ce38d73d5341cd01fee8a5939f60621fa9',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
