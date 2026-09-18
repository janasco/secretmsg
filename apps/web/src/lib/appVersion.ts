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

export const APK_VERSION = 'v1.6.5';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.6.5-arm64.apk',
    size: '21.5 MB',
    sha256:
      '0e3d692d9e6ffebb35f8f7e98119142c458eb5b74908b47363d004391e99a279',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.6.5-arm32.apk',
    size: '19.3 MB',
    sha256:
      '0ee8d467aef1fdd55c1a83cbb2868d25888456c34aae06701fc1d82ec26460a3',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.6.5-x64.apk',
    size: '23.0 MB',
    sha256:
      '6317ab1849cee332d845515b6bbf04d378d729b2ada43fd5905d1a4148f01e80',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
