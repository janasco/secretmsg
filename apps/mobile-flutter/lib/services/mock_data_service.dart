import 'package:flutter/material.dart';
import '../models/models.dart';

class MockDataService extends ChangeNotifier {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // Active User Profile
  final UserProfile currentUser = UserProfile(
    username: 'janasco',
    displayName: 'janasco',
    bio: 'send me anonymous vibes & candid confessions 🤍',
    isPro: true,
    vanityUrl: 'secretmsg.net/janasco',
  );

  // Settings & Toggles
  bool allowDoubleBlindReplies = true;
  bool showSenderClues = true;
  bool botShieldActive = true;
  bool aiModerationActive = true;

  // Viral Templates Pool
  final List<PromptTemplate> templates = [
    PromptTemplate(
      id: 't1',
      category: 'Hype',
      promptText: 'What is my greatest superpower that I don’t realize?',
      emoji: '⚡',
      likesCount: 1420,
    ),
    PromptTemplate(
      id: 't2',
      category: 'Confessions',
      promptText: 'Send me a secret you have never told anyone before 🤫',
      emoji: '🗝️',
      likesCount: 3890,
    ),
    PromptTemplate(
      id: 't3',
      category: 'Romance',
      promptText: 'Be honest: did you ever have feelings for me? 👀',
      emoji: '💌',
      likesCount: 5210,
    ),
    PromptTemplate(
      id: 't4',
      category: 'Chill',
      promptText: 'What song immediately reminds you of me when it plays?',
      emoji: '🎧',
      likesCount: 980,
    ),
    PromptTemplate(
      id: 't5',
      category: 'Hype',
      promptText: 'Rate our friendship out of 10 and give one unfiltered reason why 🔥',
      emoji: '🏆',
      likesCount: 2130,
    ),
    PromptTemplate(
      id: 't6',
      category: 'Confessions',
      promptText: 'What was your very first impression vs how you see me now?',
      emoji: '🎭',
      likesCount: 1740,
    ),
    PromptTemplate(
      id: 't7',
      category: 'Chill',
      promptText: 'If we were stuck in an airport for 8 hours, what would we do?',
      emoji: '✈️',
      likesCount: 890,
    ),
    PromptTemplate(
      id: 't8',
      category: 'Romance',
      promptText: 'Describe our vibe in three words and leave a hint who you are 🌹',
      emoji: '✨',
      likesCount: 4120,
    ),
  ];

  // Inbox Messages
  final List<SecretMessage> messages = [
    SecretMessage(
      id: 'msg_1',
      content: 'TBH your playlist taste is unmatched! What track have you been looping lately?',
      replyContent: 'Currently obsessed with the new Fred again.. and Tycho live sets! ✨',
      replyAt: DateTime.now().subtract(const Duration(hours: 2)),
      isPinned: true,
      isRead: true,
      deviceHint: 'Mobile / iOS',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    SecretMessage(
      id: 'msg_2',
      content: 'You always bring genuine positive energy into every room. Keep doing your thing 🤍',
      isPinned: false,
      isRead: false,
      deviceHint: 'Mobile / Android',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    SecretMessage(
      id: 'msg_3',
      content: 'I have had a secret crush on you since last semester… never had the courage to say it.',
      isPinned: false,
      isRead: false,
      deviceHint: 'Desktop / Mac',
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
    ),
    SecretMessage(
      id: 'msg_4',
      content: 'What is one life goal you haven’t told anybody yet?',
      isPinned: false,
      isRead: true,
      deviceHint: 'Mobile / iOS',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // Supporters Wall
  final List<Supporter> supporters = [
    Supporter(
      id: 'sup_1',
      alias: 'Anonymous Guardian',
      tier: 'Golden Guardian',
      note: 'Love the true zero-tracking privacy on SecretMsg. Keep it open!',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    Supporter(
      id: 'sup_2',
      alias: 'Coffee Lover #42',
      tier: 'Coffee Backer',
      note: 'Super smooth UI. Coffee on me for server hosting ☕',
      createdAt: DateTime.now().subtract(const Duration(hours: 26)),
    ),
    Supporter(
      id: 'sup_3',
      alias: 'Secret Admirer 🤫',
      tier: 'Silver Patron',
      note: 'Sent this to my crush and they replied! Thank you!',
      createdAt: DateTime.now().subtract(const Duration(hours: 48)),
    ),
    Supporter(
      id: 'sup_4',
      alias: 'Anonymous Supporter',
      tier: 'Bronze Supporter',
      note: 'Supporting independent open-source web platforms.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  // Story Themes for Sticker Studio
  final List<StoryTheme> storyThemes = [
    StoryTheme(
      id: 'obsidian',
      name: 'Obsidian',
      gradientColors: [const Color(0xFF0F172A), const Color(0xFF0B0E14)],
      textColor: Colors.white,
      cardBackground: const Color(0xFF1E293B),
    ),
    StoryTheme(
      id: 'cyber',
      name: 'Cyber Neon',
      gradientColors: [const Color(0xFF38BDF8), const Color(0xFF818CF8)],
      textColor: const Color(0xFF0F172A),
      cardBackground: Colors.white,
    ),
    StoryTheme(
      id: 'sunset',
      name: 'Amber Sunset',
      gradientColors: [const Color(0xFFF43F5E), const Color(0xFFF59E0B)],
      textColor: Colors.white,
      cardBackground: const Color(0xFF881337),
    ),
    StoryTheme(
      id: 'candy',
      name: 'Cotton Candy',
      gradientColors: [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
      textColor: Colors.white,
      cardBackground: const Color(0xFF581C87),
    ),
    StoryTheme(
      id: 'white',
      name: 'Crisp White',
      gradientColors: [const Color(0xFFFFFFFF), const Color(0xFFE2E8F0)],
      textColor: const Color(0xFF0B0E14),
      cardBackground: const Color(0xFFF8FAFC),
    ),
  ];

  // Actions
  void sendMessage(String content, {String? hint}) {
    messages.insert(
      0,
      SecretMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        deviceHint: hint ?? 'Mobile / App',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void replyToMessage(String messageId, String reply) {
    final msg = messages.firstWhere((m) => m.id == messageId);
    msg.replyContent = reply;
    msg.replyAt = DateTime.now();
    msg.isRead = true;
    notifyListeners();
  }

  void togglePin(String messageId) {
    final msg = messages.firstWhere((m) => m.id == messageId);
    msg.isPinned = !msg.isPinned;
    notifyListeners();
  }

  void markAsRead(String messageId) {
    final msg = messages.firstWhere((m) => m.id == messageId);
    msg.isRead = true;
    notifyListeners();
  }

  void wipeAllMessages() {
    messages.clear();
    notifyListeners();
  }
}
