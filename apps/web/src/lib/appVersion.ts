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

export const APK_VERSION = 'v1.4.0';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.4.0-arm64.apk',
    size: '20.5 MB',
    sha256:
      '2ad4df8211df7e75b70bf3597585571e1d0eeeb917e2f4e0796afdf419d51cbe',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.4.0-arm32.apk',
    size: '18.2 MB',
    sha256:
      '6f1e04f48f86fa56a81d68a9f22c49ecc0345415e7ff33d8786d258f3f2af65f',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.4.0-x64.apk',
    size: '22.0 MB',
    sha256:
      '09981cd8e5540c887ce9f72136e399b5c17d189077b9683dc6c3c26af03debaf',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
