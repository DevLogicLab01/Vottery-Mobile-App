import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

class EnhancedPostsFeedsComposer extends StatefulWidget {
  const EnhancedPostsFeedsComposer({super.key});

  @override
  State<EnhancedPostsFeedsComposer> createState() =>
      _EnhancedPostsFeedsComposerState();
}

class _EnhancedPostsFeedsComposerState
    extends State<EnhancedPostsFeedsComposer> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final VPService _vpService = VPService.instance;

  String _selectedContentType = 'Post';
  final List<String> _contentTypes = ['Post', 'Moment', 'Jolts', 'Live'];
  String _privacyLevel = 'Public';
  final List<String> _privacyLevels = ['Public', 'Friends Only', 'Private'];

  final List<String> _selectedMedia = [];
  List<String> _hashtags = [];
  List<String> _mentions = [];
  int _characterCount = 0;
  int _estimatedVP = 5;
  bool _isPosting = false;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  // Autocomplete
  List<Map<String, dynamic>> _hashtagSuggestions = [];
  List<Map<String, dynamic>> _mentionSuggestions = [];
  bool _showHashtagSuggestions = false;
  bool _showMentionSuggestions = false;

  final int _maxCharacters = 5000;
  final bool _autoSaveEnabled = true;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
    _startAutoSave();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    setState(() {
      _characterCount = _contentController.text.length;
      _estimatedVP = _calculateEstimatedVP();
    });

    final text = _contentController.text;
    final cursorPosition = _contentController.selection.baseOffset;

    // Check for hashtag autocomplete
    if (cursorPosition > 0 && text[cursorPosition - 1] == '#') {
      _fetchHashtagSuggestions('');
    } else if (_showHashtagSuggestions) {
      final lastHashtagIndex = text.lastIndexOf('#', cursorPosition - 1);
      if (lastHashtagIndex != -1) {
        final query = text.substring(lastHashtagIndex + 1, cursorPosition);
        if (!query.contains(' ')) {
          _fetchHashtagSuggestions(query);
        } else {
          setState(() => _showHashtagSuggestions = false);
        }
      }
    }

    // Check for mention autocomplete
    if (cursorPosition > 0 && text[cursorPosition - 1] == '@') {
      _fetchMentionSuggestions('');
    } else if (_showMentionSuggestions) {
      final lastMentionIndex = text.lastIndexOf('@', cursorPosition - 1);
      if (lastMentionIndex != -1) {
        final query = text.substring(lastMentionIndex + 1, cursorPosition);
        if (!query.contains(' ')) {
          _fetchMentionSuggestions(query);
        } else {
          setState(() => _showMentionSuggestions = false);
        }
      }
    }
  }

  Future<void> _fetchHashtagSuggestions(String query) async {
    try {
      final results = await SupabaseService.instance.client
          .from('search_analytics')
          .select('query, search_count')
          .ilike('query', '#$query%')
          .order('search_count', ascending: false)
          .limit(10);

      setState(() {
        _hashtagSuggestions = List<Map<String, dynamic>>.from(results);
        _showHashtagSuggestions = _hashtagSuggestions.isNotEmpty;
      });
    } catch (e) {
      debugPrint('Fetch hashtag suggestions error: $e');
    }
  }

  Future<void> _fetchMentionSuggestions(String query) async {
    try {
      final results = await SupabaseService.instance.client
          .from('user_profiles')
          .select('id, username, avatar_url')
          .ilike('username', '$query%')
          .limit(10);

      setState(() {
        _mentionSuggestions = List<Map<String, dynamic>>.from(results);
        _showMentionSuggestions = _mentionSuggestions.isNotEmpty;
      });
    } catch (e) {
      debugPrint('Fetch mention suggestions error: $e');
    }
  }

  void _insertHashtag(String hashtag) {
    final text = _contentController.text;
    final cursorPosition = _contentController.selection.baseOffset;
    final lastHashtagIndex = text.lastIndexOf('#', cursorPosition - 1);

    if (lastHashtagIndex != -1) {
      final newText =
          '${text.substring(0, lastHashtagIndex)}$hashtag ${text.substring(cursorPosition)}';
      _contentController.text = newText;
      _contentController.selection = TextSelection.fromPosition(
        TextPosition(offset: lastHashtagIndex + hashtag.length + 1),
      );
    }

    setState(() => _showHashtagSuggestions = false);
  }

  void _insertMention(String username) {
    final text = _contentController.text;
    final cursorPosition = _contentController.selection.baseOffset;
    final lastMentionIndex = text.lastIndexOf('@', cursorPosition - 1);

    if (lastMentionIndex != -1) {
      final newText =
          '${text.substring(0, lastMentionIndex)}@$username ${text.substring(cursorPosition)}';
      _contentController.text = newText;
      _contentController.selection = TextSelection.fromPosition(
        TextPosition(offset: lastMentionIndex + username.length + 2),
      );
    }

    setState(() => _showMentionSuggestions = false);
  }

  int _calculateEstimatedVP() {
    int vp = 5; // Base VP
    if (_characterCount > 100) vp += 10;
    if (_hashtags.isNotEmpty) vp += 5;
    if (_mentions.isNotEmpty) vp += 3;
    if (_selectedMedia.isNotEmpty) vp += 15;
    return vp;
  }

  void _extractHashtagsAndMentions() {
    final text = _contentController.text;
    final hashtagRegex = RegExp(r'#\w+');
    final mentionRegex = RegExp(r'@\w+');

    setState(() {
      _hashtags = hashtagRegex
          .allMatches(text)
          .map((m) => m.group(0)!)
          .toList();
      _mentions = mentionRegex
          .allMatches(text)
          .map((m) => m.group(0)!.substring(1))
          .toList();
    });
  }

  Future<void> _pickMedia() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedMedia.addAll(
            images.take(4 - _selectedMedia.length).map((x) => x.path),
          );
        });
      }
    } catch (e) {
      debugPrint('Pick media error: $e');
    }
  }

  void _startAutoSave() {
    if (_autoSaveEnabled) {
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _autoSaveEnabled) {
          _saveDraft();
          _startAutoSave();
        }
      });
    }
  }

  Future<void> _saveDraft() async {
    if (_contentController.text.trim().isEmpty) return;

    try {
      await SupabaseService.instance.client.from('post_drafts').upsert({
        'user_id': SupabaseService.instance.client.auth.currentUser!.id,
        'content': _contentController.text,
        'content_type': _selectedContentType,
        'privacy_level': _privacyLevel,
        'media_urls': _selectedMedia,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Save draft error: $e');
    }
  }

  Future<void> _handlePost() async {
    if (_contentController.text.trim().isEmpty && _selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add content or media to your post'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      _extractHashtagsAndMentions();

      await SupabaseService.instance.client.from('social_posts').insert({
        'author_id': SupabaseService.instance.client.auth.currentUser!.id,
        'post_type': _selectedContentType.toLowerCase(),
        'content': _contentController.text,
        'media_urls': _selectedMedia,
        'hashtags': _hashtags,
        'mentions': _mentions,
        'privacy_level': _privacyLevel.toLowerCase().replaceAll(' ', '_'),
        'status': 'published',
        'vp_earned': _estimatedVP,
      });

      await _vpService.awardSocialVP('post_creation', 'new_post');

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post published! +$_estimatedVP VP earned'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Post creation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create post. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  void _showPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Post Preview',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  _contentController.text,
                  style: GoogleFonts.inter(fontSize: 14.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'EnhancedPostsFeedsComposer',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'close',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Create $_selectedContentType',
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: TextButton(
                onPressed: _isPosting ? null : _handlePost,
                child: _isPosting
                    ? SizedBox(
                        width: 5.w,
                        height: 5.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryLight,
                        ),
                      )
                    : Text(
                        'Post',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryLight,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content Type Selector
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.category, size: 5.w),
                        SizedBox(width: 2.w),
                        Text(
                          'Content Type:',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedContentType,
                            isExpanded: true,
                            underline: SizedBox(),
                            items: _contentTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedContentType = value!);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Rich Text Formatting Toolbar
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.format_bold,
                            color: _isBold
                                ? AppTheme.primaryLight
                                : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _isBold = !_isBold);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.format_italic,
                            color: _isItalic
                                ? AppTheme.primaryLight
                                : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _isItalic = !_isItalic);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.format_underline,
                            color: _isUnderline
                                ? AppTheme.primaryLight
                                : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _isUnderline = !_isUnderline);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.format_list_bulleted),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.format_list_numbered),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Content Input
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: TextField(
                      controller: _contentController,
                      maxLines: 8,
                      maxLength: _maxCharacters,
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        border: InputBorder.none,
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: _isBold
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontStyle: _isItalic
                            ? FontStyle.italic
                            : FontStyle.normal,
                        decoration: _isUnderline
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Privacy Controls
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ..._privacyLevels.map((level) {
                          return RadioListTile<String>(
                            title: Text(level),
                            subtitle: Text(_getPrivacyDescription(level)),
                            value: level,
                            groupValue: _privacyLevel,
                            onChanged: (value) {
                              setState(() => _privacyLevel = value!);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // VP Earning Preview
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.vibrantYellow.withAlpha(26),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.stars, color: AppTheme.vibrantYellow),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated VP Reward',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '+$_estimatedVP VP',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.vibrantYellow,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _showPreview,
                          child: Text('Preview'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickMedia,
                          icon: Icon(Icons.photo_library),
                          label: Text('Media'),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveDraft,
                          icon: Icon(Icons.save),
                          label: Text('Save Draft'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),

            // Hashtag Suggestions
            if (_showHashtagSuggestions)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 30.h,
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: _hashtagSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _hashtagSuggestions[index];
                      return ListTile(
                        title: Text(suggestion['query'] ?? ''),
                        subtitle: Text(
                          '${suggestion['search_count'] ?? 0} uses',
                        ),
                        onTap: () => _insertHashtag(suggestion['query']),
                      );
                    },
                  ),
                ),
              ),

            // Mention Suggestions
            if (_showMentionSuggestions)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 30.h,
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: _mentionSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _mentionSuggestions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: suggestion['avatar_url'] != null
                              ? NetworkImage(suggestion['avatar_url'])
                              : null,
                        ),
                        title: Text('@${suggestion['username'] ?? ''}'),
                        onTap: () =>
                            _insertMention(suggestion['username'] ?? ''),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getPrivacyDescription(String level) {
    switch (level) {
      case 'Public':
        return 'Visible to everyone';
      case 'Friends Only':
        return 'Visible to connections';
      case 'Private':
        return 'Visible only to you';
      default:
        return '';
    }
  }
}
