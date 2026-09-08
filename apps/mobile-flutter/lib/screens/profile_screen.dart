import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/mock_data_service.dart';
import '../widgets/qr_dialog.dart';
import 'sticker_studio_screen.dart';
import 'supporters_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final service = MockDataService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SupportersScreen()),
              );
            },
            icon: const Icon(Icons.star_rounded, color: AppTheme.amberGold, size: 22),
            tooltip: 'Supporter Perks',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textMuted, size: 20),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Profile Identity Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.outlineStrong),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.04),
                      blurRadius: 20,
                      inset: true,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.outlineStrong, width: 2),
                            color: AppTheme.surfaceDim,
                          ),
                          child: const Center(
                            child: Text(
                              'J',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryWhite,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.amberGold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star_rounded, size: 10, color: Color(0xFF0B0E14)),
                                SizedBox(width: 2),
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0B0E14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      service.currentUser.displayName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryWhite,
                      ),
                    ),
                    Text(
                      '@${service.currentUser.username} • secretmsg.net',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.currentUser.bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),

                    // Vanity Link Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDim,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.link_rounded, size: 16, color: AppTheme.textMuted),
                              const SizedBox(width: 8),
                              Text(
                                service.currentUser.vanityUrl,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: AppTheme.primaryWhite,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Live',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.emeraldGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Copy & QR Actions
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: 'https://${service.currentUser.vanityUrl}'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Public link copied!'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Color(0xFF1E293B),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0B0E14)),
                              label: const Text(
                                'Copy Link',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0B0E14),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryWhite,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => QrDialog(vanityUrl: service.currentUser.vanityUrl),
                              );
                            },
                            icon: const Icon(Icons.qr_code_2_rounded, size: 16, color: AppTheme.primaryWhite),
                            label: const Text(
                              'QR',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryWhite),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.outlineStrong),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Creator Tools Menu
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Creator Tools',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_filter_rounded, color: AppTheme.primaryWhite, size: 20),
                      title: const Text('Story Sticker Studio', style: TextStyle(fontSize: 13, color: AppTheme.primaryWhite)),
                      subtitle: const Text('Export 9:16 cards for Instagram & Snapchat', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StickerStudioScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppTheme.outline),
                    ListTile(
                      leading: const Icon(Icons.star_rounded, color: AppTheme.amberGold, size: 20),
                      title: const Text('Supporters Wall & Perks', style: TextStyle(fontSize: 13, color: AppTheme.primaryWhite)),
                      subtitle: const Text('Transparent hosting funding & Polar perks', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SupportersScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppTheme.outline),
                    ListTile(
                      leading: const Icon(Icons.shield_rounded, color: AppTheme.skyBlue, size: 20),
                      title: const Text('Privacy & Security Vault', style: TextStyle(fontSize: 13, color: AppTheme.primaryWhite)),
                      subtitle: const Text('Zero-log guarantee & nuclear data wipes', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
