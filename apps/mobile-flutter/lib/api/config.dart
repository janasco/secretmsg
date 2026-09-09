const String kApiBaseUrl = 'https://api.secretmsg.net';
const String kPublicBaseUrl = 'https://secretmsg.net';
const String kAccountAppUrl = 'https://app.secretmsg.net';

/// Public bot-screening site key — safe to embed client-side.
const String kTurnstileSiteKey = '0x4AAAAAAEsIItNVg9CO0YY9';

/// Maximum characters for a message / reply.
const int kMaxMessageLength = 500;

String shareUrlFor(String username) {
  return '$kPublicBaseUrl/${Uri.encodeComponent(username)}';
}