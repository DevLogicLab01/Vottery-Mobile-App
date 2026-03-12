import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/language_service.dart';
import '../../../services/supabase_service.dart';

class RealTimeTranslationEngineWidget extends StatefulWidget {
  final VoidCallback onTranslationComplete;

  const RealTimeTranslationEngineWidget({
    super.key,
    required this.onTranslationComplete,
  });

  @override
  State<RealTimeTranslationEngineWidget> createState() =>
      _RealTimeTranslationEngineWidgetState();
}

class _RealTimeTranslationEngineWidgetState
    extends State<RealTimeTranslationEngineWidget> {
  final LanguageService _languageService = LanguageService.instance;
  final _client = SupabaseService.instance.client;
  final TextEditingController _sourceTextController = TextEditingController();

  String _sourceLanguage = 'en';
  String _targetLanguage = 'ar';
  String _translatedText = '';
  double _confidenceScore = 0.0;
  bool _isTranslating = false;
  List<Map<String, dynamic>> _translationQueue = [];

  @override
  void initState() {
    super.initState();
    _loadTranslationQueue();
  }

  @override
  void dispose() {
    _sourceTextController.dispose();
    super.dispose();
  }

  Future<void> _loadTranslationQueue() async {
    try {
      final response = await _client
          .from('translation_queue')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _translationQueue = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Load translation queue error: $e');
    }
  }

  Future<void> _translateText() async {
    if (_sourceTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter text to translate'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isTranslating = true);

    try {
      // Call OpenAI translation via Supabase Edge Function
      final response = await _client.functions.invoke(
        'openai-translation',
        body: {
          'text': _sourceTextController.text,
          'source_language': _sourceLanguage,
          'target_language': _targetLanguage,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final data = response.data;

      if (mounted) {
        setState(() {
          _translatedText = data['translated_text'] ?? '';
          _confidenceScore = (data['confidence_score'] ?? 0.0).toDouble();
          _isTranslating = false;
        });

        // Store translation in cache
        await _cacheTranslation();

        widget.onTranslationComplete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Translation completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      if (mounted) {
        setState(() => _isTranslating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cacheTranslation() async {
    try {
      await _client.from('translation_cache').insert({
        'source_text': _sourceTextController.text,
        'translated_text': _translatedText,
        'source_language': _sourceLanguage,
        'target_language': _targetLanguage,
        'confidence_score': _confidenceScore,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Cache translation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languages = _languageService.getSupportedLanguages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Real-Time Translation Engine',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _sourceLanguage,
                decoration: InputDecoration(
                  labelText: 'Source Language',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                ),
                items: languages.map((lang) {
                  return DropdownMenuItem<String>(
                    value: lang['code'] as String,
                    child: Text('${lang['flag']} ${lang['name']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sourceLanguage = value);
                  }
                },
              ),
            ),
            SizedBox(width: 3.w),
            Icon(Icons.arrow_forward, size: 24.sp),
            SizedBox(width: 3.w),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _targetLanguage,
                decoration: InputDecoration(
                  labelText: 'Target Language',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                ),
                items: languages.map((lang) {
                  return DropdownMenuItem<String>(
                    value: lang['code'] as String,
                    child: Text('${lang['flag']} ${lang['name']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _targetLanguage = value);
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        TextField(
          controller: _sourceTextController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Text to translate',
            hintText: 'Enter content for translation...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3.w),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isTranslating ? null : _translateText,
            icon: _isTranslating
                ? SizedBox(
                    width: 16.sp,
                    height: 16.sp,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Icon(Icons.translate),
            label: Text(
              _isTranslating ? 'Translating...' : 'Translate with OpenAI',
              style: TextStyle(fontSize: 14.sp),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.w),
              ),
            ),
          ),
        ),
        if (_translatedText.isNotEmpty) ...[
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(3.w),
              border: Border.all(color: Colors.green.withAlpha(51), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
                    SizedBox(width: 2.w),
                    Text(
                      'Translation Result',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(26),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 12.sp,
                            color: Colors.green,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${(_confidenceScore * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  _translatedText,
                  style: TextStyle(fontSize: 14.sp, height: 1.5),
                ),
              ],
            ),
          ),
        ],
        if (_translationQueue.isNotEmpty) ...[
          SizedBox(height: 3.h),
          Text(
            'Translation Queue (${_translationQueue.length})',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _translationQueue.length,
            itemBuilder: (context, index) {
              final item = _translationQueue[index];
              return Card(
                margin: EdgeInsets.only(bottom: 2.h),
                child: ListTile(
                  leading: Icon(
                    Icons.pending,
                    color: Colors.orange,
                    size: 24.sp,
                  ),
                  title: Text(
                    '${item['source_language']} → ${item['target_language']}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    item['content_type'] ?? 'Unknown',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
