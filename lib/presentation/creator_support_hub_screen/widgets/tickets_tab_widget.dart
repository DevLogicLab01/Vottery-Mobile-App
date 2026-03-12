import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../services/support_ticket_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/shimmer_skeleton_loader.dart';
import '../../../widgets/enhanced_empty_state_widget.dart';
import './ticket_creation_dialog_widget.dart';
import './ticket_detail_screen_widget.dart';

class TicketsTabWidget extends StatefulWidget {
  final VoidCallback onRefresh;

  const TicketsTabWidget({super.key, required this.onRefresh});

  @override
  State<TicketsTabWidget> createState() => _TicketsTabWidgetState();
}

class _TicketsTabWidgetState extends State<TicketsTabWidget> {
  final SupportTicketService _service = SupportTicketService.instance;
  final _auth = AuthService.instance;

  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;
  String? _selectedStatus;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);

    final tickets = await _service.getUserTickets(
      status: _selectedStatus,
      category: _selectedCategory,
    );

    setState(() {
      _tickets = tickets;
      _isLoading = false;
    });
  }

  void _showTicketCreationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TicketCreationDialogWidget(
        onSubmit: () {
          Navigator.pop(context);
          _loadTickets();
          widget.onRefresh();
        },
      ),
    );
  }

  void _showTicketDetail(Map<String, dynamic> ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailScreenWidget(ticketId: ticket['id']),
      ),
    ).then((_) => _loadTickets());
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'low':
        return Icons.circle;
      case 'medium':
        return Icons.remove;
      case 'high':
        return Icons.arrow_upward;
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.circle;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.yellow;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const SkeletonList(itemCount: 6);
    }

    if (_tickets.isEmpty) {
      return NoDataEmptyState(
        title: 'No Support Tickets',
        description: 'Create a ticket if you need help or have questions.',
        onRefresh: _loadTickets,
      );
    }

    return Column(
      children: [
        // Summary cards
        Container(
          padding: EdgeInsets.all(4.w),
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Open',
                  _tickets.where((t) => t['status'] == 'open').length,
                  Colors.orange,
                  Icons.inbox,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildSummaryCard(
                  'In Progress',
                  _tickets.where((t) => t['status'] == 'in_progress').length,
                  Colors.blue,
                  Icons.pending,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildSummaryCard(
                  'Resolved',
                  _tickets.where((t) => t['status'] == 'resolved').length,
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        ),

        // Ticket list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTickets,
            child: ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                return _buildTicketCard(ticket);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 1.h),
          Text(
            count.toString(),
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final theme = Theme.of(context);
    final createdAt = DateTime.parse(ticket['created_at']);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => _showTicketDetail(ticket),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    '#${ticket['ticket_number'] ?? ticket['id'].toString().substring(0, 8)}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        ticket['status'],
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      ticket['status'].toString().toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(ticket['status']),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),

              // Title
              Text(
                ticket['subject'] ?? 'No subject',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1.h),

              // Metadata
              Row(
                children: [
                  // Category
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      ticket['category'] ?? 'General',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),

                  // Priority
                  Row(
                    children: [
                      Icon(
                        _getPriorityIcon(ticket['priority'] ?? 'medium'),
                        size: 14.sp,
                        color: _getPriorityColor(
                          ticket['priority'] ?? 'medium',
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        ticket['priority'] ?? 'Medium',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: _getPriorityColor(
                            ticket['priority'] ?? 'medium',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Time
                  Text(
                    timeago.format(createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
