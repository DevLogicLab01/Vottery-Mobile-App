import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/load_testing/production_load_test_service.dart';

class LoadTestControlPanelWidget extends StatelessWidget {
  final int selectedTierIndex;
  final bool isRunning;
  final bool testWebSocket;
  final bool testBlockchain;
  final bool testDatabase;
  final bool testApi;
  final String progressMessage;
  final ValueChanged<int> onTierChanged;
  final ValueChanged<bool> onWebSocketToggle;
  final ValueChanged<bool> onBlockchainToggle;
  final ValueChanged<bool> onDatabaseToggle;
  final ValueChanged<bool> onApiToggle;
  final VoidCallback onRunTest;

  const LoadTestControlPanelWidget({
    super.key,
    required this.selectedTierIndex,
    required this.isRunning,
    required this.testWebSocket,
    required this.testBlockchain,
    required this.testDatabase,
    required this.testApi,
    required this.progressMessage,
    required this.onTierChanged,
    required this.onWebSocketToggle,
    required this.onBlockchainToggle,
    required this.onDatabaseToggle,
    required this.onApiToggle,
    required this.onRunTest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Load Tier',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      constraints: const BoxConstraints(minHeight: 44),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedTierIndex,
                          isExpanded: true,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.black87,
                          ),
                          items: List.generate(
                            ProductionLoadTestService.userLoadTiers.length,
                            (i) => DropdownMenuItem(
                              value: i,
                              child: Text(
                                ProductionLoadTestService.formatTierLabel(i),
                              ),
                            ),
                          ),
                          onChanged: isRunning
                              ? null
                              : (v) => onTierChanged(v ?? 0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              ElevatedButton.icon(
                onPressed: isRunning ? null : onRunTest,
                icon: isRunning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow, size: 18),
                label: Text(
                  isRunning ? 'Running...' : 'Start Load Test',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            children: [
              _buildToggleChip('WebSocket', testWebSocket, onWebSocketToggle),
              _buildToggleChip(
                'Blockchain',
                testBlockchain,
                onBlockchainToggle,
              ),
              _buildToggleChip('Database', testDatabase, onDatabaseToggle),
              _buildToggleChip('API', testApi, onApiToggle),
            ],
          ),
          if (progressMessage.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withAlpha(13),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withAlpha(51),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Color(0xFF6C63FF),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      progressMessage,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF6C63FF),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Divider(color: Colors.grey.shade200, height: 1.h),
        ],
      ),
    );
  }

  Widget _buildToggleChip(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: value ? Colors.white : Colors.grey.shade700,
        ),
      ),
      selected: value,
      onSelected: isRunning ? null : onChanged,
      selectedColor: const Color(0xFF6C63FF),
      backgroundColor: Colors.grey.shade100,
      checkmarkColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
      minimumSize: const Size(44, 44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
