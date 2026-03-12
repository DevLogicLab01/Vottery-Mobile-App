import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/ab_testing_service.dart';

class TestBuilderWidget extends StatefulWidget {
  final VoidCallback onExperimentCreated;

  const TestBuilderWidget({super.key, required this.onExperimentCreated});

  @override
  State<TestBuilderWidget> createState() => _TestBuilderWidgetState();
}

class _TestBuilderWidgetState extends State<TestBuilderWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _experimentType = 'election_layout';
  final List<Map<String, dynamic>> _variants = [
    {'name': 'Control', 'config': {}},
    {'name': 'Variant A', 'config': {}},
  ];
  final DateTime _startDate = DateTime.now();
  final DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addVariant() {
    if (_variants.length < 10) {
      setState(() {
        _variants.add({
          'name': 'Variant ${String.fromCharCode(65 + _variants.length - 1)}',
          'config': {},
        });
      });
    }
  }

  void _removeVariant(int index) {
    if (_variants.length > 2) {
      setState(() {
        _variants.removeAt(index);
      });
    }
  }

  Future<void> _createExperiment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final result = await ABTestingService.instance.createExperiment(
      name: _nameController.text,
      description: _descriptionController.text,
      experimentType: _experimentType,
      variants: _variants,
      startDate: _startDate,
      endDate: _endDate,
    );

    if (mounted) {
      setState(() => _isCreating = false);

      if (result?['success'] ?? false) {
        Navigator.pop(context);
        widget.onExperimentCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Experiment created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['message'] as String? ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: EdgeInsets.all(6.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),

            SizedBox(height: 3.h),

            // Title
            Text(
              'Create A/B Test',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 3.h),

            Expanded(
              child: ListView(
                children: [
                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Experiment Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 2.h),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),

                  SizedBox(height: 2.h),

                  // Experiment type
                  DropdownButtonFormField<String>(
                    initialValue: _experimentType,
                    decoration: const InputDecoration(
                      labelText: 'Experiment Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'election_layout',
                        child: Text('Election Layout'),
                      ),
                      DropdownMenuItem(
                        value: 'notification_timing',
                        child: Text('Notification Timing'),
                      ),
                      DropdownMenuItem(
                        value: 'creator_features',
                        child: Text('Creator Features'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _experimentType = value!);
                    },
                  ),

                  SizedBox(height: 3.h),

                  // Variants
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Variants (${_variants.length}/10)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: _variants.length < 10 ? _addVariant : null,
                        icon: const Icon(Icons.add_circle),
                      ),
                    ],
                  ),

                  SizedBox(height: 1.h),

                  ..._variants.asMap().entries.map((entry) {
                    final index = entry.key;
                    final variant = entry.value;

                    return Container(
                      margin: EdgeInsets.only(bottom: 1.h),
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              variant['name'] as String,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (index > 1)
                            IconButton(
                              onPressed: () => _removeVariant(index),
                              icon: const Icon(Icons.remove_circle_outline),
                              color: theme.colorScheme.error,
                            ),
                        ],
                      ),
                    );
                  }),

                  SizedBox(height: 2.h),

                  // Date range
                  Text(
                    'Duration',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 1.h),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Start: ${_startDate.day}/${_startDate.month}/${_startDate.year}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'End: ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.h),

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createExperiment,
                child: _isCreating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Text('Create Experiment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
