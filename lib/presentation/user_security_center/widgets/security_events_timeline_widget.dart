import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/user_security_service.dart';

class SecurityEventsTimelineWidget extends StatefulWidget {
  final Map<String, dynamic> eventsSummary;
  final VoidCallback onEventsChanged;

  const SecurityEventsTimelineWidget({
    super.key,
    required this.eventsSummary,
    required this.onEventsChanged,
  });

  @override
  State<SecurityEventsTimelineWidget> createState() =>
      _SecurityEventsTimelineWidgetState();
}

class _SecurityEventsTimelineWidgetState
    extends State<SecurityEventsTimelineWidget> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      final events = await UserSecurityService.instance.getSecurityEvents(
        threatLevel: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resolveEvent(String eventId, String description) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Resolve Security Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(description, style: TextStyle(fontSize: 12.sp)),
              SizedBox(height: 2.h),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Resolution Action',
                  border: OutlineInputBorder(),
                  hintText: 'Describe how this was resolved',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Resolve'),
            ),
          ],
        );
      },
    );

    if (action != null && action.isNotEmpty) {
      final success = await UserSecurityService.instance.resolveSecurityEvent(
        eventId,
        action,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event resolved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onEventsChanged();
        _loadEvents();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Summary cards
        Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Critical',
                  '${widget.eventsSummary['critical'] ?? 0}',
                  Colors.red,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildSummaryCard(
                  'High',
                  '${widget.eventsSummary['high'] ?? 0}',
                  Colors.orange,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildSummaryCard(
                  'Medium',
                  '${widget.eventsSummary['medium'] ?? 0}',
                  Colors.yellow[700]!,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildSummaryCard(
                  'Low',
                  '${widget.eventsSummary['low'] ?? 0}',
                  Colors.green,
                ),
              ),
            ],
          ),
        ),

        // Filter chips
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          child: Wrap(
            spacing: 2.w,
            children: [
              _buildFilterChip('all', 'All'),
              _buildFilterChip('critical', 'Critical'),
              _buildFilterChip('high', 'High'),
              _buildFilterChip('medium', 'Medium'),
              _buildFilterChip('low', 'Low'),
            ],
          ),
        ),
        SizedBox(height: 2.h),

        // Events timeline
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _events.isEmpty
              ? Center(
                  child: Text(
                    'No security events found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    final eventType = event['event_type'] ?? '';
                    final threatLevel = event['threat_level'] ?? 'low';
                    final description = event['description'] ?? '';
                    final ipAddress = event['ip_address'];
                    final deviceName = event['device_name'];
                    final isResolved = event['is_resolved'] ?? false;
                    final createdAt = event['created_at'] != null
                        ? DateTime.parse(event['created_at'])
                        : DateTime.now();

                    Color threatColor;
                    IconData eventIcon;
                    switch (threatLevel) {
                      case 'critical':
                        threatColor = Colors.red;
                        eventIcon = Icons.error;
                        break;
                      case 'high':
                        threatColor = Colors.orange;
                        eventIcon = Icons.warning;
                        break;
                      case 'medium':
                        threatColor = Colors.yellow[700]!;
                        eventIcon = Icons.info;
                        break;
                      default:
                        threatColor = Colors.green;
                        eventIcon = Icons.check_circle_outline;
                    }

                    return Card(
                      margin: EdgeInsets.only(bottom: 2.h),
                      child: ExpansionTile(
                        leading: Icon(eventIcon, color: threatColor),
                        title: Text(
                          eventType.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 0.5.h),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.sp),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              createdAt.toString().substring(0, 16),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: isResolved
                                ? Colors.green.withAlpha(51)
                                : threatColor.withAlpha(51),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            isResolved ? 'RESOLVED' : threatLevel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: isResolved ? Colors.green : threatColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(3.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (ipAddress != null)
                                  _buildDetailRow(
                                    'IP Address',
                                    ipAddress,
                                    Icons.location_on,
                                  ),
                                if (deviceName != null)
                                  _buildDetailRow(
                                    'Device',
                                    deviceName,
                                    Icons.devices,
                                  ),
                                SizedBox(height: 1.h),
                                if (!isResolved)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _resolveEvent(
                                        event['id'],
                                        description,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: const Text('Mark as Resolved'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = value);
          _loadEvents();
        }
      },
      selectedColor: Theme.of(context).colorScheme.primary.withAlpha(51),
      labelStyle: TextStyle(
        fontSize: 11.sp,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: Colors.grey[600]),
          SizedBox(width: 2.w),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 11.sp)),
          ),
        ],
      ),
    );
  }
}
