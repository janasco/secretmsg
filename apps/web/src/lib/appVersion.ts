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

export const APK_VERSION = 'v1.4.8';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.4.8-arm64.apk',
    size: '21.2 MB',
    sha256:
      'e590475d6bcfd521fc7c6118e4bc40d553c70a6113061fa396af9b5c934df9b5',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.4.8-arm32.apk',
    size: '19.0 MB',
    sha256:
      'fe10e0d8edc786f3cf12d85afaa9c70323078ee3ec081a2b1f35e57a4e46bd0c',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.4.8-x64.apk',
    size: '22.7 MB',
    sha256:
      'ad2dabb0b68c6aafceed6fc31390a64b5bf231012a056bb3aa0d4a16a5ca79ee',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
