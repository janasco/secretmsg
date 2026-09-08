import 'package:flutter/material.dart';

class SecretMessage {
  final String id;
  final String content;
  String? replyContent;
  DateTime? replyAt;
  bool isPinned;
  bool isRead;
  final String? deviceHint;
  final DateTime createdAt;

  SecretMessage({
    required this.id,
    required this.content,
    this.replyContent,
    this.replyAt,
    this.isPinned = false,
    this.isRead = false,
    this.deviceHint,
    required this.createdAt,
  });
}

class PromptTemplate {
  final String id;
  final String category; // 'Hype', 'Confessions', 'Chill', 'Romance'
  final String promptText;
  final String emoji;
  final int likesCount;

  PromptTemplate({
    required this.id,
    required this.category,
    required this.promptText,
    required this.emoji,
    required this.likesCount,
  });
}

class Supporter {
  final String id;
  final String alias;
  final String tier;
  final String? note;
  final DateTime createdAt;

  Supporter({
    required this.id,
    required this.alias,
    required this.tier,
    this.note,
    required this.createdAt,
  });
}

class StoryTheme {
  final String id;
  final String name;
  final List<Color> gradientColors;
  final Color textColor;
  final Color cardBackground;

  StoryTheme({
    required this.id,
    required this.name,
    required this.gradientColors,
    required this.textColor,
    required this.cardBackground,
  });
}

class UserProfile {
  final String username;
  final String displayName;
  final String bio;
  final bool isPro;
  final String vanityUrl;

  UserProfile({
    required this.username,
    required this.displayName,
    required this.bio,
    required this.isPro,
    required this.vanityUrl,
  });
}
