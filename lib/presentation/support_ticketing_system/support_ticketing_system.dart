import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/support_ticket_service.dart';
import './widgets/ticket_submission_form_widget.dart';
import './widgets/ticket_list_widget.dart';
import './widgets/ticket_detail_widget.dart';
import './widgets/faq_section_widget.dart';
import './widgets/ticket_analytics_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

/// Support Ticketing System
/// Comprehensive mobile-optimized customer support with intelligent routing
class SupportTicketingSystem extends StatefulWidget {
  const SupportTicketingSystem({super.key});

  @override
  State<SupportTicketingSystem> createState() => _SupportTicketingSystemState();
}

class _SupportTicketingSystemState extends State<SupportTicketingSystem>
    with SingleTickerProviderStateMixin {
  final SupportTicketService _service = SupportTicketService.instance;

  late TabController _tabController;
  List<Map<String, dynamic>> _tickets = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String? _selectedStatus;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final tickets = await _service.getUserTickets(
      status: _selectedStatus,
      category: _selectedCategory,
    );
    final analytics = await _service.getTicketAnalytics();

    setState(() {
      _tickets = tickets;
      _analytics = analytics;
      _isLoading = false;
    });
  }

  void _showTicketSubmissionForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TicketSubmissionFormWidget(
        onSubmit: (category, priority, subject, description) async {
          Navigator.pop(context);

          final ticket = await _service.createTicket(
            category: category,
            priority: priority,
            subject: subject,
            description: description,
          );

          if (ticket != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Ticket ${ticket['ticket_number']} created successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
            _loadData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to create ticket'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showTicketDetail(Map<String, dynamic> ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailWidget(ticketId: ticket['id']),
      ),
    );
  }

  void _applyFilters(String? status, String? category) {
    setState(() {
      _selectedStatus = status;
      _selectedCategory = category;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'SupportTicketingSystem',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          title: Text(
            'Support Center',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: theme.colorScheme.onPrimary,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onPrimary.withValues(
              alpha: 0.7,
            ),
            tabs: const [
              Tab(text: 'My Tickets'),
              Tab(text: 'FAQ'),
              Tab(text: 'Analytics'),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 6)
            : _tickets.isEmpty
            ? NoDataEmptyState(
                title: 'No Support Tickets',
                description:
                    'Submit a ticket if you need help or have questions.',
                onRefresh: _loadData,
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // My Tickets Tab
                    TicketListWidget(
                      tickets: _tickets,
                      onTicketTap: _showTicketDetail,
                      onRefresh: _loadData,
                      onFilterChange: _applyFilters,
                      selectedStatus: _selectedStatus,
                      selectedCategory: _selectedCategory,
                    ),

                    // FAQ Tab
                    FAQSectionWidget(),

                    // Analytics Tab
                    TicketAnalyticsWidget(analytics: _analytics),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showTicketSubmissionForm,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          icon: const Icon(Icons.add),
          label: Text(
            'New Ticket',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
