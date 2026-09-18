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

export const APK_VERSION = 'v1.6.2';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.6.2-arm64.apk',
    size: '21.5 MB',
    sha256:
      '2ea34ab5eb76bb5e0eb3fc1c243a543829152598694fcb413cc0404dfd67044a2',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.6.2-arm32.apk',
    size: '19.3 MB',
    sha256:
      '62e010cab61a35c8fc7ef2a95cc6448064253018a006752a49ffb15cac3a80c8',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.6.2-x64.apk',
    size: '23.0 MB',
    sha256:
      '6d84a1eb685b3264088db11eed896337d5e1543a2a3d104ae921c8cbfb927fc',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
