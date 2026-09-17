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

export const APK_VERSION = 'v1.4.6';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.4.6-arm64.apk',
    size: '21.3 MB',
    sha256:
      'da7a2eb698dc19c7a4f14be7dbed218ddac02d66555ef7a64625ce4e85d6c3d7',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.4.6-arm32.apk',
    size: '19.0 MB',
    sha256:
      '43cd44627136db6217fc2ba833dd7d464927f407ef8dcc732ef946799bd2899e',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.4.6-x64.apk',
    size: '22.7 MB',
    sha256:
      '47953eaab102edbc85c027213482cfd09349f49bdeedc228fc84f0ae62cddd55',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
