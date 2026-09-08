import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mock_data_service.dart';
import '../models/models.dart';

class SupportersScreen extends StatelessWidget {
  const SupportersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MockDataService();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.primaryWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Supporters Wall & Perks',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monthly Funding Goal Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.outlineStrong),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'September 2026 Goal',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '72% Funded',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.emeraldGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '\$180',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primaryWhite),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '/ \$250 server costs',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted.withOpacity(0.8), height: 1.6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: const LinearProgressIndicator(
                        value: 0.72,
                        backgroundColor: AppTheme.surfaceDim,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryWhite),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'SecretMsg is 100% independent & open source. Donations fund edge servers, domains, and zero-tracking storage.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.35),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Supporter Perks Section
              const Text(
                'Polar.sh Donation Perks',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
              ),
              const SizedBox(height: 10),

              _buildPerkItem(
                icon: Icons.link_rounded,
                title: 'Custom Vanity Handles',
                subtitle: 'Claim clean handles (e.g. secretmsg.net/alex)',
              ),
              const SizedBox(height: 8),
              _buildPerkItem(
                icon: Icons.reply_all_rounded,
                title: 'Double-Blind Anonymous Replies',
                subtitle: 'Reply to anonymous senders without either party being unmasked',
              ),
              const SizedBox(height: 8),
              _buildPerkItem(
                icon: Icons.star_rounded,
                title: 'Gold Supporter Profile Badge',
                subtitle: 'Minimalist golden star badge on your link & story cards',
              ),

              const SizedBox(height: 24),

              // Community Supporters List
              const Text(
                'Community Backers Wall',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
              ),
              const SizedBox(height: 10),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: service.supporters.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final sup = service.supporters[idx];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              sup.alias,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDim,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.outline),
                              ),
                              child: Text(
                                sup.tier,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.amberGold),
                              ),
                            ),
                          ],
                        ),
                        if (sup.note != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '“${sup.note}”',
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerkItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDim,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryWhite),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
