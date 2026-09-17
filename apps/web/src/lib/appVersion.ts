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

export const APK_VERSION = 'v1.5.0';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.5.0-arm64.apk',
    size: '21.4 MB',
    sha256:
      '097fca0447053f39e2d52826812cc4c63e3566fc1805102a06f65fdaea36803a',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.5.0-arm32.apk',
    size: '19.2 MB',
    sha256:
      '3d8a35cceb631b15ca812a6f9b08270d4c81fc1172bd42375d1f0b289ed76931',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.5.0-x64.apk',
    size: '22.9 MB',
    sha256:
      '59e10f257d87e8facfef48e5253f1b79866af30640f6b3780bd24a18fd296cc9',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
