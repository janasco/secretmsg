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

export const APK_VERSION = 'v1.4.4';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.4.4-arm64.apk',
    size: '20.7 MB',
    sha256:
      '99e98fd1e7c4bde8572cd524ba5ae5c6021d39a671e9de80f8964b7d2b2bae51',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.4.4-arm32.apk',
    size: '18.4 MB',
    sha256:
      'e8edd0120aa3863e129daac67d93ad222618407e0bd01a412dd6e820517ce572',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.4.4-x64.apk',
    size: '22.1 MB',
    sha256:
      '02870a2a0947592206ef2b6de428e3988fac651b9af58369b73af0caa0a9d15e',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
