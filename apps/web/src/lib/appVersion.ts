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

export const APK_VERSION = 'v1.6.4';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.6.4-arm64.apk',
    size: '21.5 MB',
    sha256:
      '1f0472ab84d99f61a85812ce8062f13e91fdd1971763643e8ec476bbe0d79ef0',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.6.4-arm32.apk',
    size: '19.3 MB',
    sha256:
      'e5f668e1f05ddaeb2a33dc014041d52ed1365ac2583d4f05752b468b97186d9c',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.6.4-x64.apk',
    size: '23.0 MB',
    sha256:
      '704bf9f549a89db63a1b38eb49d674b20630de319706b74b6a0b4b1832a17e35',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
