import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

/// Text sticker editor for Moments
class TextStickerEditorWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onStickerAdded;
  final VoidCallback onClose;

  const TextStickerEditorWidget({
    super.key,
    required this.onStickerAdded,
    required this.onClose,
  });

  @override
  State<TextStickerEditorWidget> createState() =>
      _TextStickerEditorWidgetState();
}

class _TextStickerEditorWidgetState extends State<TextStickerEditorWidget> {
  final TextEditingController _textController = TextEditingController();
  Color _selectedColor = Colors.white;
  double _fontSize = 16.0;

  static const List<Color> _colors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.green,
    Colors.purple,
    Colors.orange,
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(220),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Text Sticker',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onClose,
              ),
            ],
          ),
          TextField(
            controller: _textController,
            style: GoogleFonts.inter(
              color: _selectedColor,
              fontSize: _fontSize.sp,
            ),
            decoration: InputDecoration(
              hintText: 'Enter text...',
              hintStyle: GoogleFonts.inter(color: Colors.white.withAlpha(100)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Colors.white.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Colors.white.withAlpha(100)),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // Color picker
          Row(
            children: [
              Text(
                'Color: ',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 11.sp),
              ),
              ..._colors.map(
                (color) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    margin: EdgeInsets.only(right: 1.5.w),
                    width: 7.w,
                    height: 7.w,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color
                            ? Colors.yellow
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          // Font size
          Row(
            children: [
              Text(
                'Size: ',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 11.sp),
              ),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 12.0,
                  max: 36.0,
                  activeColor: AppTheme.primaryLight,
                  inactiveColor: Colors.white.withAlpha(50),
                  onChanged: (v) => setState(() => _fontSize = v),
                ),
              ),
              Text(
                '${_fontSize.toInt()}',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 11.sp),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_textController.text.trim().isNotEmpty) {
                  widget.onStickerAdded({
                    'text': _textController.text.trim(),
                    'color': _selectedColor.value,
                    'fontSize': _fontSize,
                    'x': 0.5,
                    'y': 0.5,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
              child: Text(
                'Add Sticker',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
