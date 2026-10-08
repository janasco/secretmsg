// NOT CRYPTOGRAPHICALLY REVIEWED. See lib/crypto/README.md and the header of
// crypto_constants.dart. Crypto bugs fail silently.
//
// Claim-link key transport.
//
// A claim link carries the per-message content key in the URL *fragment*
// (`#k=...`). Browsers never send the fragment to a server: it is not part of
// the HTTP request line, not in Referer, and not in any analytics beacon that
// reads location. That is the entire security property relied on here — the
// server sees only the token in the path.
//
// Link shape:
//   https://secretmsg.net/reply/<replyToken>#k=<base64url 32-byte key>
//
// The sender's device builds this link after sending an encrypted message and
// keeps the key locally so it can rebuild the link later (keyed by the reply
// token). The recipient never sees K in the fragment; it unwraps K from the
// message envelope with its device private key.
//
// Unverified properties: fragment confidentiality depends on the client app
// and OS not exfiltrating it (web extensions, screenshots, clipboard sync are
// all outside this code); anyone who obtains the full link can read the
// thread; there is no per-viewer authentication.
library;

import 'dart:typed_data';

import 'crypto_constants.dart';
import 'crypto_encoding.dart';

class ClaimLink {
  ClaimLink._();

  /// Fragment parameter carrying the content key.
  static const String fragmentKeyParam = 'k';

  /// Builds a claim link. [contentKey] must be exactly 32 bytes.
  ///
  /// The token is percent-encoded into the path; the key goes only into the
  /// fragment. This function never emits the key anywhere else.
  static String build({
    required String baseUrl,
    required String replyToken,
    required List<int> contentKey,
  }) {
    if (contentKey.length != kContentKeyLength) {
      throw ArgumentError.value(
          contentKey.length, 'contentKey', 'Content key must be 32 bytes');
    }
    if (replyToken.isEmpty) {
      throw ArgumentError('replyToken is required');
    }
    final trimmed = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$trimmed/reply/${Uri.encodeComponent(replyToken)}'
        '#$fragmentKeyParam=${CryptoEncoding.b64url(contentKey)}';
  }

  /// Extracts the content key from a URL or a bare `#k=...` fragment.
  ///
  /// Returns null when the fragment is missing, malformed, or the wrong size.
  /// Query parameters and the path are ignored on purpose: a link that puts
  /// the key there was never valid, and accepting it would normalize a leak.
  static Uint8List? extractKey(String urlOrFragment) {
    String? fragment;
    if (urlOrFragment.startsWith('#')) {
      fragment = urlOrFragment.substring(1);
    } else {
      final uri = Uri.tryParse(urlOrFragment);
      fragment = uri?.fragment;
    }
    if (fragment == null || fragment.isEmpty) return null;
    final params = Uri.splitQueryString(fragment);
    final raw = params[fragmentKeyParam];
    if (raw == null || raw.isEmpty) return null;
    try {
      final bytes = CryptoEncoding.b64urlDecode(raw);
      if (bytes.length != kContentKeyLength) return null;
      return bytes;
    } on FormatException {
      return null;
    }
  }

  /// True when the link carries a key fragment.
  static bool hasKey(String urlOrFragment) => extractKey(urlOrFragment) != null;

  /// Returns [uri] with the key fragment removed, for safe logging/analytics.
  /// The key cannot be reconstructed from the result.
  static Uri withoutKey(Uri uri) => uri.replace(fragment: '');

  /// Renders a loggable form of [url]: scheme, host, path and non-secret query
  /// parameters only. Fragments are dropped unconditionally, and the returned
  /// string never contains the content key.
  static String redact(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '<unparseable url>';
    final rebuilt = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
      queryParameters:
          uri.queryParameters.isEmpty ? null : uri.queryParameters,
    );
    return rebuilt.toString();
  }
}
