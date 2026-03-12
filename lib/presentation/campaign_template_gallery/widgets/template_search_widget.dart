import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TemplateSearchWidget extends StatefulWidget {
  final Function(String) onSearchChanged;

  const TemplateSearchWidget({super.key, required this.onSearchChanged});

  @override
  State<TemplateSearchWidget> createState() => _TemplateSearchWidgetState();
}

class _TemplateSearchWidgetState extends State<TemplateSearchWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchController,
      onChanged: widget.onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search templates...',
        hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
        prefixIcon: Icon(Icons.search, size: 6.w, color: Colors.grey),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 5.w),
                onPressed: () {
                  _searchController.clear();
                  widget.onSearchChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      ),
    );
  }
}
