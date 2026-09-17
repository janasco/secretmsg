import '../gamification/ranks.dart';

class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final String? email;
  final String? avatarSeed;
  final String? bio;
  final int isPremium;
  final String? badgeTitle;
  final int hasVerifiedBadge;
  final int hasViewerHints;
  final int hasSenderHints;
  final int viewsCount;
  final bool isPaused;
  final int? pausedUntil;
  final List<String> hiddenWords;
  final String modSensitivity;
  final int? allowHints;
  final int customSlugUnlocked;
  final RankInfo rank;
  final int receivedCount;
  final int repliesCount;

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.email,
    this.avatarSeed,
    this.bio,
    this.isPremium = 0,
    this.badgeTitle,
    this.hasVerifiedBadge = 0,
    this.hasViewerHints = 0,
    this.hasSenderHints = 0,
    this.viewsCount = 0,
    this.isPaused = false,
    this.pausedUntil,
    this.hiddenWords = const [],
    this.modSensitivity = 'standard',
    this.allowHints,
    this.customSlugUnlocked = 0,
    this.rank = const RankInfo(tier: 'newcomer', name: 'Newcomer', emoji: '🌱', score: 0),
    this.receivedCount = 0,
    this.repliesCount = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<String> hidden = const [];
    final rawHidden = json['hidden_words'];
    if (rawHidden is List) {
      hidden = rawHidden.map((e) => e.toString()).toList();
    }
    return UserProfile(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      email: json['email']?.toString(),
      avatarSeed: json['avatar_seed']?.toString(),
      bio: json['bio']?.toString(),
      isPremium: (json['is_premium'] as num?)?.toInt() ?? 0,
      badgeTitle: json['badge_title']?.toString(),
      hasVerifiedBadge: (json['has_verified_badge'] as num?)?.toInt() ?? 0,
      hasViewerHints: (json['has_viewer_hints'] as num?)?.toInt() ?? 0,
      hasSenderHints: (json['has_sender_hints'] as num?)?.toInt() ?? 0,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      isPaused: json['is_paused'] == true,
      pausedUntil: (json['paused_until'] as num?)?.toInt(),
      hiddenWords: hidden,
      modSensitivity: json['mod_sensitivity']?.toString() ?? 'standard',
      allowHints: (json['allow_hints'] as num?)?.toInt(),
      customSlugUnlocked: (json['custom_slug_unlocked'] as num?)?.toInt() ?? 0,
      rank: RankInfo.parse(json['rank']),
      receivedCount: (json['received_count'] as num?)?.toInt() ?? 0,
      repliesCount: (json['replies_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'email': email,
        'avatar_seed': avatarSeed,
        'bio': bio,
        'is_premium': isPremium,
        'badge_title': badgeTitle,
        'has_verified_badge': hasVerifiedBadge,
        'has_viewer_hints': hasViewerHints,
        'has_sender_hints': hasSenderHints,
        'views_count': viewsCount,
        'is_paused': isPaused,
        'paused_until': pausedUntil,
      'hidden_words': hiddenWords,
      'mod_sensitivity': modSensitivity,
      'allow_hints': allowHints,
      'custom_slug_unlocked': customSlugUnlocked,
      'received_count': receivedCount,
      'replies_count': repliesCount,
      'rank': {
        'tier': rank.tier,
        'name': rank.name,
        'emoji': rank.emoji,
        'score': rank.score,
        'nextTier': rank.nextTier,
        'nextName': rank.nextName,
        'nextScore': rank.nextScore,
        'progress': rank.progress,
      },
    };

  bool get isSupporter => isPremium == 1;

  String get initials {
    final clean = displayName.trim();
    if (clean.isEmpty) return 'S';
    return clean.length >= 2 ? clean.substring(0, 2).toUpperCase() : clean.toUpperCase();
  }
}

class AnonymousMessage {
  final String id;
  final String content;
  final String? replyContent;
  final String? replyAt;
  final int isPinned;
  final int isRead;
  final String? deviceHint;
  final String createdAt;
  final bool? senderHintsLocked;
  final String? quarantineReason;

  const AnonymousMessage({
    required this.id,
    required this.content,
    this.replyContent,
    this.replyAt,
    this.isPinned = 0,
    this.isRead = 0,
    this.deviceHint,
    required this.createdAt,
    this.senderHintsLocked,
    this.quarantineReason,
  });

  factory AnonymousMessage.fromJson(Map<String, dynamic> json) {
    return AnonymousMessage(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      replyContent: json['reply_content']?.toString(),
      replyAt: json['reply_at']?.toString(),
      isPinned: (json['is_pinned'] as num?)?.toInt() ?? 0,
      isRead: (json['is_read'] as num?)?.toInt() ?? 0,
      deviceHint: json['device_hint']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      senderHintsLocked: json['sender_hints_locked'] as bool?,
      quarantineReason: json['quarantine_reason']?.toString(),
    );
  }
}

class FiledReport {
  final String id;
  final String messageId;
  final String reason;
  final bool resolved;
  final String createdAt;

  const FiledReport({
    required this.id,
    required this.messageId,
    required this.reason,
    required this.resolved,
    required this.createdAt,
  });

  factory FiledReport.fromJson(Map<String, dynamic> json) {
    final resolved = json['resolved'];
    return FiledReport(
      id: json['id']?.toString() ?? '',
      messageId: json['message_id']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      resolved: resolved == 1 || resolved == true,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class ReplyThread {
  final String content;
  final String? replyContent;
  final String? replyAt;
  final String createdAt;

  const ReplyThread({
    required this.content,
    this.replyContent,
    this.replyAt,
    required this.createdAt,
  });

  factory ReplyThread.fromJson(Map<String, dynamic> json) {
    return ReplyThread(
      content: json['content']?.toString() ?? '',
      replyContent: json['reply_content']?.toString(),
      replyAt: json['reply_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class BlockedSender {
  final String senderFpHash;
  final String createdAt;

  const BlockedSender({
    required this.senderFpHash,
    this.createdAt = '',
  });

  factory BlockedSender.fromJson(Map<String, dynamic> json) {
    return BlockedSender(
      senderFpHash: json['sender_fp_hash']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class Supporter {
  final String id;
  final String alias;
  final String tier;
  final String? note;
  final String createdAt;

  const Supporter({
    required this.id,
    required this.alias,
    required this.tier,
    this.note,
    required this.createdAt,
  });

  factory Supporter.fromJson(Map<String, dynamic> json) {
    return Supporter(
      id: json['id']?.toString() ?? '',
      alias: json['alias']?.toString() ?? 'Anonymous Supporter',
      tier: json['tier']?.toString() ?? 'Coffee Backer',
      note: json['note']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class SupportersData {
  final List<Supporter> supporters;
  final Map<String, dynamic> stats;

  const SupportersData({required this.supporters, required this.stats});

  factory SupportersData.fromJson(Map<String, dynamic> json) {
    final list = (json['supporters'] as List?)
            ?.map((e) => Supporter.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return SupportersData(
      supporters: list,
      stats: (json['stats'] as Map<String, dynamic>?) ?? const {},
    );
  }
}