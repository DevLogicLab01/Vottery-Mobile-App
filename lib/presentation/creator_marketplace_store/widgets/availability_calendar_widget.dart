import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AvailabilityCalendarWidget extends StatefulWidget {
  final String creatorId;
  final Function(DateTime) onDateSelected;

  const AvailabilityCalendarWidget({
    super.key,
    required this.creatorId,
    required this.onDateSelected,
  });

  @override
  State<AvailabilityCalendarWidget> createState() =>
      _AvailabilityCalendarWidgetState();
}

class _AvailabilityCalendarWidgetState
    extends State<AvailabilityCalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, String> _availability = {};

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  void _loadAvailability() {
    // Mock availability data - in production, fetch from Supabase
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.add(Duration(days: i));
      if (i % 7 == 0 || i % 7 == 6) {
        _availability[DateTime(date.year, date.month, date.day)] =
            'unavailable';
      } else if (i % 3 == 0) {
        _availability[DateTime(date.year, date.month, date.day)] = 'booked';
      } else if (i % 5 == 0) {
        _availability[DateTime(date.year, date.month, date.day)] = 'limited';
      } else {
        _availability[DateTime(date.year, date.month, date.day)] = 'available';
      }
    }
    setState(() {});
  }

  Color _getColorForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final status = _availability[normalizedDay];

    switch (status) {
      case 'available':
        return Colors.green;
      case 'limited':
        return Colors.amber;
      case 'booked':
        return Colors.red;
      case 'unavailable':
        return Colors.grey;
      default:
        return Colors.transparent;
    }
  }

  bool _canSelectDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final status = _availability[normalizedDay];
    return status == 'available' || status == 'limited';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability Calendar',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: AppTheme.primaryLight, size: 5.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Creator timezone: EST (UTC-5)',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(Duration(days: 90)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, false);
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, true);
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, false, isToday: true);
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              if (_canSelectDay(selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                widget.onDateSelected(selectedDay);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('This date is not available'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ),
        SizedBox(height: 2.h),
        _buildLegend(),
      ],
    );
  }

  Widget _buildDayCell(DateTime day, bool isSelected, {bool isToday = false}) {
    final color = _getColorForDay(day);
    final canSelect = _canSelectDay(day);

    return Container(
      margin: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryLight
            : color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(color: AppTheme.primaryLight, width: 2.0)
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 11.sp,
            color: isSelected
                ? Colors.white
                : (canSelect
                      ? AppTheme.textPrimaryLight
                      : AppTheme.textSecondaryLight),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final items = [
      {'color': Colors.green, 'label': 'Available'},
      {'color': Colors.amber, 'label': 'Limited slots'},
      {'color': Colors.red, 'label': 'Booked'},
      {'color': Colors.grey, 'label': 'Unavailable'},
    ];

    return Wrap(
      spacing: 4.w,
      runSpacing: 1.h,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4.w,
              height: 4.w,
              decoration: BoxDecoration(
                color: item['color'] as Color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 1.w),
            Text(
              item['label'] as String,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
