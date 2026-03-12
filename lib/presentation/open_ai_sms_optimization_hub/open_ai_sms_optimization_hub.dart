import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/openai_sms_optimizer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../theme/app_theme.dart';

/// OpenAI SMS Optimization Hub
/// AI-powered SMS enhancement with content length optimization,
/// personalization, engagement improvement, and A/B test generation
class OpenAISMSOptimizationHub extends StatefulWidget {
  const OpenAISMSOptimizationHub({super.key});

  @override
  State<OpenAISMSOptimizationHub> createState() =>
      _OpenAISMSOptimizationHubState();
}

class _OpenAISMSOptimizationHubState extends State<OpenAISMSOptimizationHub> {
  final OpenAISMSOptimizer _optimizer = OpenAISMSOptimizer.instance;
  final TextEditingController _messageController = TextEditingController();

  Map<String, dynamic>? _optimizationResult;
  Map<String, dynamic> _analytics = {};
  bool _isOptimizing = false;
  bool _enableLength = true;
  bool _enablePersonalization = false;
  bool _enableEngagement = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    final analytics = await _optimizer.getOptimizationAnalytics();
    if (mounted) {
      setState(() => _analytics = analytics);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'OpenAI SMS Optimization Hub',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'OpenAI SMS Optimization',
          variant: CustomAppBarVariant.withBack,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalyticsHeader(),
              SizedBox(height: 2.h),
              _buildMessageInput(),
              SizedBox(height: 2.h),
              _buildOptimizationOptions(),
              SizedBox(height: 2.h),
              _buildOptimizeButton(),
              if (_optimizationResult != null) ...[
                SizedBox(height: 2.h),
                _buildOptimizationResult(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsHeader() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optimization Analytics',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticCard(
                  'Total Optimizations',
                  '${_analytics['total_optimizations'] ?? 0}',
                  Icons.auto_fix_high,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildAnalyticCard(
                  'Avg. Reduction',
                  '${_analytics['avg_character_reduction'] ?? 0} chars',
                  Icons.compress,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryLight, size: 20.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Original Message',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter your SMS message...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.all(3.w),
            ),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Characters: ${_messageController.text.length}',
                style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryLight),
              ),
              Text(
                'Segments: ${(_messageController.text.length / 160).ceil()}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: _messageController.text.length > 160
                      ? Colors.orange
                      : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationOptions() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optimization Options',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          _buildOptionSwitch(
            'Length Optimization',
            'Compress message to fit 160 characters',
            _enableLength,
            (value) => setState(() => _enableLength = value),
          ),
          _buildOptionSwitch(
            'Personalization',
            'Add personal touch with user data',
            _enablePersonalization,
            (value) => setState(() => _enablePersonalization = value),
          ),
          _buildOptionSwitch(
            'Engagement Enhancement',
            'Improve click-through rates with urgency',
            _enableEngagement,
            (value) => setState(() => _enableEngagement = value),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSwitch(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 13.sp, color: AppTheme.textPrimaryLight),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primaryLight,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildOptimizeButton() {
    return ElevatedButton.icon(
      onPressed: _isOptimizing || _messageController.text.isEmpty
          ? null
          : _optimizeMessage,
      icon: _isOptimizing
          ? SizedBox(
              width: 16.sp,
              height: 16.sp,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.auto_fix_high),
      label: Text(
        _isOptimizing ? 'Optimizing...' : 'Optimize Message',
        style: TextStyle(fontSize: 14.sp),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryLight,
        minimumSize: Size(double.infinity, 6.h),
      ),
    );
  }

  Widget _buildOptimizationResult() {
    final originalMessage = _optimizationResult!['original_message'] as String;
    final optimizedMessage = _optimizationResult!['optimized_message'] as String? ??
        _optimizationResult!['personalized_message'] as String? ??
        _optimizationResult!['engaged_message'] as String;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optimization Result',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          _buildMessageComparison('Original', originalMessage, originalMessage.length),
          SizedBox(height: 1.h),
          _buildMessageComparison('Optimized', optimizedMessage, optimizedMessage.length),
          if (_optimizationResult!['character_savings'] != null) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
                  SizedBox(width: 2.w),
                  Text(
                    'Saved ${_optimizationResult!['character_savings']} characters',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageComparison(String label, String message, int length) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                '$length chars',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: length > 160 ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            message,
            style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Future<void> _optimizeMessage() async {
    setState(() => _isOptimizing = true);

    try {
      Map<String, dynamic>? result;

      if (_enableLength) {
        result = await _optimizer.optimizeLength(_messageController.text);
      } else if (_enablePersonalization) {
        result = await _optimizer.personalizeMessage(
          messageBody: _messageController.text,
          userData: {'name': 'User', 'tier': 'Pro'},
        );
      } else if (_enableEngagement) {
        result = await _optimizer.optimizeEngagement(_messageController.text);
      }

      if (mounted) {
        setState(() {
          _optimizationResult = result;
          _isOptimizing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isOptimizing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Optimization failed: $e')),
        );
      }
    }
  }
}