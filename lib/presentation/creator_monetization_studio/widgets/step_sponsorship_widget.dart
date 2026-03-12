import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class StepSponsorshipWidget extends StatelessWidget {
  final String selectedTier;
  const StepSponsorshipWidget({super.key, required this.selectedTier});

  @override
  Widget build(BuildContext context) {
    final isPremium = selectedTier == 'Gold' || selectedTier == 'Platinum';
    final sponsorships = [
      _SponsorshipData(
        'VoteNation Media',
        'Election Coverage Campaign',
        '\$150/campaign',
        'bronze',
        true,
      ),
      _SponsorshipData(
        'CivicTech Inc',
        'Democracy Awareness Drive',
        '\$300/campaign',
        'silver',
        true,
      ),
      _SponsorshipData(
        'PoliticsNow',
        'Premium Election Series',
        '\$800/campaign',
        'gold',
        isPremium,
      ),
      _SponsorshipData(
        'GlobalVote Corp',
        'International Elections',
        '\$2,000/campaign',
        'platinum',
        selectedTier == 'Platinum',
      ),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sponsorship Opportunities',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Connect with brands that match your audience',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withAlpha(13),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color(0xFF6C63FF).withAlpha(51)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFF6C63FF),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Your $selectedTier tier unlocks ${isPremium ? 'premium' : 'basic'} sponsorships',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          ...sponsorships.map((s) => _buildSponsorshipCard(s)),
        ],
      ),
    );
  }

  Widget _buildSponsorshipCard(_SponsorshipData s) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: s.isEligible ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: s.isEligible ? Colors.grey.shade200 : Colors.grey.shade300,
        ),
        boxShadow: s.isEligible
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.business,
                  size: 20,
                  color: Color(0xFF6C63FF),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.brandName,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: s.isEligible
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      s.campaignTitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    s.payoutAmount,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: s.isEligible
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.shade400,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 1.5.w,
                      vertical: 0.2.h,
                    ),
                    decoration: BoxDecoration(
                      color: _tierColor(s.requiredTier).withAlpha(26),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      s.requiredTier.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: _tierColor(s.requiredTier),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (s.isEligible) ...[
            SizedBox(height: 1.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF6C63FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                ),
                child: Text(
                  'Apply Now',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: 0.5.h),
            Text(
              'Upgrade to ${s.requiredTier} tier to unlock',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'gold':
        return const Color(0xFFFFB300);
      case 'platinum':
        return const Color(0xFF6C63FF);
      case 'silver':
        return Colors.grey.shade600;
      default:
        return Colors.brown;
    }
  }
}

class _SponsorshipData {
  final String brandName;
  final String campaignTitle;
  final String payoutAmount;
  final String requiredTier;
  final bool isEligible;
  _SponsorshipData(
    this.brandName,
    this.campaignTitle,
    this.payoutAmount,
    this.requiredTier,
    this.isEligible,
  );
}
