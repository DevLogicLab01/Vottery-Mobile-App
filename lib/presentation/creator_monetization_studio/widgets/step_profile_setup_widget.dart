import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class StepProfileSetupWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController bioController;
  final Set<String> selectedCategories;
  final ValueChanged<String> onCategoryToggle;

  const StepProfileSetupWidget({
    super.key,
    required this.nameController,
    required this.bioController,
    required this.selectedCategories,
    required this.onCategoryToggle,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ['Politics', 'Entertainment', 'Sports', 'Technology'];
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Up Your Profile',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Tell the world who you are',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 3.h),
          // Avatar upload placeholder
          Center(
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withAlpha(26),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withAlpha(77),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          _buildLabel('Creator Name *'),
          SizedBox(height: 0.5.h),
          TextField(
            controller: nameController,
            decoration: _inputDecoration('Enter your creator name'),
            style: GoogleFonts.inter(fontSize: 13.sp),
          ),
          SizedBox(height: 2.h),
          _buildLabel('Bio * (max 500 characters)'),
          SizedBox(height: 0.5.h),
          TextField(
            controller: bioController,
            maxLength: 500,
            maxLines: 4,
            decoration: _inputDecoration(
              'Tell your audience about yourself...',
            ),
            style: GoogleFonts.inter(fontSize: 13.sp),
          ),
          SizedBox(height: 2.h),
          _buildLabel('Content Categories'),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: categories.map((cat) => _buildCategoryChip(cat)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 12.sp,
        color: Colors.grey.shade400,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Color(0xFF6C63FF)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = selectedCategories.contains(category);
    return GestureDetector(
      onTap: () => onCategoryToggle(category),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          category,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
