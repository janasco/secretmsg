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

export const APK_VERSION = 'v1.4.5';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.4.5-arm64.apk',
    size: '20.7 MB',
    sha256:
      'b49836230950e3a053234fd1b53287535ec44b84bbe95599504d29d7905f0fb2',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.4.5-arm32.apk',
    size: '18.4 MB',
    sha256:
      'e695713fec3b48243100eb179cd820960e859a3c66d34f1cf755dc286f23b19a',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.4.5-x64.apk',
    size: '22.1 MB',
    sha256:
      '390a4d84e11e58306316c1ff11aa0e15792f1835967e974ee762545c495b7e4d',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
