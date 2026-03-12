import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ContentRatioSlidersWidget extends StatelessWidget {
  final double electionPercentage;
  final double socialPercentage;
  final double adPercentage;
  final Function(String contentType, double value) onRatioChanged;
  final VoidCallback onSave;

  const ContentRatioSlidersWidget({
    super.key,
    required this.electionPercentage,
    required this.socialPercentage,
    required this.adPercentage,
    required this.onRatioChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = electionPercentage + socialPercentage + adPercentage;
    final isValid = (total - 100.0).abs() < 0.1;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Content Ratio Sliders',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isValid ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    'Total: ${total.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildSlider(
              context,
              'Election Content',
              electionPercentage,
              Colors.purple,
              Icons.how_to_vote,
              (value) => onRatioChanged('election', value),
            ),
            SizedBox(height: 2.h),
            _buildSlider(
              context,
              'Social Content',
              socialPercentage,
              Colors.blue,
              Icons.people,
              (value) => onRatioChanged('social', value),
            ),
            SizedBox(height: 2.h),
            _buildSlider(
              context,
              'Ad Content',
              adPercentage,
              Colors.green,
              Icons.ads_click,
              (value) => onRatioChanged('ad', value),
            ),
            SizedBox(height: 2.h),
            _buildDistributionPreview(context),
            SizedBox(height: 2.h),
            if (!isValid)
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Total must equal 100%. Adjust sliders.',
                        style: TextStyle(color: Colors.red, fontSize: 11.sp),
                      ),
                    ),
                  ],
                ),
              ),
            if (isValid) SizedBox(height: 2.h),
            if (isValid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  icon: Icon(Icons.save),
                  label: Text('Save Distribution'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context,
    String label,
    double value,
    Color color,
    IconData icon,
    Function(double) onChanged,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 2.w),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                '${value.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.3),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.2),
            trackHeight: 6.0,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribution Preview',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Row(
            children: [
              if (electionPercentage > 0)
                Expanded(
                  flex: electionPercentage.toInt(),
                  child: Container(height: 30, color: Colors.purple),
                ),
              if (socialPercentage > 0)
                Expanded(
                  flex: socialPercentage.toInt(),
                  child: Container(height: 30, color: Colors.blue),
                ),
              if (adPercentage > 0)
                Expanded(
                  flex: adPercentage.toInt(),
                  child: Container(height: 30, color: Colors.green),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
