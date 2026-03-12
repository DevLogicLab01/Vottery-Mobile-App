import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class NonMonetaryPrizeFormWidget extends StatefulWidget {
  final String title;
  final String description;
  final double value;
  final List<String> imageUrls;
  final Function(Map<String, dynamic>) onDataChanged;

  const NonMonetaryPrizeFormWidget({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.imageUrls,
    required this.onDataChanged,
  });

  @override
  State<NonMonetaryPrizeFormWidget> createState() =>
      _NonMonetaryPrizeFormWidgetState();
}

class _NonMonetaryPrizeFormWidgetState
    extends State<NonMonetaryPrizeFormWidget> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _valueController;
  late List<String> _imageUrls;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _descriptionController = TextEditingController(text: widget.description);
    _valueController = TextEditingController(
      text: widget.value > 0 ? widget.value.toStringAsFixed(2) : '',
    );
    _imageUrls = List.from(widget.imageUrls);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onDataChanged({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'value': double.tryParse(_valueController.text) ?? 0.0,
      'imageUrls': _imageUrls,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Non-Monetary Prize Details',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Prize Title',
              hintText: 'e.g., One week Dubai holiday',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (_) => _notifyChange(),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Prize Description',
              hintText: 'Detailed description of the prize',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (_) => _notifyChange(),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Estimated Value (USD)',
              hintText: 'Approximate monetary value',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixText: '\$ ',
            ),
            onChanged: (_) => _notifyChange(),
          ),
          SizedBox(height: 2.h),
          Text(
            'Prize Images',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Text(
            'Add image URLs to showcase the prize',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
