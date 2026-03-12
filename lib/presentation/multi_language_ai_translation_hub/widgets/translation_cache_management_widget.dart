import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';

class TranslationCacheManagementWidget extends StatefulWidget {
  final Map<String, dynamic>? cacheStats;
  final VoidCallback onCacheCleared;

  const TranslationCacheManagementWidget({
    super.key,
    this.cacheStats,
    required this.onCacheCleared,
  });

  @override
  State<TranslationCacheManagementWidget> createState() =>
      _TranslationCacheManagementWidgetState();
}

class _TranslationCacheManagementWidgetState
    extends State<TranslationCacheManagementWidget> {
  final _client = SupabaseService.instance.client;

  bool _isClearing = false;
  List<Map<String, dynamic>> _cachedTranslations = [];

  @override
  void initState() {
    super.initState();
    _loadCachedTranslations();
  }

  Future<void> _loadCachedTranslations() async {
    try {
      final response = await _client
          .from('translation_cache')
          .select()
          .order('hit_count', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _cachedTranslations = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Load cached translations error: $e');
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Translation Cache'),
        content: const Text(
          'Are you sure you want to clear all cached translations? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isClearing = true);

    try {
      await _client
          .from('translation_cache')
          .delete()
          .neq('id', '00000000-0000-0000-0000-000000000000');

      widget.onCacheCleared();
      await _loadCachedTranslations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Cache cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Clear cache error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = widget.cacheStats ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Translation Cache Management',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blue.withAlpha(204)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(3.w),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildCacheStatItem(
                      icon: Icons.storage,
                      label: 'Cache Size',
                      value: '${stats['total_entries'] ?? 0} entries',
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: _buildCacheStatItem(
                      icon: Icons.speed,
                      label: 'Hit Rate',
                      value:
                          '${((stats['hit_rate'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: _buildCacheStatItem(
                      icon: Icons.save,
                      label: 'Storage Used',
                      value: '${stats['storage_mb'] ?? 0} MB',
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: _buildCacheStatItem(
                      icon: Icons.trending_up,
                      label: 'Cache Hits',
                      value: '${stats['total_hits'] ?? 0}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 3.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Frequently Cached Translations',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            ElevatedButton.icon(
              onPressed: _isClearing ? null : _clearCache,
              icon: _isClearing
                  ? SizedBox(
                      width: 14.sp,
                      height: 14.sp,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.delete_sweep, size: 18),
              label: Text('Clear Cache', style: TextStyle(fontSize: 12.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        if (_cachedTranslations.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'No cached translations yet',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cachedTranslations.length,
            itemBuilder: (context, index) {
              final item = _cachedTranslations[index];
              return Card(
                margin: EdgeInsets.only(bottom: 2.h),
                child: ExpansionTile(
                  leading: Icon(Icons.cached, color: Colors.blue, size: 24.sp),
                  title: Text(
                    '${item['source_language']} → ${item['target_language']}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(Icons.visibility, size: 12.sp),
                      SizedBox(width: 1.w),
                      Text(
                        '${item['hit_count'] ?? 0} hits',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      SizedBox(width: 3.w),
                      Icon(Icons.verified, size: 12.sp, color: Colors.green),
                      SizedBox(width: 1.w),
                      Text(
                        '${((item['confidence_score'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(3.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Source:',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            item['source_text'] ?? '',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Translation:',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            item['translated_text'] ?? '',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCacheStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withAlpha(204),
            ),
          ),
        ],
      ),
    );
  }
}
