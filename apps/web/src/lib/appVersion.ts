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

export const APK_VERSION = 'v1.7.0';

export const APK_VARIANTS: ApkVariant[] = [
  {
    label: '64-bit (recommended, most phones)',
    file: 'secretmsg-android-v1.7.0-arm64.apk',
    size: '13.1 MB',
    sha256:
      '1bdc0f0fe9f6c40c07b4f20a1f3d07ee251b143e6d015dd598a4d068d94f0fa8',
  },
  {
    label: '32-bit (older phones)',
    file: 'secretmsg-android-v1.7.0-arm32.apk',
    size: '12.7 MB',
    sha256:
      'a868608decdaff1b0f790f6ee24b30b730fa95f52b4718746f1d84a34d25d8f8',
  },
  {
    label: 'x86 64-bit (emulators, Chromebooks)',
    file: 'secretmsg-android-v1.7.0-x64.apk',
    size: '13.3 MB',
    sha256:
      '07848056a77ec359cdc19dfb4be1ba25c1a6a07782cb88dd332d110a9b16201b',
  },
];

/** Primary download (first variant). Kept for LandingPage + compat. */
export const APK_PRIMARY = APK_VARIANTS[0];
export const APK_FILE = APK_PRIMARY.file;
export const APK_SIZE = APK_PRIMARY.size;
export const APK_SHA256 = APK_PRIMARY.sha256;
