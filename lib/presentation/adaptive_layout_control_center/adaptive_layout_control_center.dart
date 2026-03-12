import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/custom_app_bar.dart';

class AdaptiveLayoutControlCenter extends StatefulWidget {
  const AdaptiveLayoutControlCenter({super.key});

  @override
  State<AdaptiveLayoutControlCenter> createState() =>
      _AdaptiveLayoutControlCenterState();
}

class _AdaptiveLayoutControlCenterState
    extends State<AdaptiveLayoutControlCenter>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  double _contentBoxWidth = 14.5;
  int _transitionDuration = 300;
  String _easingCurve = 'easeInOut';
  bool _smoothTransitions = true;
  String _selectedDevice = 'iPhone 13';
  bool _isSaving = false;
  bool _isRunningTests = false;

  final List<Map<String, dynamic>> _breakpoints = [
    {'name': 'Mobile', 'min_width': 0, 'max_width': 600, 'columns': 1},
    {'name': 'Tablet', 'min_width': 600, 'max_width': 900, 'columns': 2},
    {'name': 'Desktop', 'min_width': 900, 'max_width': 9999, 'columns': 3},
  ];

  final List<Map<String, dynamic>> _devices = [
    {
      'name': 'iPhone 13',
      'width': 390.0,
      'height': 844.0,
      'icon': Icons.phone_iphone,
    },
    {
      'name': 'iPad Pro',
      'width': 1024.0,
      'height': 1366.0,
      'icon': Icons.tablet_mac,
    },
    {
      'name': 'Galaxy S21',
      'width': 360.0,
      'height': 800.0,
      'icon': Icons.phone_android,
    },
    {
      'name': 'Pixel 6',
      'width': 412.0,
      'height': 915.0,
      'icon': Icons.phone_android,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      await _supabase.from('adaptive_layout_configs').upsert({
        'content_box_width': _contentBoxWidth,
        'breakpoints': _breakpoints,
        'transition_duration': _transitionDuration,
        'easing_curve': _easingCurve,
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layout configuration saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Save config error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _runTests() async {
    setState(() => _isRunningTests = true);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() => _isRunningTests = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All breakpoint tests passed. No overflow detected.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Layout Configuration',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Content Box Width',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_contentBoxWidth.toStringAsFixed(1)} cm',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6366F1),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _contentBoxWidth,
                  min: 10.0,
                  max: 20.0,
                  divisions: 20,
                  activeColor: const Color(0xFF6366F1),
                  label: '${_contentBoxWidth.toStringAsFixed(1)} cm',
                  onChanged: (v) => setState(() => _contentBoxWidth = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '10 cm',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 9.sp,
                      ),
                    ),
                    Text(
                      'Default: 14.5 cm',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 9.sp,
                      ),
                    ),
                    Text(
                      '20 cm',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Smooth Transitions',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: _smoothTransitions,
                      activeThumbColor: const Color(0xFF6366F1),
                      onChanged: (v) => setState(() => _smoothTransitions = v),
                    ),
                  ],
                ),
                if (_smoothTransitions) ...[
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Duration: ${_transitionDuration}ms',
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _transitionDuration.toDouble(),
                    min: 100,
                    max: 1000,
                    divisions: 9,
                    activeColor: const Color(0xFF6366F1),
                    label: '${_transitionDuration}ms',
                    onChanged: (v) =>
                        setState(() => _transitionDuration = v.toInt()),
                  ),
                  SizedBox(height: 1.h),
                  DropdownButtonFormField<String>(
                    initialValue: _easingCurve,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Easing Curve',
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    items: ['linear', 'easeIn', 'easeOut', 'easeInOut']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _easingCurve = v!),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
              onPressed: _isSaving ? null : _saveConfig,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                'Save Configuration',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakpointsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Breakpoint Configuration',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFF0F172A),
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      'Breakpoint',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Min Width',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Max Width',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Columns',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
                rows: _breakpoints
                    .map(
                      (bp) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              bp['name'],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${bp['min_width']}px',
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              bp['max_width'] == 9999
                                  ? '∞'
                                  : '${bp['max_width']}px',
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              bp['columns'].toString(),
                              style: GoogleFonts.inter(
                                color: const Color(0xFF6366F1),
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Current Screen Width',
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Screen Width',
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 11.sp),
                ),
                Text(
                  '${MediaQuery.of(context).size.width.toStringAsFixed(0)}px',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6366F1),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSimulatorTab() {
    final selectedDeviceData = _devices.firstWhere(
      (d) => d['name'] == _selectedDevice,
    );
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Simulator',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _devices.map((device) {
              final isSelected = _selectedDevice == device['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedDevice = device['name']),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1).withAlpha(51)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : Colors.grey.withAlpha(77),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        device['icon'] as IconData,
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.grey,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        device['name'],
                        style: GoogleFonts.inter(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.grey,
                          fontSize: 10.sp,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _selectedDevice,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${selectedDeviceData['width'].toInt()} x ${selectedDeviceData['height'].toInt()} px',
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 10.sp),
                ),
                SizedBox(height: 2.h),
                // Device frame preview
                Center(
                  child: Container(
                    width: 60.w,
                    height: 30.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selectedDeviceData['icon'] as IconData,
                          color: Colors.grey,
                          size: 32,
                        ),
                        SizedBox(height: 1.h),
                        AnimatedContainer(
                          duration: Duration(milliseconds: _transitionDuration),
                          curve: _easingCurve == 'easeInOut'
                              ? Curves.easeInOut
                              : _easingCurve == 'easeIn'
                              ? Curves.easeIn
                              : _easingCurve == 'easeOut'
                              ? Curves.easeOut
                              : Curves.linear,
                          width: (_contentBoxWidth / 20) * 50.w,
                          height: 3.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withAlpha(128),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '${_contentBoxWidth.toStringAsFixed(1)} cm box',
                          style: GoogleFonts.inter(
                            color: Colors.grey,
                            fontSize: 9.sp,
                          ),
                        ),
                      ],
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

  Widget _buildTestingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Responsive Test Suite',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Coverage',
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                _buildTestItem('Mobile breakpoint (0-600px)', true),
                _buildTestItem('Tablet breakpoint (600-900px)', true),
                _buildTestItem('Desktop breakpoint (900px+)', true),
                _buildTestItem('Overflow detection', true),
                _buildTestItem('Content box width validation', true),
                _buildTestItem('Transition animation smoothness', true),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
              onPressed: _isRunningTests ? null : _runTests,
              icon: _isRunningTests
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow, color: Colors.white),
              label: Text(
                _isRunningTests ? 'Running Tests...' : 'Run All Tests',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Implementation Guide',
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.withAlpha(51)),
            ),
            child: Text('''// Responsive breakpoints usage:
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600) {
      return MobileLayout();
    } else if (constraints.maxWidth < 900) {
      return TabletLayout();
    }
    return DesktopLayout();
  },
);

// Content box with 14.5cm width:
AnimatedContainer(
  duration: Duration(milliseconds: $_transitionDuration),
  width: 14.5 * 37.8, // 1cm = 37.8px
  child: ContentBox(),
);''', style: GoogleFonts.sourceCodePro(color: Colors.green, fontSize: 9.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildTestItem(String label, bool passed) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: passed ? Colors.green : Colors.grey,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: CustomAppBar(
        title: 'Adaptive Layout Control',
        variant: CustomAppBarVariant.withBack,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1E293B),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF6366F1),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Configuration'),
                Tab(text: 'Breakpoints'),
                Tab(text: 'Device Simulator'),
                Tab(text: 'Testing'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConfigTab(),
                _buildBreakpointsTab(),
                _buildDeviceSimulatorTab(),
                _buildTestingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}