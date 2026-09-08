import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/mock_data_service.dart';
import '../models/models.dart';
import '../widgets/qr_dialog.dart';
import 'compose_screen.dart';
import 'dice_screen.dart';
import 'settings_screen.dart';
import 'inbox_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final service = MockDataService();
  String selectedCategory = 'All';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  final categories = ['All', 'Hype', 'Confessions', 'Chill', 'Romance'];

  @override
  Widget build(BuildContext context) {
    final filteredTemplates = service.templates.where((t) {
      final matchesCategory = selectedCategory == 'All' || t.category.toLowerCase() == selectedCategory.toLowerCase();
      final matchesSearch = searchQuery.isEmpty || t.promptText.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.outlineStrong, width: 1),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'S',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Color(0xFF0B0E14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SecretMsg',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontSize: 18,
                                    height: 1.1,
                                  ),
                            ),
                            Text(
                              'secretmsg.net',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: AppTheme.skyBlue,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                          },
                          icon: const Icon(Icons.settings_outlined, size: 22, color: AppTheme.textMuted),
                          tooltip: 'Settings',
                        ),
                        IconButton(
                          onPressed: () {
                            if (widget.onNavigateTab != null) {
                              widget.onNavigateTab!(3); // Switch to Inbox tab
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const InboxScreen()),
                              );
                            }
                          },
                          icon: const Icon(Icons.mail_outline_rounded, size: 22, color: AppTheme.textMuted),
                          tooltip: 'Inbox',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDim,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.outline, width: 1),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (val) => setState(() => searchQuery = val),
                    style: const TextStyle(fontSize: 13, color: AppTheme.primaryWhite),
                    decoration: InputDecoration(
                      hintText: 'Search candid templates & prompts...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.textMuted),
                              onPressed: () {
                                searchController.clear();
                                setState(() => searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ),

            // Category Pills
            SliverToBoxAdapter(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = categories[idx];
                    final isSelected = selectedCategory == cat;
                    return InkWell(
                      onTap: () => setState(() => selectedCategory = cat),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryWhite : AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryWhite : AppTheme.outline,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF0B0E14) : AppTheme.primaryWhite,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Hero Vanity Link Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.outlineStrong, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.03),
                        blurRadius: 15,
                        inset: true,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.emeraldGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'LIVE ON SECRETMSG.NET',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppTheme.emeraldGreen,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.amberGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.amberGold.withOpacity(0.4), width: 0.5),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star_rounded, size: 12, color: AppTheme.amberGold),
                                SizedBox(width: 3),
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.amberGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'secretmsg.net/${service.currentUser.username}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Share this link on Instagram Stories, Snapchat, or TikTok to get candid TBHs.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: 'https://${service.currentUser.vanityUrl}'));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Public link copied to clipboard!'),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 38,
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
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryWhite,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.outlineStrong),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Featured Viral Prompts',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryWhite,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DiceScreen()),
                        );
                      },
                      icon: const Icon(Icons.shuffle_rounded, size: 14, color: AppTheme.textMuted),
                      label: const Text(
                        'Dice Shuffle',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Templates Feed
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final template = filteredTemplates[index];
                    return _buildTemplateCard(context, template);
                  },
                  childCount: filteredTemplates.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, PromptTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(template.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDim,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.outline, width: 0.5),
                    ),
                    child: Text(
                      template.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.favorite_rounded, size: 12, color: AppTheme.wholesomeRose),
                  const SizedBox(width: 4),
                  Text(
                    '${template.likesCount}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            template.promptText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryWhite,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ComposeScreen(initialPrompt: template.promptText),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 12, color: Color(0xFF0B0E14)),
                  label: const Text(
                    'Ask This',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B0E14),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
