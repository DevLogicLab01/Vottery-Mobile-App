import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/advanced_settings_section_widget.dart';
import './widgets/basic_info_section_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/vote_options_section_widget.dart';

/// Create Vote Screen
/// Enables vote creators to build new voting campaigns with mobile-optimized form inputs
class CreateVote extends StatefulWidget {
  const CreateVote({super.key});

  @override
  State<CreateVote> createState() => _CreateVoteState();
}

class _CreateVoteState extends State<CreateVote> {
  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  // Form validation errors
  String? _titleError;
  String? _descriptionError;
  final List<String?> _optionErrors = [null, null];

  // Settings state
  DateTime? _selectedDeadline;
  bool _anonymousVoting = false;
  bool _realTimeResults = true;
  bool _multiSelect = false;
  String _voterRestriction = 'none';
  String _resultVisibility = 'public';

  // UI state
  bool _isPublishing = false;
  bool _hasUnsavedChanges = false;
  DateTime? _lastAutoSave;

  @override
  void initState() {
    super.initState();
    _setupAutoSave();
    _setupChangeListeners();
  }

  void _setupAutoSave() {
    Future.delayed(const Duration(seconds: 30), _autoSaveDraft);
  }

  void _setupChangeListeners() {
    _titleController.addListener(() {
      setState(() {
        _hasUnsavedChanges = true;
        _titleError = null;
      });
    });
    _descriptionController.addListener(() {
      setState(() {
        _hasUnsavedChanges = true;
        _descriptionError = null;
      });
    });
  }

  Future<void> _autoSaveDraft() async {
    if (!mounted) return;
    if (_hasUnsavedChanges && _titleController.text.isNotEmpty) {
      await _saveDraft(showMessage: false);
      setState(() {
        _lastAutoSave = DateTime.now();
      });
    }
    if (mounted) {
      Future.delayed(const Duration(seconds: 30), _autoSaveDraft);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _validateForm() {
    bool isValid = true;

    setState(() {
      if (_titleController.text.trim().isEmpty) {
        _titleError = 'Title is required';
        isValid = false;
      } else if (_titleController.text.trim().length < 5) {
        _titleError = 'Title must be at least 5 characters';
        isValid = false;
      }

      if (_descriptionController.text.trim().isEmpty) {
        _descriptionError = 'Description is required';
        isValid = false;
      } else if (_descriptionController.text.trim().length < 10) {
        _descriptionError = 'Description must be at least 10 characters';
        isValid = false;
      }

      for (int i = 0; i < _optionControllers.length; i++) {
        if (_optionControllers[i].text.trim().isEmpty) {
          if (i < _optionErrors.length) {
            _optionErrors[i] = 'Option ${i + 1} is required';
          } else {
            _optionErrors.add('Option ${i + 1} is required');
          }
          isValid = false;
        } else {
          if (i < _optionErrors.length) {
            _optionErrors[i] = null;
          }
        }
      }

      if (_selectedDeadline == null) {
        isValid = false;
      } else if (_selectedDeadline!.isBefore(DateTime.now())) {
        isValid = false;
      }
    });

    return isValid;
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        _optionControllers.add(TextEditingController());
        _optionErrors.add(null);
        _hasUnsavedChanges = true;
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
        if (index < _optionErrors.length) {
          _optionErrors.removeAt(index);
        }
        _hasUnsavedChanges = true;
      });
    }
  }

  void _reorderOption(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final controller = _optionControllers.removeAt(oldIndex);
      _optionControllers.insert(newIndex, controller);

      if (oldIndex < _optionErrors.length && newIndex < _optionErrors.length) {
        final error = _optionErrors.removeAt(oldIndex);
        _optionErrors.insert(newIndex, error);
      }
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _selectDeadline() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _hasUnsavedChanges = true;
        });
      }
    }
  }

  Future<void> _showPreview() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix all errors before previewing'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PreviewModal(
        title: _titleController.text,
        description: _descriptionController.text,
        options: _optionControllers.map((c) => c.text).toList(),
        deadline: _selectedDeadline!,
        anonymousVoting: _anonymousVoting,
        realTimeResults: _realTimeResults,
        multiSelect: _multiSelect,
      ),
    );
  }

  Future<void> _saveDraft({bool showMessage = true}) async {
    setState(() => _hasUnsavedChanges = false);

    if (showMessage && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CustomIconWidget(
                iconName: 'check_circle',
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text('Draft saved successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _publishVote() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isPublishing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CustomIconWidget(
                iconName: 'check_circle',
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text('Vote published successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed(AppRoutes.voteDashboard);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unsaved Changes'),
        content: Text(
          'You have unsaved changes. Do you want to save as draft before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Discard'),
          ),
          TextButton(
            onPressed: () async {
              await _saveDraft();
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text('Save Draft'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFormValid =
        _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _optionControllers.every((c) => c.text.trim().isNotEmpty) &&
        _selectedDeadline != null;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: ErrorBoundaryWrapper(
        screenName: 'CreateVote',
        child: Scaffold(
          appBar: CustomAppBar(
            title: 'Create Vote',
            variant: CustomAppBarVariant.withBack,
            onBackPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
            actions: [
              TextButton(
                onPressed: _saveDraft,
                child: Text(
                  'Save Draft',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 4.w,
                  right: 4.w,
                  top: 2.h,
                  bottom: 12.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_lastAutoSave != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'cloud_done',
                              color: const Color(0xFF10B981),
                              size: 16,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Last saved: ${_lastAutoSave!.hour}:${_lastAutoSave!.minute.toString().padLeft(2, '0')}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_lastAutoSave != null) SizedBox(height: 2.h),
                    BasicInfoSectionWidget(
                      titleController: _titleController,
                      descriptionController: _descriptionController,
                      titleError: _titleError,
                      descriptionError: _descriptionError,
                    ),
                    SizedBox(height: 2.h),
                    VoteOptionsSectionWidget(
                      optionControllers: _optionControllers,
                      onAddOption: _addOption,
                      onRemoveOption: _removeOption,
                      onReorderOption: _reorderOption,
                      optionErrors: _optionErrors,
                    ),
                    SizedBox(height: 2.h),
                    SettingsSectionWidget(
                      selectedDeadline: _selectedDeadline,
                      onSelectDeadline: _selectDeadline,
                      anonymousVoting: _anonymousVoting,
                      onAnonymousChanged: (val) => setState(() {
                        _anonymousVoting = val;
                        _hasUnsavedChanges = true;
                      }),
                      realTimeResults: _realTimeResults,
                      onRealTimeResultsChanged: (val) => setState(() {
                        _realTimeResults = val;
                        _hasUnsavedChanges = true;
                      }),
                      multiSelect: _multiSelect,
                      onMultiSelectChanged: (val) => setState(() {
                        _multiSelect = val;
                        _hasUnsavedChanges = true;
                      }),
                    ),
                    SizedBox(height: 2.h),
                    AdvancedSettingsSectionWidget(
                      selectedRestriction: _voterRestriction,
                      onRestrictionChanged: (val) => setState(() {
                        _voterRestriction = val;
                        _hasUnsavedChanges = true;
                      }),
                      selectedVisibility: _resultVisibility,
                      onVisibilityChanged: (val) => setState(() {
                        _resultVisibility = val;
                        _hasUnsavedChanges = true;
                      }),
                    ),
                    SizedBox(height: 2.h),
                    OutlinedButton.icon(
                      onPressed: _showPreview,
                      icon: CustomIconWidget(
                        iconName: 'visibility',
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      label: Text('Preview Vote'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 6.h),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: isFormValid && !_isPublishing
                          ? _publishVote
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 6.h),
                      ),
                      child: _isPublishing
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text('Publish Vote'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewModal extends StatelessWidget {
  final String title;
  final String description;
  final List<String> options;
  final DateTime deadline;
  final bool anonymousVoting;
  final bool realTimeResults;
  final bool multiSelect;

  const _PreviewModal({
    required this.title,
    required this.description,
    required this.options,
    required this.deadline,
    required this.anonymousVoting,
    required this.realTimeResults,
    required this.multiSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vote Preview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'schedule',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Ends: ${deadline.month}/${deadline.day}/${deadline.year} ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    multiSelect
                        ? 'Select one or more options:'
                        : 'Select one option:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  ...options.asMap().entries.map((entry) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 1.h),
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: multiSelect
                                ? 'check_box_outline_blank'
                                : 'radio_button_unchecked',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 2.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: [
                      if (anonymousVoting)
                        Chip(
                          avatar: CustomIconWidget(
                            iconName: 'visibility_off',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          label: Text('Anonymous'),
                        ),
                      if (realTimeResults)
                        Chip(
                          avatar: CustomIconWidget(
                            iconName: 'show_chart',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          label: Text('Live Results'),
                        ),
                      if (multiSelect)
                        Chip(
                          avatar: CustomIconWidget(
                            iconName: 'check_box',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          label: Text('Multiple Choice'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
