/// Which distribution track a build was produced for.
///
/// The app is distributed on two tracks that never merge:
///
///   1. Google Play — an AAB, re-signed by Google Play App Signing with a
///      Google-managed key.
///   2. Sideloaded — per-ABI APKs from secretmsg.net/download, signed with a
///      dedicated sideload key we control.
///
/// Android identifies an app by package name **and** signing certificate, so
/// although both claim `net.secretmsg.android_app`, neither install can be
/// upgraded by the other: Android refuses with
/// `INSTALL_FAILED_UPDATE_INCOMPATIBLE` and the only remedy is an uninstall
/// that deletes the app's local state. The two tracks therefore need
/// different update destinations, and the binary has to know which one it is
/// before it can pick one.
///
/// The value is baked in at build time from the *same* flag that selects the
/// signing key. `android/app/build.gradle` appends
/// `--dart-define=SECRETMSG_DISTRIBUTION_TRACK=<track>` to `dart-defines`
/// whenever `-PsideloadSigning=true` is set, and `scripts/build_sideload.sh`
/// is the only thing that sets that flag. One switch drives the key and the
/// track, so they cannot drift apart.
library;

/// Name of the compile-time constant. Must match the `--dart-define` key
/// written by `android/app/build.gradle`.
const String kDistributionTrackDefine = 'SECRETMSG_DISTRIBUTION_TRACK';

const String _rawTrack = String.fromEnvironment(kDistributionTrackDefine);

/// The two mutually exclusive distribution tracks.
enum DistributionTrack {
  /// Installed from Google Play. Updates arrive as a new Play release.
  play('play'),

  /// Installed from a sideloaded APK on secretmsg.net/download.
  sideload('sideload');

  const DistributionTrack(this.wireName);

  /// Stable identifier used on the build-time define and in the feed keys.
  final String wireName;
}

/// The track this binary was built for.
///
/// **The default is [DistributionTrack.play], and that is the safe default.**
/// Two independent arguments, both load-bearing:
///
///  * It is the *same* default as the signing switch. `-PsideloadSigning` is
///    an opt-in: absent it, `build.gradle` signs the release with the upload
///    key and the artifact is the Play upload path, byte for byte as it was
///    before the sideload track existed. Defaulting the track to `play` keeps
///    the key and the track describing the same artifact. Defaulting to
///    `sideload` would assert "this is a publicly downloadable APK" about a
///    build that is in fact being handed to Google.
///
///  * The failure modes are not symmetric. A Play build that mislabels itself
///    as a sideload build asks the feed for the sideload download page and
///    sends a Play user to an APK their device cannot install over the Play
///    copy — a silent misconfiguration that only shows up as a failed install
///    on someone else's phone. A Play build that correctly asks for the Play
///    field before one exists gets no update prompt at all: degraded,
///    harmless, and fixed by editing one line of the feed.
///
/// So an app that cannot prove it is a sideload build behaves as a Play build.
/// `flutter test` and debug runs pass no define, so this is also the value the
/// test suite exercises.
const DistributionTrack kDistributionTrack = _rawTrack == 'sideload'
    ? DistributionTrack.sideload
    : DistributionTrack.play;
