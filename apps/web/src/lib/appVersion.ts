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

export const APK_VERSION = 'v1.7.1';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.7.1-arm64.apk',
    size: '13.1 MB',
    sha256:
      'af873673108b6d163e82ef9170936503995d06816ae68aa6c84accab7a3a3826',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.7.1-arm32.apk',
    size: '12.7 MB',
    sha256:
      '05f9682ca55d087efd3a812756947074223eee5019ca9f24eca58995ef76f016',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.7.1-x64.apk',
    size: '13.3 MB',
    sha256:
      'cdf130d2e4889a34145924191d18c2587ec9f62f9a7b58e6ac30c0580222e333',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
