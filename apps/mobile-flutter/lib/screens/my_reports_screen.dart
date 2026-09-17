import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Outcomes for reports you filed: pending vs resolved. Anonymous reports
/// (filed signed out) can't be listed — only yours, only while signed in.
class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<FiledReport>? _reports;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await ApiClient.getMyReports();
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your reports.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'My reports'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _reports == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Text(_error!, textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.roseLight, fontSize: 13)),
          const SizedBox(height: 12),
          Center(child: OutlinedButton(onPressed: _load, child: const Text('Retry'))),
        ],
      );
    }
    final items = _reports ?? const [];
    if (items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 90),
          Icon(Icons.flag_outlined, size: 52, color: context.colors.textFaint),
          const SizedBox(height: 12),
          Text('No reports filed',
              textAlign: TextAlign.center,
              style: context.type.bodyBase.copyWith(
                  fontWeight: FontWeight.w700, color: context.colors.textSecondary)),
          const SizedBox(height: 6),
          Text('When you report abuse, the outcome shows up here.',
              textAlign: TextAlign.center, style: context.type.bodySm),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _ReportCard(report: items[i]),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final FiledReport report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final resolved = report.resolved;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: resolved
              ? context.colors.emerald.withValues(alpha: 0.35)
              : context.colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (resolved ? context.colors.emerald : context.colors.amber)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  resolved ? 'Resolved — action taken' : 'Under review',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: resolved ? context.colors.emeraldSoft : context.colors.amberLight,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                report.createdAt.length >= 10 ? report.createdAt.substring(0, 10) : report.createdAt,
                style: TextStyle(fontSize: 10.5, color: context.colors.textFaint),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(report.reason,
              style: TextStyle(fontSize: 13.5, height: 1.5, color: context.colors.textPrimary)),
        ],
      ),
    );
  }
}
