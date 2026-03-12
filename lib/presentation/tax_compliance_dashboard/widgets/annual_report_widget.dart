import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AnnualReportWidget extends StatefulWidget {
  final List<Map<String, dynamic>> documents;

  const AnnualReportWidget({super.key, required this.documents});

  @override
  State<AnnualReportWidget> createState() => _AnnualReportWidgetState();
}

class _AnnualReportWidgetState extends State<AnnualReportWidget> {
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final yearDocs = widget.documents
        .where((doc) => doc['tax_year'] == _selectedYear)
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildYearSelector(),
          SizedBox(height: 3.h),
          _buildReportSummary(yearDocs),
          SizedBox(height: 3.h),
          _buildDocumentsList(yearDocs),
          SizedBox(height: 3.h),
          _buildExportButtons(),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - index);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Tax Year',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            children: years.map((year) {
              final isSelected = year == _selectedYear;
              return ChoiceChip(
                label: Text(year.toString()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedYear = year);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSummary(List<Map<String, dynamic>> yearDocs) {
    final totalDocs = yearDocs.length;
    final validDocs = yearDocs.where((d) => d['status'] == 'generated').length;
    final pendingDocs = yearDocs.where((d) => d['status'] == 'pending').length;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedYear Tax Summary',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total',
                totalDocs.toString(),
                Icons.description,
              ),
              _buildSummaryItem(
                'Valid',
                validDocs.toString(),
                Icons.check_circle,
              ),
              _buildSummaryItem(
                'Pending',
                pendingDocs.toString(),
                Icons.pending,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryLight, size: 8.w),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildDocumentsList(List<Map<String, dynamic>> yearDocs) {
    if (yearDocs.isEmpty) {
      return Center(
        child: Text(
          'No documents for $_selectedYear',
          style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondaryLight),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.h),
        ...yearDocs.map(
          (doc) => ListTile(
            leading: Icon(Icons.description, size: 6.w),
            title: Text(
              doc['document_type']
                      ?.toString()
                      .replaceAll('_', ' ')
                      .toUpperCase() ??
                  'Unknown',
              style: TextStyle(fontSize: 13.sp),
            ),
            subtitle: Text(
              doc['jurisdiction_code'] ?? 'N/A',
              style: TextStyle(fontSize: 11.sp),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.download),
            label: Text('Download Tax Package (PDF)'),
          ),
        ),
        SizedBox(height: 1.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.table_chart),
            label: Text('Export Earnings Breakdown (CSV)'),
          ),
        ),
      ],
    );
  }
}
