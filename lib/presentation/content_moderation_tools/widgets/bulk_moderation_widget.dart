import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class BulkModerationWidget extends StatefulWidget {
  final VoidCallback onComplete;

  const BulkModerationWidget({super.key, required this.onComplete});

  @override
  State<BulkModerationWidget> createState() => _BulkModerationWidgetState();
}

class _BulkModerationWidgetState extends State<BulkModerationWidget> {
  String _selectedAction = 'approve';
  final Set<String> _selectedItems = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          _buildActionSelector(context),
          Expanded(child: _buildItemList(context)),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'checklist',
            color: theme.colorScheme.primary,
            size: 24,
          ),
          SizedBox(width: 2.w),
          Text(
            'Bulk Moderation',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'close',
              color: theme.textTheme.bodyMedium?.color ?? Colors.black,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Action',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildActionChip(
                  'approve',
                  'Approve All',
                  'check_circle',
                  const Color(0xFF10B981),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildActionChip(
                  'remove',
                  'Remove All',
                  'delete',
                  const Color(0xFFEF4444),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildActionChip(
                  'escalate',
                  'Escalate All',
                  'arrow_upward',
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(
    String value,
    String label,
    String iconName,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedAction == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedAction = value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: isSelected ? color : theme.disabledColor,
              size: 24,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? color : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: 5,
      itemBuilder: (context, index) {
        final itemId = 'item_$index';
        final isSelected = _selectedItems.contains(itemId);

        return Container(
          margin: EdgeInsets.only(bottom: 1.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedItems.add(itemId);
                } else {
                  _selectedItems.remove(itemId);
                }
              });
            },
            title: Text(
              'Content item ${index + 1}',
              style: theme.textTheme.bodyMedium,
            ),
            subtitle: Text(
              'Risk score: ${70 + index * 5}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _selectedItems.isEmpty ? null : _handleBulkAction,
              child: Text('Apply to ${_selectedItems.length} items'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBulkAction() {
    Navigator.pop(context);
    widget.onComplete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bulk action "$_selectedAction" applied to ${_selectedItems.length} items',
        ),
      ),
    );
  }
}
