import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ImageOptionBuilderWidget extends StatelessWidget {
  final int optionIndex;
  final Map<String, dynamic> option;
  final bool isCorrectAnswer;
  final Function(String) onTextChanged;
  final Function(String) onAltTextChanged;
  final VoidCallback onImagePick;
  final VoidCallback onRemove;
  final VoidCallback onSetCorrect;

  const ImageOptionBuilderWidget({
    super.key,
    required this.optionIndex,
    required this.option,
    required this.isCorrectAnswer,
    required this.onTextChanged,
    required this.onAltTextChanged,
    required this.onImagePick,
    required this.onRemove,
    required this.onSetCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = option['image_url'];
    final hasImage = imageUrl != null && imageUrl.toString().isNotEmpty;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: isCorrectAnswer ? 3 : 1,
      color: isCorrectAnswer
          ? AppTheme.accentLight.withAlpha(26)
          : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: isCorrectAnswer,
                  onChanged: (_) => onSetCorrect(),
                  activeColor: AppTheme.accentLight,
                ),
                Expanded(
                  child: Text(
                    'Option ${optionIndex + 1}',
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isCorrectAnswer
                          ? AppTheme.accentLight
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                ),
                if (isCorrectAnswer)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      'Correct',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(width: 2.w),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 5.w),
                  onPressed: onRemove,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            TextField(
              decoration: InputDecoration(
                labelText: 'Option Text',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              controller: TextEditingController(text: option['text']),
              onChanged: onTextChanged,
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onImagePick,
                    icon: Icon(
                      hasImage ? Icons.help_outline : Icons.add_photo_alternate,
                      size: 5.w,
                    ),
                    label: Text(hasImage ? 'Change Image' : 'Add Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasImage
                          ? AppTheme.accentLight
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (hasImage) ...[
              SizedBox(height: 1.h),
              Container(
                height: 20.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: kIsWeb
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(Icons.broken_image, size: 10.w),
                            );
                          },
                        )
                      : Image.file(
                          File(imageUrl),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(Icons.broken_image, size: 10.w),
                            );
                          },
                        ),
                ),
              ),
              SizedBox(height: 1.h),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Alt Text (Accessibility)',
                  hintText: 'Describe the image for screen readers',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: Icon(Icons.accessibility, size: 5.w),
                ),
                controller: TextEditingController(text: option['alt_text']),
                onChanged: onAltTextChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
