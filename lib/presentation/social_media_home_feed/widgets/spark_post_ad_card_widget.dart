import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import './post_card_widget.dart';

class SparkPostAdCardWidget extends StatefulWidget {
  final String sourcePostId;
  final String ctaLabel;
  final String? ctaUrl;
  final void Function() onClick;

  const SparkPostAdCardWidget({
    super.key,
    required this.sourcePostId,
    required this.ctaLabel,
    required this.ctaUrl,
    required this.onClick,
  });

  @override
  State<SparkPostAdCardWidget> createState() => _SparkPostAdCardWidgetState();
}

class _SparkPostAdCardWidgetState extends State<SparkPostAdCardWidget> {
  Map<String, dynamic>? _post;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final supabase = Supabase.instance.client;
    try {
      // Try social_posts first (native feed table)
      Map<String, dynamic>? social;
      try {
        social = await supabase
            .from('social_posts')
            .select(
              'id, content, like_count, comment_count, share_count, created_at, media_urls, '
              'creator:user_profiles!creator_id(id, full_name, name, avatar_url, avatar)',
            )
            .eq('id', widget.sourcePostId)
            .maybeSingle();
      } catch (_) {
        // Some deployments use author_id instead of creator_id
        social = await supabase
            .from('social_posts')
            .select(
              'id, content, like_count, comment_count, share_count, created_at, media_urls, '
              'author:user_profiles!author_id(id, full_name, name, avatar_url, avatar)',
            )
            .eq('id', widget.sourcePostId)
            .maybeSingle();
      }

      if (social != null) {
        final profile = (social['creator'] as Map<String, dynamic>?) ??
            (social['author'] as Map<String, dynamic>?) ??
            {};
        final fullName =
            (profile['full_name'] ?? profile['name'] ?? 'User').toString();
        final mediaUrls = (social['media_urls'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final imageUrl = mediaUrls.isNotEmpty ? mediaUrls.first : null;

        setState(() {
          _post = {
            'id': social['id'],
            'content': social['content'] ?? '',
            'image_url': (imageUrl != null && imageUrl.isNotEmpty)
                ? imageUrl
                : null,
            'like_count': social['like_count'] ?? 0,
            'comment_count': social['comment_count'] ?? 0,
            'share_count': social['share_count'] ?? 0,
            'created_at': social['created_at'],
            'author': {
              'full_name': fullName,
              'avatar_url': profile['avatar_url'] ?? profile['avatar'] ?? '',
            },
          };
          _loading = false;
        });
        return;
      }

      // Fallback: posts table (web-style)
      final post = await supabase
          .from('posts')
          .select('id, content, image, likes, comments, shares, created_at, user:user_profiles(id, full_name, name, avatar_url, avatar)')
          .eq('id', widget.sourcePostId)
          .maybeSingle();

      if (post != null) {
        final user = post['user'] as Map<String, dynamic>? ?? {};
        final fullName =
            (user['full_name'] ?? user['name'] ?? 'User').toString();
        final rawImage = post['image']?.toString();
        setState(() {
          _post = {
            'id': post['id'],
            'content': post['content'] ?? '',
            'image_url': (rawImage != null && rawImage.isNotEmpty)
                ? rawImage
                : null,
            'like_count': post['likes'] ?? 0,
            'comment_count': post['comments'] ?? 0,
            'share_count': post['shares'] ?? 0,
            'created_at': post['created_at'],
            'author': {
              'full_name': fullName,
              'avatar_url': user['avatar_url'] ?? user['avatar'] ?? '',
            },
          };
          _loading = false;
        });
        return;
      }

      setState(() {
        _post = null;
        _loading = false;
      });
    } catch (e) {
      debugPrint('SparkPostAdCardWidget load error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 10.h,
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_post == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        PostCardWidget(
          post: _post!,
          onLike: (_) {},
          onComment: (_) {},
          onShare: (_) {},
        ),
        Positioned(
          top: 12,
          right: 16,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.4.h),
            decoration: BoxDecoration(
              color: AppTheme.vibrantYellow.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Spark Ad',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        if (widget.ctaUrl != null && widget.ctaUrl!.isNotEmpty)
          Positioned(
            bottom: 12,
            right: 16,
            child: ElevatedButton(
              onPressed: () async {
                widget.onClick();
                final uri = Uri.tryParse(widget.ctaUrl!);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.0.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                widget.ctaLabel,
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

