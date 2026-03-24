import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../services/auth_service.dart';
import '../../../services/sponsored_elections_service.dart';

/// CPE & schema workspace — mirrors Web `CpeSchemaHubSection` tabs inside campaign management.
class CpeSchemaHubSection extends StatefulWidget {
  const CpeSchemaHubSection({super.key});

  @override
  State<CpeSchemaHubSection> createState() => _CpeSchemaHubSectionState();
}

class _CpeSchemaHubSectionState extends State<CpeSchemaHubSection>
    with SingleTickerProviderStateMixin {
  final SponsoredElectionsService _service = SponsoredElectionsService.instance;
  final AuthService _auth = AuthService.instance;

  late TabController _tabController;

  bool _loading = true;
  List<Map<String, dynamic>> _elections = [];
  List<Map<String, dynamic>> _zones = [];
  Map<String, Map<String, dynamic>> _formatStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final brandId = _auth.currentUser?.id;
      final results = await Future.wait([
        brandId != null
            ? _service.getBrandSponsoredElections(brandId: brandId)
            : Future.value(<Map<String, dynamic>>[]),
        _service.getCPEPricingZones(),
        _service.getAdFormatStatistics(),
      ]);
      if (!mounted) return;
      setState(() {
        _elections = results[0] as List<Map<String, dynamic>>;
        _zones = results[1] as List<Map<String, dynamic>>;
        _formatStats = results[2] as Map<String, Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      debugPrint('CpeSchemaHubSection load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, double> _aggregateMetrics() {
    return _elections.fold<Map<String, double>>(
      {
        'spent': 0,
        'engagements': 0,
        'revenue': 0,
        'active': 0,
      },
      (acc, e) {
        acc['spent'] =
            acc['spent']! + ((e['budget_spent'] ?? 0) as num).toDouble();
        acc['engagements'] =
            acc['engagements']! + ((e['total_engagements'] ?? 0) as num).toDouble();
        acc['revenue'] =
            acc['revenue']! + ((e['generated_revenue'] ?? 0) as num).toDouble();
        if ((e['status'] as String? ?? '').toLowerCase() == 'active') {
          acc['active'] = acc['active']! + 1;
        }
        return acc;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 2.h),
            Text(
              'Loading CPE hub…',
              style: GoogleFonts.inter(color: theme.hintColor),
            ),
          ],
        ),
      );
    }

    final m = _aggregateMetrics();
    final avgCpe = m['engagements']! > 0 ? m['spent']! / m['engagements']! : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            ),
          ),
          padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Sponsored elections & CPE',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Pricing zones, formats, and schema reference',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 1.5.h),
              Row(
                children: [
                  _MetricChip(
                    label: 'Spent',
                    value: '\$${m['spent']!.toStringAsFixed(0)}',
                  ),
                  SizedBox(width: 2.w),
                  _MetricChip(
                    label: 'Engagements',
                    value: m['engagements']!.toStringAsFixed(0),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  _MetricChip(
                    label: 'Active',
                    value: m['active']!.toStringAsFixed(0),
                  ),
                  SizedBox(width: 2.w),
                  _MetricChip(
                    label: 'Avg CPE',
                    value: '\$${avgCpe.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ],
          ),
        ),
        Material(
          color: theme.colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelStyle: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'CPE matrix'),
              Tab(text: 'Market research'),
              Tab(text: 'Hype'),
              Tab(text: 'CSR'),
              Tab(text: 'Engine'),
              Tab(text: 'Revenue'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(
                formatStats: _formatStats,
                elections: _elections,
                zones: _zones,
              ),
              _CpeMatrixTab(zones: _zones),
              _InfoTab(
                title: 'Market research schema',
                body:
                    'Survey-style elections for consumer insights: demographic filters, '
                    'question branching, completion incentives, and exportable results '
                    '(CSV / JSON). Aligns with Web Market Research panel.',
              ),
              _InfoTab(
                title: 'Hype prediction format',
                body:
                    'Timeline predictions, viral coefficient tracking, and accuracy rewards. '
                    'Use for launches and pre-release engagement — same concepts as Web Hype panel.',
              ),
              _InfoTab(
                title: 'CSR election structure',
                body:
                    'Cause-aligned voting, transparent donation flow, and impact reporting. '
                    'CSR campaigns often use a lower CPE multiplier — configure in pricing engine.',
              ),
              _InfoTab(
                title: 'Pricing engine',
                body:
                    'Zone multipliers and format-specific CPE (market research +20%, CSR −20% vs baseline). '
                    'Open Dynamic CPE from the app bar for the live matrix editor.',
              ),
              _RevenueTab(service: _service, brandId: _auth.currentUser?.id),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Map<String, Map<String, dynamic>> formatStats;
  final List<Map<String, dynamic>> elections;
  final List<Map<String, dynamic>> zones;

  const _OverviewTab({
    required this.formatStats,
    required this.elections,
    required this.zones,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Ad format performance',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        _FormatCard(
          title: 'Market research',
          color: Colors.blue,
          stats: formatStats['MARKET_RESEARCH'],
        ),
        SizedBox(height: 1.h),
        _FormatCard(
          title: 'Hype prediction',
          color: Colors.purple,
          stats: formatStats['HYPE_PREDICTION'],
        ),
        SizedBox(height: 1.h),
        _FormatCard(
          title: 'CSR',
          color: Colors.green,
          stats: formatStats['CSR'],
        ),
        SizedBox(height: 2.h),
        Text(
          'Active sponsored elections',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        ...elections
            .where((e) => (e['status'] as String? ?? '').toLowerCase() == 'active')
            .map(
              (e) => Card(
                margin: EdgeInsets.only(bottom: 1.h),
                child: ListTile(
                  title: Text(
                    (e['election'] is Map
                            ? (e['election'] as Map)['title']
                            : null) ??
                        'Campaign',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Format: ${e['ad_format_type'] ?? '—'} · CPE: \$${e['cost_per_vote'] ?? e['cost_per_participant'] ?? '—'}',
                    style: GoogleFonts.inter(fontSize: 11.sp),
                  ),
                  trailing: Text(
                    '${e['total_engagements'] ?? 0}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
        if (elections
            .where((e) => (e['status'] as String? ?? '').toLowerCase() == 'active')
            .isEmpty)
          Text(
            'No active campaigns',
            style: GoogleFonts.inter(color: theme.hintColor),
          ),
        SizedBox(height: 2.h),
        Text(
          'CPE zones (sample)',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: zones.take(8).map((z) {
            return Chip(
              label: Text(
                '${z['zone_code'] ?? z['id']}: \$${z['base_cpe'] ?? '—'}',
                style: GoogleFonts.inter(fontSize: 10.sp),
              ),
            );
          }).toList(),
        ),
        if (zones.isEmpty)
          Text(
            'No zone rows returned (check cpe_pricing_zones table).',
            style: GoogleFonts.inter(color: theme.hintColor, fontSize: 11.sp),
          ),
      ],
    );
  }
}

class _FormatCard extends StatelessWidget {
  final String title;
  final Color color;
  final Map<String, dynamic>? stats;

  const _FormatCard({
    required this.title,
    required this.color,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final s = stats ?? {};
    final campaigns = (s['campaigns'] ?? 0) as int;
    final engagements = (s['engagements'] ?? 0) as int;
    final revenue = (s['revenue'] ?? 0.0) as double;
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: color.darken(),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '$campaigns campaigns · $engagements engagements · \$${revenue.toStringAsFixed(2)} revenue',
            style: GoogleFonts.inter(fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}

class _CpeMatrixTab extends StatelessWidget {
  final List<Map<String, dynamic>> zones;

  const _CpeMatrixTab({required this.zones});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (zones.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Text(
            'No CPE zones loaded.',
            style: GoogleFonts.inter(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: zones.length,
      itemBuilder: (_, i) {
        final z = zones[i];
        final name = z['zone_name']?.toString() ?? 'Zone';
        final code = z['zone_code']?.toString() ?? '';
        final base = z['base_cpe']?.toString() ?? '—';
        final mult = z['premium_multiplier']?.toString() ?? '—';
        return Card(
          margin: EdgeInsets.only(bottom: 1.h),
          child: ListTile(
            title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(
              'Code $code · multiplier $mult×',
              style: GoogleFonts.inter(fontSize: 11.sp),
            ),
            trailing: Text(
              '\$$base',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16.sp,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoTab extends StatelessWidget {
  final String title;
  final String body;

  const _InfoTab({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          body,
          style: GoogleFonts.inter(fontSize: 13.sp, height: 1.45),
        ),
      ],
    );
  }
}

class _RevenueTab extends StatefulWidget {
  final SponsoredElectionsService service;
  final String? brandId;

  const _RevenueTab({required this.service, required this.brandId});

  @override
  State<_RevenueTab> createState() => _RevenueTabState();
}

class _RevenueTabState extends State<_RevenueTab> {
  int _days = 30;
  Map<String, dynamic>? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final id = widget.brandId;
    if (id == null) {
      setState(() => _data = null);
      return;
    }
    setState(() => _loading = true);
    final end = DateTime.now().toUtc();
    final start = end.subtract(Duration(days: _days));
    final result = await widget.service.getRevenueAnalytics(
      brandId: id,
      startDateIso: start.toIso8601String(),
      endDateIso: end.toIso8601String(),
    );
    if (mounted) {
      setState(() {
        _data = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.brandId == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Text(
            'Sign in to load revenue analytics for your brand.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: theme.hintColor),
          ),
        ),
      );
    }
    if (_loading || _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final d = _data!;
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Revenue reporting',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DropdownButton<int>(
              value: _days,
              items: const [
                DropdownMenuItem(value: 7, child: Text('7d')),
                DropdownMenuItem(value: 30, child: Text('30d')),
                DropdownMenuItem(value: 90, child: Text('90d')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _days = v);
                _fetch();
              },
            ),
            IconButton(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        _revRow('Total spent', '\$${(d['totalSpent'] as double).toStringAsFixed(2)}'),
        _revRow('Total revenue', '\$${(d['totalRevenue'] as double).toStringAsFixed(2)}'),
        _revRow('Campaigns', '${d['totalCampaigns']}'),
        _revRow('Avg CPE', '\$${d['averageCPE']}'),
        _revRow('Eng. rate', '${d['averageEngagementRate']}%'),
      ],
    );
  }

  Widget _revRow(String k, String v) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: GoogleFonts.inter(fontSize: 13.sp)),
          Text(
            v,
            style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
