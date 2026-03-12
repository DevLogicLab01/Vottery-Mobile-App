import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TopEarnersTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> earners;

  const TopEarnersTableWidget({super.key, required this.earners});

  @override
  State<TopEarnersTableWidget> createState() => _TopEarnersTableWidgetState();
}

class _TopEarnersTableWidgetState extends State<TopEarnersTableWidget> {
  int _sortColumnIndex = 3;
  bool _sortAscending = false;
  late List<Map<String, dynamic>> _sortedEarners;

  @override
  void initState() {
    super.initState();
    _sortedEarners = List.from(
      widget.earners.isEmpty ? _mockEarners() : widget.earners,
    );
    _sortData();
  }

  List<Map<String, dynamic>> _mockEarners() {
    return [
      {
        'user_name': 'OracleKing',
        'predictions_made': 145,
        'accuracy_score': 0.87,
        'vp_earned': 12450,
      },
      {
        'user_name': 'VoteWizard',
        'predictions_made': 98,
        'accuracy_score': 0.82,
        'vp_earned': 9870,
      },
      {
        'user_name': 'PredictPro',
        'predictions_made': 203,
        'accuracy_score': 0.79,
        'vp_earned': 8920,
      },
      {
        'user_name': 'ElectionGuru',
        'predictions_made': 67,
        'accuracy_score': 0.91,
        'vp_earned': 7650,
      },
      {
        'user_name': 'ForecastAce',
        'predictions_made': 112,
        'accuracy_score': 0.75,
        'vp_earned': 6340,
      },
    ];
  }

  void _sortData() {
    final columns = [
      'user_name',
      'predictions_made',
      'accuracy_score',
      'vp_earned',
    ];
    if (_sortColumnIndex < columns.length) {
      final key = columns[_sortColumnIndex];
      _sortedEarners.sort((a, b) {
        final aVal = a[key];
        final bVal = b[key];
        if (aVal is String && bVal is String) {
          return _sortAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
        }
        final aNum = (aVal as num?)?.toDouble() ?? 0;
        final bNum = (bVal as num?)?.toDouble() ?? 0;
        return _sortAscending ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFFB347),
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Top Earners',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FA)),
              dataRowMinHeight: 40,
              dataRowMaxHeight: 48,
              columnSpacing: 3.w,
              headingTextStyle: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              columns: [
                DataColumn(
                  label: const Text('User'),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                    _sortData();
                  }),
                ),
                DataColumn(
                  label: const Text('Predictions'),
                  numeric: true,
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                    _sortData();
                  }),
                ),
                DataColumn(
                  label: const Text('Accuracy'),
                  numeric: true,
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                    _sortData();
                  }),
                ),
                DataColumn(
                  label: const Text('VP Earned'),
                  numeric: true,
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                    _sortData();
                  }),
                ),
              ],
              rows: _sortedEarners.asMap().entries.map((entry) {
                final i = entry.key;
                final earner = entry.value;
                final accuracy =
                    (earner['accuracy_score'] as num?)?.toDouble() ?? 0;
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (i < 3)
                            Text(
                              ['🥇', '🥈', '🥉'][i],
                              style: const TextStyle(fontSize: 14),
                            ),
                          if (i >= 3) SizedBox(width: 2.w),
                          SizedBox(width: 1.w),
                          Text(
                            earner['user_name']?.toString() ?? 'Unknown',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        earner['predictions_made']?.toString() ?? '0',
                        style: GoogleFonts.inter(fontSize: 11.sp),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 1.5.w,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _accuracyColor(accuracy).withAlpha(26),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${(accuracy * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: _accuracyColor(accuracy),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${earner['vp_earned'] ?? 0} VP',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _accuracyColor(double accuracy) {
    if (accuracy >= 0.8) return const Color(0xFF4CAF50);
    if (accuracy >= 0.6) return const Color(0xFFFFB347);
    return const Color(0xFFFF6B6B);
  }
}
