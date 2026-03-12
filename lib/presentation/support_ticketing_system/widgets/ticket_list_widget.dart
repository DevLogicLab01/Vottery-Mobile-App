import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class TicketListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> tickets;
  final Function(Map<String, dynamic>) onTicketTap;
  final VoidCallback onRefresh;
  final Function(String?, String?) onFilterChange;
  final String? selectedStatus;
  final String? selectedCategory;

  const TicketListWidget({
    super.key,
    required this.tickets,
    required this.onTicketTap,
    required this.onRefresh,
    required this.onFilterChange,
    this.selectedStatus,
    this.selectedCategory,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'waiting_for_user':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'technical':
        return Icons.computer;
      case 'billing':
        return Icons.payment;
      case 'election':
        return Icons.how_to_vote;
      case 'fraud':
        return Icons.security;
      case 'account':
        return Icons.person;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Filters
        Container(
          padding: EdgeInsets.all(4.w),
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.5.h,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    const DropdownMenuItem(value: 'open', child: Text('Open')),
                    const DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('In Progress'),
                    ),
                    const DropdownMenuItem(
                      value: 'resolved',
                      child: Text('Resolved'),
                    ),
                    const DropdownMenuItem(
                      value: 'closed',
                      child: Text('Closed'),
                    ),
                  ],
                  onChanged: (value) => onFilterChange(value, selectedCategory),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.5.h,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    const DropdownMenuItem(
                      value: 'technical',
                      child: Text('Technical'),
                    ),
                    const DropdownMenuItem(
                      value: 'billing',
                      child: Text('Billing'),
                    ),
                    const DropdownMenuItem(
                      value: 'election',
                      child: Text('Election'),
                    ),
                    const DropdownMenuItem(
                      value: 'fraud',
                      child: Text('Fraud'),
                    ),
                    const DropdownMenuItem(
                      value: 'account',
                      child: Text('Account'),
                    ),
                  ],
                  onChanged: (value) => onFilterChange(selectedStatus, value),
                ),
              ),
            ],
          ),
        ),

        // Ticket List
        Expanded(
          child: tickets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.support_agent,
                        size: 20.w,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No tickets found',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Create a ticket to get support',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => onRefresh(),
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 2.h),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: InkWell(
                          onTap: () => onTicketTap(ticket),
                          borderRadius: BorderRadius.circular(12.0),
                          child: Padding(
                            padding: EdgeInsets.all(4.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(2.w),
                                      decoration: BoxDecoration(
                                        color:
                                            _getCategoryIcon(
                                                  ticket['category'],
                                                ) ==
                                                Icons.computer
                                            ? Colors.blue.withValues(alpha: 0.1)
                                            : Colors.orange.withValues(
                                                alpha: 0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(ticket['category']),
                                        size: 5.w,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    SizedBox(width: 3.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ticket['ticket_number'] ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          Text(
                                            ticket['subject'] ?? 'No subject',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 0.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(
                                          ticket['priority'],
                                        ).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      child: Text(
                                        ticket['priority']
                                            .toString()
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w600,
                                          color: _getPriorityColor(
                                            ticket['priority'],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  ticket['description'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 1.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 2.w,
                                          height: 2.w,
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              ticket['status'],
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 1.w),
                                        Text(
                                          ticket['status']
                                              .toString()
                                              .replaceAll('_', ' ')
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(
                                              ticket['status'],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      timeago.format(
                                        DateTime.parse(ticket['created_at']),
                                      ),
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
