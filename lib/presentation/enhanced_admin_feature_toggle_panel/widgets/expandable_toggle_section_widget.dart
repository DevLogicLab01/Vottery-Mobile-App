import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpandableToggleSectionWidget extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final List<Map<String, dynamic>> toggles;
  final Function(String, bool) onToggleChanged;
  final VoidCallback onEnableAll;
  final VoidCallback onDisableAll;

  const ExpandableToggleSectionWidget({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.toggles,
    required this.onToggleChanged,
    required this.onEnableAll,
    required this.onDisableAll,
  });

  @override
  State<ExpandableToggleSectionWidget> createState() =>
      _ExpandableToggleSectionWidgetState();
}

class _ExpandableToggleSectionWidgetState
    extends State<ExpandableToggleSectionWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  int get _enabledCount =>
      widget.toggles.where((t) => t['is_enabled'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(1.5.w),
                    decoration: BoxDecoration(
                      color: widget.categoryColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      widget.categoryIcon,
                      color: widget.categoryColor,
                      size: 16.sp,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.categoryName,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          '$_enabledCount/${widget.toggles.length} enabled',
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isExpanded) ...[
                    TextButton(
                      onPressed: widget.onEnableAll,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'All On',
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onDisableAll,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'All Off',
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: Colors.red[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 1.w),
                  ],
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[400],
                      size: 18.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                Divider(height: 1, color: Colors.grey[200]),
                ...widget.toggles.map(
                  (toggle) => _ToggleItem(
                    toggle: toggle,
                    onChanged: (val) => widget.onToggleChanged(
                      toggle['toggle_name'] as String,
                      val,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final Map<String, dynamic> toggle;
  final ValueChanged<bool> onChanged;
  const _ToggleItem({required this.toggle, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isEnabled = toggle['is_enabled'] as bool? ?? false;
    final isCritical = toggle['is_critical'] as bool? ?? false;
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0),
      title: Row(
        children: [
          Expanded(
            child: Text(
              toggle['display_name'] as String? ??
                  toggle['toggle_name'] as String? ??
                  '',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
          if (isCritical)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                'CRITICAL',
                style: GoogleFonts.inter(
                  fontSize: 7.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.red[600],
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        toggle['description'] as String? ?? '',
        style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey[500]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      value: isEnabled,
      activeThumbColor: Colors.blue[600],
      onChanged: (val) {
        if (isCritical && !val) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Disable Critical Feature?'),
              content: Text(
                'Disabling "${toggle['display_name']}" may impact core platform functionality. Are you sure?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onChanged(val);
                  },
                  child: const Text(
                    'Disable',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        } else {
          onChanged(val);
        }
      },
    );
  }
}
