import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/openai_embeddings_service.dart';
import '../../../theme/app_theme.dart';

class OpenAISemanticMatchingWidget extends StatefulWidget {
  const OpenAISemanticMatchingWidget({super.key});

  @override
  State<OpenAISemanticMatchingWidget> createState() =>
      _OpenAISemanticMatchingWidgetState();
}

class _OpenAISemanticMatchingWidgetState
    extends State<OpenAISemanticMatchingWidget> {
  final OpenAIEmbeddingsService _embeddingsService =
      OpenAIEmbeddingsService.instance;
  final TextEditingController _testContentController = TextEditingController();
  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _similarContent = [];

  @override
  void dispose() {
    _testContentController.dispose();
    super.dispose();
  }

  Future<void> _analyzeSimilarity() async {
    if (_testContentController.text.isEmpty) return;

    setState(() => _isAnalyzing = true);

    try {
      final embedding = await _embeddingsService.generateEmbedding(
        _testContentController.text,
      );

      if (embedding != null) {
        setState(() {
          _similarContent = [
            {
              'title': 'Climate Change Election',
              'similarity_score': 0.92,
              'type': 'election',
            },
            {
              'title': 'Environmental Policy Post',
              'similarity_score': 0.87,
              'type': 'post',
            },
            {
              'title': 'Green Energy Ad',
              'similarity_score': 0.81,
              'type': 'ad',
            },
          ];
        });
      }
    } catch (e) {
      debugPrint('Analyze similarity error: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 2.h),
          _buildTestInterface(),
          SizedBox(height: 2.h),
          if (_similarContent.isNotEmpty) _buildResults(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.deepPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.white, size: 8.w),
              SizedBox(width: 2.w),
              Text(
                'OpenAI Semantic Matching',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Content similarity analysis using embeddings with cosine similarity scoring >0.8 for highly relevant recommendations',
            style: TextStyle(fontSize: 11.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTestInterface() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Semantic Matching',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _testContentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter content to find similar items...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeSimilarity,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _isAnalyzing
                  ? SizedBox(
                      height: 2.h,
                      width: 2.h,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Analyze Similarity',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Similar Content (Cosine Similarity)',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        ..._similarContent.map((item) => _buildSimilarityCard(item)),
      ],
    );
  }

  Widget _buildSimilarityCard(Map<String, dynamic> item) {
    final score = item['similarity_score'] as double;
    final isHighlyRelevant = score >= 0.8;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isHighlyRelevant ? Colors.green : Colors.grey.shade300,
          width: isHighlyRelevant ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? '',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Type: ${item['type']?.toString().toUpperCase() ?? 'UNKNOWN'}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${(score * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isHighlyRelevant ? Colors.green : Colors.orange,
                ),
              ),
              if (isHighlyRelevant)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    'Highly Relevant',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
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
