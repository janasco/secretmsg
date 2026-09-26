import 'package:flutter_test/flutter_test.dart';

import 'package:secretmsg_mobile/distribution/track.dart';
import 'package:secretmsg_mobile/ritual/update_check.dart';

const String kSideloadPage = 'https://secretmsg.net/download';
const String kPlayListing = 'https://play.google.com/store/apps/details?id=net.secretmsg.android_app';

void main() {
  group('compareVersions', () {
    test('orders triples numerically, not lexicographically', () {
      expect(compareVersions('1.4.4', '1.4.10'), lessThan(0));
      expect(compareVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(compareVersions('1.4.3', '1.4.3'), 0);
      expect(compareVersions('2.0.0', '1.9.9'), greaterThan(0));
      expect(compareVersions('1.4', '1.4.0'), 0);
    });
  });

  group('the compile-time track default', () {
    // `flutter test` (scripts/verify.sh) passes no track define, so this asserts
    // the shipped default. It is the whole safety argument for the flag: a
    // build that cannot prove it is a sideload build must behave as a Play
    // build, because a Play build pointed at a sideload APK fails to install
    // while a Play build with no Play URL just stays quiet.
    test('is the Play track when no define is supplied', () {
      expect(kDistributionTrack, DistributionTrack.play);
    });

    test('parses the two wire names', () {
      expect(DistributionTrack.play.wireName, 'play');
      expect(DistributionTrack.sideload.wireName, 'sideload');
    });
  });

  group('updateUrlForTrack', () {
    test('a Play build takes the Play URL and never the sideload one', () {
      const feed = {
        'android_latest': '1.6.10',
        'url': kSideloadPage,
        'url_sideload': kSideloadPage,
        'url_play': kPlayListing,
      };
      expect(updateUrlForTrack(feed, DistributionTrack.play), kPlayListing);
    });

    test('a sideload build takes the sideload URL and never the Play one', () {
      const feed = {
        'android_latest': '1.6.10',
        'url': kSideloadPage,
        'url_sideload': kSideloadPage,
        'url_play': kPlayListing,
      };
      expect(updateUrlForTrack(feed, DistributionTrack.sideload), kSideloadPage);
    });

    test('a missing per-track field falls back to the legacy url', () {
      // What every client released before the per-track fields sees.
      const feed = {'android_latest': '1.6.10', 'url': kSideloadPage};
      expect(updateUrlForTrack(feed, DistributionTrack.sideload), kSideloadPage);
    });

    test('a sideload build with no URL anywhere still gets the download page', () {
      expect(updateUrlForTrack(const {}, DistributionTrack.sideload), kFallbackSideloadUrl);
      expect(
        updateUrlForTrack(const {'url': '   '}, DistributionTrack.sideload),
        kFallbackSideloadUrl,
      );
    });

    test('a Play build is never handed the sideload url when url_play is absent', () {
      // The bug this whole change exists to prevent. The feed deliberately
      // omits url_play while Play is unpublished, and `url` is by definition
      // the sideload page, so falling back to it would send a Play user to an
      // APK Android refuses with INSTALL_FAILED_UPDATE_INCOMPATIBLE. Returning
      // null keeps the client silent instead.
      const feed = {'android_latest': '1.6.10', 'url': kSideloadPage, 'url_sideload': kSideloadPage};
      expect(updateUrlForTrack(feed, DistributionTrack.play), isNull);
      expect(updateUrlForTrack(const {}, DistributionTrack.play), isNull);
    });

    test('an empty or blank per-track value counts as absent', () {
      const feed = {
        'url_play': '',
        'url_sideload': '  ',
        'url': kSideloadPage,
      };
      expect(updateUrlForTrack(feed, DistributionTrack.play), isNull);
      expect(updateUrlForTrack(feed, DistributionTrack.sideload), kSideloadPage);
    });

    test('each track reads its own feed key', () {
      expect(urlFieldForTrack(DistributionTrack.play), 'url_play');
      expect(urlFieldForTrack(DistributionTrack.sideload), 'url_sideload');
    });
  });

  group('UpdateInfo.hasDestination', () {
    test('is false only when the feed named nothing for this track', () {
      const withUrl = UpdateInfo(
        current: '1.6.9',
        latest: '1.6.10',
        url: kSideloadPage,
        behind: true,
        track: DistributionTrack.sideload,
      );
      const withoutUrl = UpdateInfo(
        current: '1.6.9',
        latest: '1.6.10',
        url: null,
        behind: true,
        track: DistributionTrack.play,
      );
      expect(withUrl.hasDestination, isTrue);
      expect(withoutUrl.hasDestination, isFalse);
    });
  });
}
