import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'claude_service.dart';
import 'supabase_service.dart';

/// Mirrors Web `revenueIntelligenceService.js`: same tables, transaction types, and Claude forecast prompts.
class RevenueIntelligenceService {
  RevenueIntelligenceService._();
  static final RevenueIntelligenceService instance =
      RevenueIntelligenceService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Canonical zone labels — same order as Web `ZONES` / Claude prompt.
  static const List<String> _canonicalZoneOrder = [
    'USA',
    'Western Europe',
    'Eastern Europe',
    'India',
    'Latin America',
    'Africa',
    'Middle East/Asia',
    'Australasia',
  ];

  /// Web `ZONES` multipliers (fee-zone pricing baseline when no payout telemetry).
  static const List<double> _zoneMultipliers = [
    1.0,
    0.95,
    0.45,
    0.25,
    0.35,
    0.20,
    0.60,
    0.90,
  ];

  static String _normalizeZoneLabel(dynamic label) {
    final s = (label?.toString() ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (RegExp(r'\busa\b|united states|u\.s\.|u\.s\.a').hasMatch(s)) {
      return 'USA';
    }
    if (s.contains('western europe')) return 'Western Europe';
    if (s.contains('eastern europe')) return 'Eastern Europe';
    if (RegExp(r'\bindia\b').hasMatch(s)) return 'India';
    if (s.contains('latin america')) return 'Latin America';
    if (RegExp(r'\bafrica\b').hasMatch(s) && !s.contains('south africa')) {
      return 'Africa';
    }
    if (s.contains('middle east')) return 'Middle East/Asia';
    if (s.contains('australasia') ||
        RegExp(r'\baustralia\b').hasMatch(s) ||
        s.contains('oceania') ||
        s.contains('new zealand')) {
      return 'Australasia';
    }
    return label?.toString().trim() ?? '';
  }

  DateTime _startDate(String timeRange) {
    final now = DateTime.now();
    switch (timeRange) {
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '90d':
        return now.subtract(const Duration(days: 90));
      case '30d':
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  double _sumAmount(List<dynamic>? rows) {
    if (rows == null) return 0;
    var t = 0.0;
    for (final r in rows) {
      if (r is Map && r['amount'] != null) {
        t += double.tryParse(r['amount'].toString()) ?? 0;
      }
    }
    return t;
  }

  Future<Map<String, dynamic>> _smsAdRevenue(String timeRange) async {
    try {
      final start = _startDate(timeRange).toUtc().toIso8601String();
      final data = await _client
          .from('wallet_transactions')
          .select('amount, created_at, transaction_type')
          .inFilter('transaction_type', [
            'ad_revenue',
            'sms_ad_revenue',
            'ad_slot_revenue',
          ])
          .gte('created_at', start);
      final total = _sumAmount(data);
      return {
        'source': 'SMS Advertising',
        'total': total,
        'growth': 0.0,
        'icon': Icons.sms,
        'color': 0xFF6366F1,
      };
    } catch (e) {
      debugPrint('RevenueIntelligenceService._smsAdRevenue: $e');
      return {
        'source': 'SMS Advertising',
        'total': 0.0,
        'growth': 0.0,
        'icon': Icons.sms,
        'color': 0xFF6366F1,
      };
    }
  }

  Future<Map<String, dynamic>> _electionSponsorshipRevenue(
      String timeRange) async {
    try {
      final start = _startDate(timeRange).toUtc().toIso8601String();
      final data = await _client
          .from('sponsored_elections')
          .select('budget_total, created_at, status')
          .eq('status', 'active')
          .gte('created_at', start);
      var total = 0.0;
      if (data is List) {
        for (final r in data) {
          if (r is Map && r['budget_total'] != null) {
            total += double.tryParse(r['budget_total'].toString()) ?? 0;
          }
        }
      }
      return {
        'source': 'Election Sponsorships',
        'total': total,
        'growth': 0.0,
        'icon': Icons.how_to_vote,
        'color': 0xFF8B5CF6,
      };
    } catch (e) {
      debugPrint('RevenueIntelligenceService._electionSponsorshipRevenue: $e');
      return {
        'source': 'Election Sponsorships',
        'total': 0.0,
        'growth': 0.0,
        'icon': Icons.how_to_vote,
        'color': 0xFF8B5CF6,
      };
    }
  }

  Future<Map<String, dynamic>> _carouselRevenue(String timeRange) async {
    try {
      final start = _startDate(timeRange).toUtc().toIso8601String();
      final data = await _client
          .from('wallet_transactions')
          .select('amount, created_at, transaction_type')
          .filter('transaction_type', 'in',
              '(carousel_revenue,carousel_sponsorship,carousel_monetization)')
          .gte('created_at', start);
      final total = _sumAmount(data);
      return {
        'source': 'Carousel Monetization',
        'total': total,
        'growth': 0.0,
        'icon': Icons.view_carousel,
        'color': 0xFFEC4899,
      };
    } catch (e) {
      debugPrint('RevenueIntelligenceService._carouselRevenue: $e');
      return {
        'source': 'Carousel Monetization',
        'total': 0.0,
        'growth': 0.0,
        'icon': Icons.view_carousel,
        'color': 0xFFEC4899,
      };
    }
  }

  Future<Map<String, dynamic>> _creatorTierRevenue(String timeRange) async {
    try {
      final start = _startDate(timeRange).toUtc().toIso8601String();
      final data = await _client
          .from('carousel_creator_subscriptions')
          .select('price_paid, created_at, status')
          .eq('status', 'active')
          .gte('created_at', start);
      var total = 0.0;
      if (data is List) {
        for (final r in data) {
          if (r is Map && r['price_paid'] != null) {
            total += double.tryParse(r['price_paid'].toString()) ?? 0;
          }
        }
      }
      return {
        'source': 'Creator Tier Subscriptions',
        'total': total,
        'growth': 0.0,
        'icon': Icons.workspace_premium,
        'color': 0xFFF59E0B,
      };
    } catch (e) {
      debugPrint('RevenueIntelligenceService._creatorTierRevenue: $e');
      return {
        'source': 'Creator Tier Subscriptions',
        'total': 0.0,
        'growth': 0.0,
        'icon': Icons.workspace_premium,
        'color': 0xFFF59E0B,
      };
    }
  }

  Future<Map<String, dynamic>> _templateMarketplaceRevenue(
      String timeRange) async {
    try {
      final start = _startDate(timeRange).toUtc().toIso8601String();
      final data = await _client
          .from('carousel_template_purchases')
          .select('amount_paid, created_at')
          .gte('created_at', start);
      var total = 0.0;
      if (data is List) {
        for (final r in data) {
          if (r is Map && r['amount_paid'] != null) {
            total += double.tryParse(r['amount_paid'].toString()) ?? 0;
          }
        }
      }
      return {
        'source': 'Template Marketplace',
        'total': total,
        'growth': 0.0,
        'icon': Icons.dashboard_customize,
        'color': 0xFF10B981,
      };
    } catch (e) {
      debugPrint('RevenueIntelligenceService._templateMarketplaceRevenue: $e');
      return {
        'source': 'Template Marketplace',
        'total': 0.0,
        'growth': 0.0,
        'icon': Icons.dashboard_customize,
        'color': 0xFF10B981,
      };
    }
  }

  Future<Map<String, dynamic>> _directSponsorshipRevenue(
      String timeRange) async {
    try {
      final start = _startDate(timeRange).toUtc().toIso8601String();
      final data = await _client
          .from('wallet_transactions')
          .select('amount, created_at, transaction_type')
          .inFilter('transaction_type', [
            'sponsorship',
            'direct_sponsorship',
            'brand_deal',
          ])
          .gte('created_at', start);
      final total = _sumAmount(data);
      return {
        'source': 'Direct Sponsorships',
        'total': total,
        'growth': 0.0,
        'icon': Icons.handshake,
        'color': 0xFF3B82F6,
      };
    } catch (e) {
      debugPrint('RevenueIntelligenceService._directSponsorshipRevenue: $e');
      return {
        'source': 'Direct Sponsorships',
        'total': 0.0,
        'growth': 0.0,
        'icon': Icons.handshake,
        'color': 0xFF3B82F6,
      };
    }
  }

  /// Raw stream maps (aligned with Web service).
  Future<List<Map<String, dynamic>>> getAllRevenueStreams(
      {String timeRange = '30d'}) async {
    final results = await Future.wait([
      _smsAdRevenue(timeRange),
      _electionSponsorshipRevenue(timeRange),
      _carouselRevenue(timeRange),
      _creatorTierRevenue(timeRange),
      _templateMarketplaceRevenue(timeRange),
      _directSponsorshipRevenue(timeRange),
    ]);
    final totalRevenue =
        results.fold<double>(0, (s, m) => s + (m['total'] as double));
    return results
        .map((stream) {
          final t = stream['total'] as double;
          final pct =
              totalRevenue > 0 ? ((t / totalRevenue) * 100).toStringAsFixed(1) : '0';
          return {...stream, 'percentage': pct};
        })
        .toList(growable: false);
  }

  /// Mobile dashboard list rows (names match `RevenueStreamsListWidget`).
  Future<List<Map<String, dynamic>>> getMobileRevenueStreams(
      {String timeRange = '30d'}) async {
    final streams = await getAllRevenueStreams(timeRange: timeRange);
    return streams.map((s) {
      final name = s['source'] as String;
      final total = s['total'] as double;
      final growth = (s['growth'] as num).toDouble();
      return {
        'name': _displayName(name),
        'subtitle': '${s['percentage']}% of consolidated revenue',
        'revenue': total,
        'target': total * 1.15,
        'trend': growth,
        'color': s['color'],
        'icon': s['icon'],
      };
    }).toList();
  }

  String _displayName(String source) {
    switch (source) {
      case 'SMS Advertising':
        return 'SMS Ads Revenue';
      case 'Election Sponsorships':
        return 'Participatory Elections';
      case 'Carousel Monetization':
        return 'Carousel Monetization';
      case 'Creator Tier Subscriptions':
        return 'Creator Tiers';
      case 'Template Marketplace':
        return 'Template Sales';
      case 'Direct Sponsorships':
        return 'Sponsorships';
      default:
        return source;
    }
  }

  Future<Map<String, double>> getRevenueBreakdown(
      {String timeRange = '30d'}) async {
    final streams = await getAllRevenueStreams(timeRange: timeRange);
    final map = <String, double>{};
    for (final s in streams) {
      map[_shortBreakdownKey(s['source'] as String)] = s['total'] as double;
    }
    return map;
  }

  String _shortBreakdownKey(String source) {
    switch (source) {
      case 'SMS Advertising':
        return 'SMS Ads';
      case 'Election Sponsorships':
        return 'Elections';
      case 'Carousel Monetization':
        return 'Marketplace';
      case 'Creator Tier Subscriptions':
        return 'Creator Tiers';
      case 'Template Marketplace':
        return 'Templates';
      case 'Direct Sponsorships':
        return 'Sponsorships';
      default:
        return source;
    }
  }

  /// Same synthetic history curve as Web `getHistoricalRevenue`.
  Future<List<Map<String, dynamic>>> getHistoricalRevenue(
      {int months = 6}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: 31 * months));
      final startIso = startDate.toUtc().toIso8601String();
      final walletData = await _client
          .from('wallet_transactions')
          .select('amount, transaction_type, created_at')
          .gte('created_at', startIso);
      final electionsData = await _client
          .from('sponsored_elections')
          .select('budget_total, created_at, status')
          .eq('status', 'active')
          .gte('created_at', startIso);
      final subscriptionsData = await _client
          .from('carousel_creator_subscriptions')
          .select('price_paid, created_at, status')
          .eq('status', 'active')
          .gte('created_at', startIso);
      final templatesData = await _client
          .from('carousel_template_purchases')
          .select('amount_paid, created_at')
          .gte('created_at', startIso);

      final buckets = <String, Map<String, double>>{};
      String monthKey(String isoDate) {
        final d = DateTime.tryParse(isoDate)?.toLocal() ?? DateTime.now();
        return '${d.year}-${d.month.toString().padLeft(2, '0')}';
      }

      Map<String, double> ensureBucket(String key) {
        return buckets.putIfAbsent(
          key,
          () => {
            'smsAds': 0.0,
            'elections': 0.0,
            'carousel': 0.0,
            'tiers': 0.0,
            'templates': 0.0,
            'sponsorships': 0.0,
          },
        );
      }

      for (final row in (walletData as List)) {
        if (row is! Map) continue;
        final key = monthKey((row['created_at'] ?? '').toString());
        final bucket = ensureBucket(key);
        final amount = double.tryParse((row['amount'] ?? '0').toString()) ?? 0.0;
        final type = (row['transaction_type'] ?? '').toString();
        if (const ['ad_revenue', 'sms_ad_revenue', 'ad_slot_revenue']
            .contains(type)) {
          bucket['smsAds'] = (bucket['smsAds'] ?? 0) + amount;
        }
        if (const [
          'carousel_revenue',
          'carousel_sponsorship',
          'carousel_monetization'
        ].contains(type)) {
          bucket['carousel'] = (bucket['carousel'] ?? 0) + amount;
        }
        if (const ['sponsorship', 'direct_sponsorship', 'brand_deal']
            .contains(type)) {
          bucket['sponsorships'] = (bucket['sponsorships'] ?? 0) + amount;
        }
      }

      for (final row in (electionsData as List)) {
        if (row is! Map) continue;
        final key = monthKey((row['created_at'] ?? '').toString());
        final bucket = ensureBucket(key);
        final amount =
            double.tryParse((row['budget_total'] ?? '0').toString()) ?? 0.0;
        bucket['elections'] = (bucket['elections'] ?? 0) + amount;
      }

      for (final row in (subscriptionsData as List)) {
        if (row is! Map) continue;
        final key = monthKey((row['created_at'] ?? '').toString());
        final bucket = ensureBucket(key);
        final amount =
            double.tryParse((row['price_paid'] ?? '0').toString()) ?? 0.0;
        bucket['tiers'] = (bucket['tiers'] ?? 0) + amount;
      }

      for (final row in (templatesData as List)) {
        if (row is! Map) continue;
        final key = monthKey((row['created_at'] ?? '').toString());
        final bucket = ensureBucket(key);
        final amount =
            double.tryParse((row['amount_paid'] ?? '0').toString()) ?? 0.0;
        bucket['templates'] = (bucket['templates'] ?? 0) + amount;
      }

      final sortedKeys = buckets.keys.toList()..sort();
      return sortedKeys.map((key) {
        final parts = key.split('-');
        final year = int.tryParse(parts[0]) ?? DateTime.now().year;
        final month = int.tryParse(parts[1]) ?? DateTime.now().month;
        final date = DateTime(year, month, 1);
        final bucket = buckets[key]!;
        final revenue = (bucket['smsAds'] ?? 0) +
            (bucket['elections'] ?? 0) +
            (bucket['carousel'] ?? 0) +
            (bucket['tiers'] ?? 0) +
            (bucket['templates'] ?? 0) +
            (bucket['sponsorships'] ?? 0);
        return {
          'month': _formatMonth(date),
          'revenue': revenue.round(),
          'smsAds': (bucket['smsAds'] ?? 0).round(),
          'elections': (bucket['elections'] ?? 0).round(),
          'carousel': (bucket['carousel'] ?? 0).round(),
          'tiers': (bucket['tiers'] ?? 0).round(),
          'templates': (bucket['templates'] ?? 0).round(),
          'sponsorships': (bucket['sponsorships'] ?? 0).round(),
        };
      }).toList(growable: false);
    } catch (e) {
      debugPrint('RevenueIntelligenceService.getHistoricalRevenue: $e');
      return [];
    }
  }

  String _formatMonth(DateTime date) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${m[date.month - 1]} ${date.year}';
  }

  Future<Map<String, dynamic>> generateRevenueForecast({
    required List<Map<String, dynamic>> historicalData,
    required List<Map<String, dynamic>> streams,
    int forecastDays = 30,
  }) async {
    final totalCurrent =
        streams.fold<double>(0, (s, x) => s + (x['total'] as double));
    final denom = streams.isEmpty ? 1 : streams.length;
    final avgGrowth = streams.fold<double>(
            0, (s, x) => s + (x['growth'] as num).toDouble()) /
        denom;

    final prompt = '''
You are a revenue intelligence analyst for Vottery, a participatory voting and social platform. Analyze the following revenue data and provide a $forecastDays-day revenue forecast.

Current Monthly Revenue Streams:
${streams.map((s) => '- ${s['source']}: \$${(s['total'] as double).toStringAsFixed(0)} (${s['growth']}% growth, ${s['percentage']}% of total)').join('\n')}

Total Current Monthly Revenue: \$${totalCurrent.toStringAsFixed(0)}
Average Growth Rate: ${avgGrowth.toStringAsFixed(1)}%

Historical Monthly Totals (last 6 months):
${(historicalData.length > 6 ? historicalData.sublist(historicalData.length - 6) : historicalData).map((d) => '- ${d['month']}: \$${d['revenue']}').join('\n')}

Provide a JSON response with this exact structure:
{
  "forecast_total": <number>,
  "confidence_interval": { "low": <number>, "high": <number> },
  "growth_projection": <percentage>,
  "key_drivers": ["driver1", "driver2", "driver3"],
  "risks": ["risk1", "risk2"],
  "opportunities": ["opportunity1", "opportunity2", "opportunity3"],
  "stream_forecasts": [
    { "source": "SMS Advertising", "forecast": <number>, "confidence": "high|medium|low" },
    { "source": "Election Sponsorships", "forecast": <number>, "confidence": "high|medium|low" },
    { "source": "Carousel Monetization", "forecast": <number>, "confidence": "high|medium|low" },
    { "source": "Creator Tier Subscriptions", "forecast": <number>, "confidence": "high|medium|low" },
    { "source": "Template Marketplace", "forecast": <number>, "confidence": "high|medium|low" },
    { "source": "Direct Sponsorships", "forecast": <number>, "confidence": "high|medium|low" }
  ],
  "summary": "<2-3 sentence executive summary>"
}''';

    try {
      final key = ClaudeService.apiKey;
      if (key.isEmpty || key == 'your-anthropic-api-key-here') {
        return _fallbackForecast(totalCurrent, streams, forecastDays);
      }
      final content = await ClaudeService.instance.callClaudeAPI(prompt);
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (match != null) {
        return jsonDecode(match.group(0)!) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('RevenueIntelligenceService.generateRevenueForecast: $e');
    }
    return _fallbackForecast(totalCurrent, streams, forecastDays);
  }

  /// Same structure as Web Claude / `buildDataDrivenZoneRecommendations` rows.
  List<Map<String, dynamic>> _webShapeMarketingZoneDefaults() {
    return [
      {
        'zone': 'USA',
        'current_index': 100,
        'opportunity_score': 78,
        'primary_strategy': 'Premium enterprise sponsorship packages',
        'top_revenue_stream': 'Direct Sponsorships',
        'growth_potential': '15%',
        'tactics': [
          'Launch Fortune 500 election sponsorship tier',
          'Expand SMS ad inventory for political campaigns',
          'Premium creator tier upsell campaigns',
        ],
        'cultural_notes':
            'High willingness to pay for premium features and data analytics',
      },
      {
        'zone': 'Western Europe',
        'current_index': 95,
        'opportunity_score': 82,
        'primary_strategy': 'GDPR-compliant data monetization',
        'top_revenue_stream': 'Election Sponsorships',
        'growth_potential': '22%',
        'tactics': [
          'Localized election sponsorship for EU elections',
          'Privacy-first ad targeting',
          'Multi-language template marketplace',
        ],
        'cultural_notes':
            'Strong privacy expectations; emphasize data transparency and compliance',
      },
      {
        'zone': 'Eastern Europe',
        'current_index': 45,
        'opportunity_score': 91,
        'primary_strategy': 'Affordable creator tier entry points',
        'top_revenue_stream': 'Creator Tier Subscriptions',
        'growth_potential': '67%',
        'tactics': [
          'Introduce Bronze tier at local pricing',
          'Community election sponsorships',
          'Template marketplace in local languages',
        ],
        'cultural_notes': 'Price-sensitive market; freemium-to-paid conversion is key',
      },
      {
        'zone': 'India',
        'current_index': 25,
        'opportunity_score': 96,
        'primary_strategy': 'Mobile-first micro-transaction model',
        'top_revenue_stream': 'Template Marketplace',
        'growth_potential': '180%',
        'tactics': [
          'UPI payment integration for templates',
          'Regional language election content',
          'Influencer creator tier partnerships',
        ],
        'cultural_notes':
            'Massive mobile user base; micro-payments and regional content drive adoption',
      },
      {
        'zone': 'Latin America',
        'current_index': 35,
        'opportunity_score': 88,
        'primary_strategy': 'Social commerce carousel monetization',
        'top_revenue_stream': 'Carousel Monetization',
        'growth_potential': '95%',
        'tactics': [
          'WhatsApp-integrated SMS campaigns',
          'Carnival/festival election themes',
          'Local brand sponsorship outreach',
        ],
        'cultural_notes':
            'High social media engagement; community-driven content performs best',
      },
      {
        'zone': 'Africa',
        'current_index': 20,
        'opportunity_score': 94,
        'primary_strategy': 'Mobile money and SMS-first revenue',
        'top_revenue_stream': 'SMS Advertising',
        'growth_potential': '220%',
        'tactics': [
          'M-Pesa and mobile money integration',
          'SMS-only election participation',
          'Affordable data-light carousel formats',
        ],
        'cultural_notes':
            'Mobile-first with limited data; SMS and lightweight features are essential',
      },
      {
        'zone': 'Middle East/Asia',
        'current_index': 60,
        'opportunity_score': 85,
        'primary_strategy': 'Premium election sponsorship for brands',
        'top_revenue_stream': 'Election Sponsorships',
        'growth_potential': '48%',
        'tactics': [
          'Luxury brand election sponsorships',
          'Arabic/Mandarin localization',
          'Ramadan/CNY seasonal campaigns',
        ],
        'cultural_notes':
            'High purchasing power in Gulf states; cultural calendar alignment is critical',
      },
      {
        'zone': 'Australasia',
        'current_index': 90,
        'opportunity_score': 71,
        'primary_strategy': 'Creator ecosystem expansion',
        'top_revenue_stream': 'Creator Tier Subscriptions',
        'growth_potential': '28%',
        'tactics': [
          'Sports and outdoor brand sponsorships',
          'Creator coaching premium tier',
          'Trans-Tasman election campaigns',
        ],
        'cultural_notes':
            'Tech-savvy audience; creator tools and analytics drive premium conversions',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _buildDataDrivenZoneRecommendations(
    List<Map<String, dynamic>> streams,
  ) async {
    final start = _startDate('90d').toUtc().toIso8601String();
    Map<String, dynamic>? topStream;
    var topTotal = -1.0;
    for (final s in streams) {
      final t = (s['total'] as num?)?.toDouble() ?? 0;
      if (t > topTotal) {
        topTotal = t;
        topStream = s;
      }
    }
    final topStreamName = topStream?['source']?.toString() ?? 'Consolidated streams';

    List<Map<String, dynamic>> buildFromMultiplierBaseline() {
      final maxM = _zoneMultipliers.reduce((a, b) => a > b ? a : b);
      if (maxM <= 0) {
        return [];
      }
      final out = <Map<String, dynamic>>[];
      for (var i = 0; i < _canonicalZoneOrder.length; i++) {
        final zoneName = _canonicalZoneOrder[i];
        final m = _zoneMultipliers[i];
        final currentIndex =
            (20 + (m / maxM) * 75).round().clamp(15, 100);
        final opp =
            (40 + (1 - m / maxM) * 50).round().clamp(20, 95);
        out.add({
          'zone': zoneName,
          'current_index': currentIndex,
          'opportunity_score': opp,
          'primary_strategy':
              'No completed prize_redemptions in the last 90 days; largest consolidated stream: $topStreamName.',
          'top_revenue_stream': topStreamName,
          'growth_potential': 'TBD',
          'tactics': [
            'Populate user_profiles.country_iso and purchasing_power_zone for payout attribution',
            'Write prize_redemptions.country_code at payout time for country_restrictions.fee_zone mapping',
            'Re-run after completed redemption volume accrues',
          ],
          'cultural_notes':
              'Baseline from platform fee multipliers — not payout-derived until redemption telemetry exists.',
        });
      }
      return out;
    }

    try {
      final redemptionData = await _client
          .from('prize_redemptions')
          .select('user_id, country_code, final_amount, amount, created_at')
          .eq('status', 'completed')
          .gte('created_at', start);

      if (redemptionData is! List || redemptionData.isEmpty) {
        return buildFromMultiplierBaseline();
      }

      final userIds = <String>{};
      for (final r in redemptionData) {
        if (r is! Map) continue;
        final id = r['user_id']?.toString();
        if (id != null && id.isNotEmpty) userIds.add(id);
      }

      final profilesById = <String, Map<String, dynamic>>{};
      final idList = userIds.toList();
      const chunkSize = 120;
      for (var i = 0; i < idList.length; i += chunkSize) {
        final chunk = idList.sublist(
          i,
          i + chunkSize > idList.length ? idList.length : i + chunkSize,
        );
        final profData = await _client
            .from('user_profiles')
            .select('id, purchasing_power_zone, country_iso')
            .inFilter('id', chunk);
        if (profData is List) {
          for (final p in profData) {
            if (p is Map && p['id'] != null) {
              profilesById[p['id'].toString()] = Map<String, dynamic>.from(p);
            }
          }
        }
      }

      final restrictData = await _client
          .from('country_restrictions')
          .select('country_code, fee_zone')
          .not('fee_zone', 'is', null);

      final countryToZone = <String, int>{};
      if (restrictData is List) {
        for (final row in restrictData) {
          if (row is! Map) continue;
          final code = row['country_code']?.toString().trim().toUpperCase() ?? '';
          final fz = row['fee_zone'];
          if (code.isEmpty || fz == null) continue;
          final z = int.tryParse(fz.toString()) ?? 0;
          if (z >= 1 && z <= 8) countryToZone[code] = z;
        }
      }

      final buckets = {for (var z = 1; z <= 8; z++) z: 0.0};
      var unknownAmount = 0.0;

      int? resolveZone(Map<String, dynamic>? profile, String? redemptionCountry) {
        if (profile != null) {
          final pz = int.tryParse(
            profile['purchasing_power_zone']?.toString() ?? '',
          );
          if (pz != null && pz >= 1 && pz <= 8) return pz;
        }
        final rc = redemptionCountry?.trim().toUpperCase() ?? '';
        if (rc.isNotEmpty && countryToZone.containsKey(rc)) {
          return countryToZone[rc];
        }
        final iso =
            profile?['country_iso']?.toString().trim().toUpperCase() ?? '';
        if (iso.isNotEmpty && countryToZone.containsKey(iso)) {
          return countryToZone[iso];
        }
        return null;
      }

      for (final row in redemptionData) {
        if (row is! Map) continue;
        final amt = double.tryParse(
              (row['final_amount'] ?? row['amount'] ?? '0').toString(),
            ) ??
            0;
        final uid = row['user_id']?.toString();
        final profile = uid != null ? profilesById[uid] : null;
        final z = resolveZone(
          profile,
          row['country_code']?.toString(),
        );
        if (z == null) {
          unknownAmount += amt;
          continue;
        }
        buckets[z] = (buckets[z] ?? 0) + amt;
      }

      if (unknownAmount > 0) {
        final per = unknownAmount / 8;
        for (var z = 1; z <= 8; z++) {
          buckets[z] = (buckets[z] ?? 0) + per;
        }
      }

      final totalPayout = buckets.values.fold<double>(0, (a, b) => a + b);
      if (totalPayout <= 0) {
        return buildFromMultiplierBaseline();
      }

      var maxBucket = 1e-9;
      for (final v in buckets.values) {
        if (v > maxBucket) maxBucket = v;
      }

      const parity = 1 / 8;
      final out = <Map<String, dynamic>>[];
      for (var i = 0; i < _canonicalZoneOrder.length; i++) {
        final zoneName = _canonicalZoneOrder[i];
        final zoneNum = i + 1;
        final volume = buckets[zoneNum] ?? 0;
        final share = volume / totalPayout;
        final currentIndex =
            (20 + (volume / maxBucket) * 75).round().clamp(15, 100);
        final rawOpp = 50 + ((parity - share) / parity) * 35;
        final opportunityScore = rawOpp.round().clamp(12, 98);
        final headroomPct = share < parity
            ? (((parity - share) / parity) * 60 + 8).round().clamp(8, 95)
            : (28 - (share - parity) * 90).round().clamp(2, 28);

        out.add({
          'zone': zoneName,
          'current_index': currentIndex,
          'opportunity_score': opportunityScore,
          'primary_strategy':
              'Payout signal (90d): \$${volume.round()} completed redemption volume (${(share * 100).toStringAsFixed(1)}% of observed payouts).',
          'top_revenue_stream': topStreamName,
          'growth_potential': '$headroomPct%',
          'tactics': [
            'Zone share ${(share * 100).toStringAsFixed(1)}% vs 12.5% eight-zone parity',
            'Validate fee_zone in country_restrictions matches redemption country_iso',
            'Largest consolidated revenue stream: $topStreamName',
          ],
          'cultural_notes':
              'Derived from user_profiles.purchasing_power_zone / country_iso, prize_redemptions.country_code, and country_restrictions.fee_zone; unattributed payout amounts split evenly across zones.',
        });
      }
      return out;
    } catch (e) {
      debugPrint('RevenueIntelligenceService._buildDataDrivenZoneRecommendations: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _mergeZoneAiWithInternal(
    List<Map<String, dynamic>> aiZones,
    List<Map<String, dynamic>> streams,
  ) async {
    final internal = await _buildDataDrivenZoneRecommendations(streams);
    final byNameInternal = {for (final z in internal) z['zone'] as String: z};
    final defaults = {
      for (final z in _webShapeMarketingZoneDefaults()) z['zone'] as String: z,
    };
    final out = <Map<String, dynamic>>[];
    for (final name in _canonicalZoneOrder) {
      Map<String, dynamic>? ai;
      for (final z in aiZones) {
        final label = _normalizeZoneLabel(z['zone']);
        if (label == name || z['zone']?.toString() == name) {
          ai = Map<String, dynamic>.from(z);
          break;
        }
      }
      if (ai != null) {
        final base = Map<String, dynamic>.from(byNameInternal[name] ?? {});
        base.addAll(ai);
        base['zone'] = name;
        out.add(base);
      } else {
        out.add(
          Map<String, dynamic>.from(
            byNameInternal[name] ?? defaults[name] ?? {},
          ),
        );
      }
    }
    return out.where((z) => z.isNotEmpty).toList();
  }

  List<Map<String, dynamic>> _mapWebZonesToMobile(
    List<Map<String, dynamic>> webZones,
  ) {
    return List<Map<String, dynamic>>.generate(
      webZones.length,
      (i) => _mapZoneToMobile(webZones[i], i + 1),
    );
  }

  Map<String, dynamic> _fallbackForecast(
    double totalCurrent,
    List<Map<String, dynamic>> streams,
    int forecastDays,
  ) {
    final multiplier = forecastDays == 30
        ? 1.12
        : forecastDays == 60
            ? 1.26
            : 1.42;
    final ft = totalCurrent * multiplier;
    final sorted = List<Map<String, dynamic>>.from(streams)
      ..sort(
        (a, b) => ((b['total'] as num?)?.toDouble() ?? 0)
            .compareTo((a['total'] as num?)?.toDouble() ?? 0),
      );
    final keyDrivers = sorted
        .take(3)
        .map(
          (s) =>
              '${s['source']}: ${s['percentage'] ?? 0}% of consolidated streams (current window)',
        )
        .toList();
    final opportunities = sorted
        .take(2)
        .map((s) => 'Track ${s['source']} — largest live stream in window')
        .toList();
    return {
      'forecast_total': ft.round(),
      'confidence_interval': {
        'low': (ft * 0.88).round(),
        'high': (ft * 1.14).round(),
      },
      'growth_projection': ((multiplier - 1) * 100).toStringAsFixed(1),
      'key_drivers': keyDrivers.isNotEmpty
          ? keyDrivers
          : ['No consolidated stream totals available for this window'],
      'risks': [
        'Claude forecast unavailable — deterministic multiplier on current stream totals only',
        'Does not include forward-looking market or seasonality (model error)',
      ],
      'opportunities': opportunities.isNotEmpty
          ? opportunities
          : ['Capture live wallet and sponsorship data to improve drivers list'],
      'stream_forecasts': streams
          .map((s) => {
                'source': s['source'],
                'forecast': ((s['total'] as double) * multiplier).round(),
                'confidence': (s['growth'] as num) > 20
                    ? 'high'
                    : (s['growth'] as num) > 10
                        ? 'medium'
                        : 'low',
              })
          .toList(),
      'summary':
          'Deterministic $forecastDays-day projection: ${((multiplier - 1) * 100).toStringAsFixed(0)}% scale on current consolidated stream totals (\$${totalCurrent.toStringAsFixed(0)}). Claude unavailable or returned non-JSON.',
    };
  }

  Future<List<Map<String, dynamic>>> generateZoneRecommendations(
      List<Map<String, dynamic>> streams) async {
    Future<List<Map<String, dynamic>>> finishWithInternal() async {
      final built = await _buildDataDrivenZoneRecommendations(streams);
      if (built.isEmpty) {
        return getDefaultZoneRecommendations();
      }
      return _mapWebZonesToMobile(built);
    }

    final totalRevenue =
        streams.fold<double>(0, (s, x) => s + (x['total'] as double));
    final prompt = '''
You are a global revenue strategist for Vottery, a participatory voting platform operating across 8 geographic zones. Generate specific monetization optimization strategies for each zone.

Platform Revenue Streams:
${streams.map((s) => '- ${s['source']}: \$${(s['total'] as double).toStringAsFixed(0)} (${s['growth']}% growth)').join('\n')}

Total Monthly Revenue: \$${totalRevenue.toStringAsFixed(0)}

Generate zone-specific strategies as JSON:
{
  "zones": [
    {
      "zone": "USA",
      "current_index": 100,
      "opportunity_score": <1-100>,
      "primary_strategy": "<specific tactic>",
      "top_revenue_stream": "<stream name>",
      "growth_potential": "<percentage>",
      "tactics": ["tactic1", "tactic2", "tactic3"],
      "cultural_notes": "<brief cultural adaptation note>"
    }
  ]
}

Include all 8 zones: USA, Western Europe, Eastern Europe, India, Latin America, Africa, Middle East/Asia, Australasia''';

    try {
      final key = ClaudeService.apiKey;
      if (key.isEmpty || key == 'your-anthropic-api-key-here') {
        return finishWithInternal();
      }
      final content = await ClaudeService.instance.callClaudeAPI(prompt);
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (match != null) {
        final decoded = jsonDecode(match.group(0)!) as Map<String, dynamic>;
        final zones = decoded['zones'];
        if (zones is List) {
          final typed = zones
              .whereType<Map>()
              .map((z) => Map<String, dynamic>.from(z))
              .toList();
          if (typed.length >= 8) {
            return _mapWebZonesToMobile(typed);
          }
          if (typed.isNotEmpty) {
            final merged = await _mergeZoneAiWithInternal(typed, streams);
            return _mapWebZonesToMobile(merged);
          }
        }
      }
    } catch (e) {
      debugPrint('RevenueIntelligenceService.generateZoneRecommendations: $e');
    }
    return finishWithInternal();
  }

  Map<String, dynamic> _mapZoneToMobile(Map<String, dynamic> z, int index) {
    final name = z['zone']?.toString() ?? 'Zone';
    final score = (z['opportunity_score'] is num)
        ? (z['opportunity_score'] as num).toDouble()
        : 50.0;
    final growthStr = z['growth_potential']?.toString() ?? '10%';
    final growthRate =
        double.tryParse(growthStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 10.0;
    return {
      'zone_number': index,
      'name': name,
      'revenue': score * 1200,
      'arpu': 4.0 + (score / 25),
      'growth_rate': growthRate,
      'primary_strategy': z['primary_strategy'],
      'tactics': z['tactics'],
    };
  }

  List<Map<String, dynamic>> getDefaultZoneRecommendations() {
    return [
      {
        'zone_number': 1,
        'name': 'USA',
        'revenue': 98500.0,
        'arpu': 12.40,
        'growth_rate': 15.0,
      },
      {
        'zone_number': 2,
        'name': 'Western Europe',
        'revenue': 72300.0,
        'arpu': 9.80,
        'growth_rate': 22.0,
      },
      {
        'zone_number': 3,
        'name': 'Eastern Europe',
        'revenue': 18900.0,
        'arpu': 3.60,
        'growth_rate': 67.0,
      },
      {
        'zone_number': 4,
        'name': 'India',
        'revenue': 22100.0,
        'arpu': 2.80,
        'growth_rate': 180.0,
      },
      {
        'zone_number': 5,
        'name': 'Latin America',
        'revenue': 31200.0,
        'arpu': 4.20,
        'growth_rate': 95.0,
      },
      {
        'zone_number': 6,
        'name': 'Africa',
        'revenue': 4600.0,
        'arpu': 1.20,
        'growth_rate': 220.0,
      },
      {
        'zone_number': 7,
        'name': 'Middle East/Asia',
        'revenue': 22100.0,
        'arpu': 5.10,
        'growth_rate': 48.0,
      },
      {
        'zone_number': 8,
        'name': 'Australasia',
        'revenue': 28400.0,
        'arpu': 8.90,
        'growth_rate': 28.0,
      },
    ];
  }

  List<Map<String, dynamic>> defaultGrowthRecommendations() {
    return [
      {
        'recommendation':
            'Latin America: Increase election sponsorships aligned to local events',
        'projected_gain': '+\$15K/month',
        'rationale': 'High growth zones respond strongly to sponsored elections',
        'impact': 'high',
        'difficulty': 'medium',
      },
      {
        'recommendation':
            'Template Marketplace: Launch premium tier with advanced templates',
        'projected_gain': '+\$8K/month',
        'rationale': 'Expand high-margin digital goods with creator tooling',
        'impact': 'medium',
        'difficulty': 'low',
      },
      {
        'recommendation':
            'Africa: Introduce micro-payment SMS ad packages',
        'projected_gain': '+\$5K/month',
        'rationale': 'Mobile-first users monetize best through lightweight SKUs',
        'impact': 'medium',
        'difficulty': 'high',
      },
    ];
  }
}
