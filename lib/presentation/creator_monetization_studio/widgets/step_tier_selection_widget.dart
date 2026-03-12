import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class StepTierSelectionWidget extends StatelessWidget {
  final String selectedTier;
  final ValueChanged<String> onTierSelected;

  const StepTierSelectionWidget({
    super.key,
    required this.selectedTier,
    required this.onTierSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tiers = [
      _TierData('Bronze', '\$0/mo', Colors.brown, [
        'Basic analytics',
        'VP earnings',
        'Community access',
      ], false),
      _TierData('Silver', '\$9.99/mo', Colors.grey.shade600, [
        'All Bronze features',
        'Priority support',
        'Advanced analytics',
      ], false),
      _TierData('Gold', '\$24.99/mo', const Color(0xFFFFB300), [
        'All Silver features',
        'Brand sponsorships',
        'Revenue boost 2.5x',
      ], true),
      _TierData('Platinum', '\$49.99/mo', const Color(0xFF6C63FF), [
        'All Gold features',
        'Premium brands',
        'Revenue boost 4x',
        'Dedicated manager',
      ], false),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Tier',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Select the plan that fits your goals',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 2.h),
          ...tiers.map((tier) => _buildTierCard(tier)),
        ],
      ),
    );
  }

  Widget _buildTierCard(_TierData tier) {
    final isSelected = selectedTier == tier.name;
    return GestureDetector(
      onTap: () => onTierSelected(tier.name),
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected ? tier.color.withAlpha(13) : Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? tier.color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: tier.color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(Icons.star, color: tier.color, size: 20),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tier.name,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          if (tier.isRecommended) ...[
                            SizedBox(width: 2.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 1.5.w,
                                vertical: 0.2.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                'Recommended',
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        tier.price,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: tier.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: tier.color, size: 24)
                else
                  Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
              ],
            ),
            SizedBox(height: 1.h),
            ...tier.benefits.map(
              (b) => Padding(
                padding: EdgeInsets.symmetric(vertical: 0.3.h),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 14, color: tier.color),
                    SizedBox(width: 2.w),
                    Text(
                      b,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierData {
  final String name;
  final String price;
  final Color color;
  final List<String> benefits;
  final bool isRecommended;
  _TierData(
    this.name,
    this.price,
    this.color,
    this.benefits,
    this.isRecommended,
  );
}
