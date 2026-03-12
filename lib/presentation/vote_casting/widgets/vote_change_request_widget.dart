import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/vote_change_service.dart';

class VoteChangeRequestWidget extends StatefulWidget {
  final String electionId;
  final String voterId;
  final Map<String, dynamic> currentVoteData;

  const VoteChangeRequestWidget({
    super.key,
    required this.electionId,
    required this.voterId,
    required this.currentVoteData,
  });

  @override
  State<VoteChangeRequestWidget> createState() =>
      _VoteChangeRequestWidgetState();
}

class _VoteChangeRequestWidgetState extends State<VoteChangeRequestWidget> {
  final _voteChangeService = VoteChangeService();
  final _reasonController = TextEditingController();

  bool _isLoading = false;
  bool _changeAllowed = false;

  @override
  void initState() {
    super.initState();
    _checkChangePermission();
  }

  Future<void> _checkChangePermission() async {
    final allowed = await _voteChangeService.isVoteChangeAllowed(
      widget.electionId,
    );
    setState(() => _changeAllowed = allowed);
  }

  Future<void> _requestVoteChange(Map<String, dynamic> newVoteData) async {
    setState(() => _isLoading = true);

    try {
      final result = await _voteChangeService.requestVoteChange(
        electionId: widget.electionId,
        voterId: widget.voterId,
        originalVoteData: widget.currentVoteData,
        newVoteData: newVoteData,
        changeReason: _reasonController.text,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Vote change request submitted'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to submit request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_changeAllowed) {
      return Container(
        padding: EdgeInsets.all(3.w),
        margin: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.lock, color: Colors.orange.shade700, size: 20.sp),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Vote changes are not allowed for this election',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      margin: EdgeInsets.symmetric(vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, color: Colors.blue.shade700, size: 24.sp),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Request Vote Change',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'You can request to change your vote. The election creator will review your request.',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: 'Reason for change (optional)',
              hintText: 'Explain why you want to change your vote',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      // TODO: Show vote selection dialog
                      // For now, just show a placeholder
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Select your new vote first'),
                        ),
                      );
                    },
              icon: _isLoading
                  ? SizedBox(
                      width: 16.sp,
                      height: 16.sp,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isLoading ? 'Submitting...' : 'Submit Change Request',
                style: TextStyle(fontSize: 13.sp),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
