import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/messaging_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/chat_interface_widget.dart';
import './widgets/conversation_card_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';

class DirectMessagingScreen extends StatefulWidget {
  const DirectMessagingScreen({super.key});

  @override
  State<DirectMessagingScreen> createState() => _DirectMessagingScreenState();
}

class _DirectMessagingScreenState extends State<DirectMessagingScreen> {
  final MessagingService _messagingService = MessagingService.instance;
  final AuthService _authService = AuthService.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filteredConversations = [];
  String? _selectedConversationId;
  int _offlineQueueCount = 0;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _loadOfflineQueueCount();
    _setupAutoSync();
    _messagingService.updateUserPresence('online');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _syncTimer?.cancel();
    _messagingService.updateUserPresence('offline');
    super.dispose();
  }

  void _setupAutoSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _syncOfflineMessages();
    });
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      final conversations = await _messagingService.getUserConversations();
      setState(() {
        _conversations = conversations;
        _filteredConversations = conversations;
      });
    } catch (e) {
      debugPrint('Load conversations error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOfflineQueueCount() async {
    final count = await _messagingService.getOfflineQueueCount();
    setState(() => _offlineQueueCount = count);
  }

  Future<void> _syncOfflineMessages() async {
    final result = await _messagingService.syncOfflineMessages();
    if (result['success'] == true && result['synced'] > 0) {
      await _loadOfflineQueueCount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['synced']} messages synced'),
            backgroundColor: AppTheme.accentLight,
          ),
        );
      }
    }
  }

  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _conversations;
      } else {
        _filteredConversations = _conversations.where((conv) {
          final name = conv['conversation_name'] ?? 'Conversation';
          return name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _openConversation(String conversationId) {
    setState(() => _selectedConversationId = conversationId);
  }

  void _closeConversation() {
    setState(() => _selectedConversationId = null);
    _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_selectedConversationId != null) {
      return ChatInterfaceWidget(
        conversationId: _selectedConversationId!,
        onBack: _closeConversation,
      );
    }

    return ErrorBoundaryWrapper(
      screenName: 'DirectMessagingScreen',
      onRetry: _loadConversations,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Messages',
            variant: CustomAppBarVariant.standard,
            actions: [
              if (_offlineQueueCount > 0)
                Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningLight,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            size: 4.w,
                            color: Colors.white,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '$_offlineQueueCount',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(
                  Icons.sync,
                  color: theme.appBarTheme.foregroundColor,
                ),
                onPressed: _syncOfflineMessages,
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildSearchBar(theme),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredConversations.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildConversationList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showNewMessageDialog(context),
          child: Icon(Icons.edit),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: theme.colorScheme.surface,
      child: TextField(
        controller: _searchController,
        onChanged: _filterConversations,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: 1.5.h,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList() {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        itemCount: _filteredConversations.length,
        itemBuilder: (context, index) {
          final conversation = _filteredConversations[index];
          return ConversationCardWidget(
            conversation: conversation,
            onTap: () => _openConversation(conversation['id']),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 20.w,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            'No conversations yet',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Start a new conversation',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showNewMessageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Message'),
        content: Text('Select a user to start a conversation'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
