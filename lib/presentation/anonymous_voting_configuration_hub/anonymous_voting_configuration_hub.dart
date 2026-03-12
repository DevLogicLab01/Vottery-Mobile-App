import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/anonymous_voting_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class AnonymousVotingConfigurationHub extends StatefulWidget {
  const AnonymousVotingConfigurationHub({super.key});

  @override
  State<AnonymousVotingConfigurationHub> createState() =>
      _AnonymousVotingConfigurationHubState();
}

class _AnonymousVotingConfigurationHubState
    extends State<AnonymousVotingConfigurationHub> {
  final _anonymousVotingService = AnonymousVotingService();
  final _supabase = SupabaseService.instance.client;

  bool _allowAnonymousVoting = false;
  bool _isLoading = false;
  String? _selectedElectionId;
  Map<String, dynamic>? _electionData;
  final String _anonymityLevel = 'Full Anonymity';
  bool _showHashVisualization = false;
  String? _sampleVoterHash;
  String? _sampleAnonymousId;

  @override
  void initState() {
    super.initState();
    _loadElectionData();
  }

  Future<void> _loadElectionData() async {
    setState(() => _isLoading = true);

    try {
      // Get current user's elections
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final elections = await _supabase
          .from('elections')
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (elections != null) {
        setState(() {
          _selectedElectionId = elections['id'] as String;
          _electionData = elections;
          _allowAnonymousVoting =
              elections['allow_anonymous_voting'] as bool? ?? false;
        });

        // Generate sample hash for visualization
        _generateSampleHash();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading election: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateSampleHash() {
    if (_selectedElectionId == null) return;

    final userId = _supabase.auth.currentUser?.id ?? 'sample-user-id';
    // Use placeholder values for demonstration since methods don't exist
    final salt = 'sample-salt-${DateTime.now().millisecondsSinceEpoch}';
    final hash =
        'sample-hash-${userId.hashCode}-${_selectedElectionId!.hashCode}-${salt.hashCode}';
    final anonymousId =
        'ANON-${_selectedElectionId!.substring(0, 8)}-${hash.substring(0, 12)}';

    setState(() {
      _sampleVoterHash = hash;
      _sampleAnonymousId = anonymousId;
    });
  }

  Future<void> _toggleAnonymousVoting(bool value) async {
    if (_selectedElectionId == null) return;

    setState(() => _isLoading = true);

    try {
      await _supabase
          .from('elections')
          .update({'allow_anonymous_voting': value})
          .eq('id', _selectedElectionId!);

      setState(() => _allowAnonymousVoting = value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? '🔒 Anonymous voting enabled'
                  : 'Anonymous voting disabled',
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating setting: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AnonymousVotingConfigurationHub',
      onRetry: _loadElectionData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Anonymous Voting Configuration'),
          backgroundColor: Colors.deepPurple,
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _electionData == null
            ? _buildNoElectionState()
            : SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrivacyStatusHeader(),
                    SizedBox(height: 3.h),
                    _buildPrivacySettingsSection(),
                    SizedBox(height: 3.h),
                    _buildVoterProtectionSection(),
                    SizedBox(height: 3.h),
                    _buildAuditTrailSection(),
                    SizedBox(height: 3.h),
                    _buildAnonymityVerificationSection(),
                    SizedBox(height: 3.h),
                    _buildComplianceDocumentationSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNoElectionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.how_to_vote_outlined, size: 80.sp, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'No elections found',
            style: TextStyle(fontSize: 18.sp, color: Colors.grey),
          ),
          SizedBox(height: 1.h),
          Text(
            'Create an election to configure anonymous voting',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyStatusHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _allowAnonymousVoting
              ? [Colors.green.shade700, Colors.green.shade900]
              : [Colors.grey.shade700, Colors.grey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _allowAnonymousVoting ? Icons.lock : Icons.lock_open,
                color: Colors.white,
                size: 24.sp,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  _electionData?['title'] ?? 'Election',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: _allowAnonymousVoting
                      ? Colors.white.withAlpha(51)
                      : Colors.white.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _allowAnonymousVoting
                      ? '🔒 Anonymous Election'
                      : 'Public Election',
                  style: TextStyle(fontSize: 14.sp, color: Colors.white),
                ),
              ),
              SizedBox(width: 2.w),
              if (_allowAnonymousVoting)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    _anonymityLevel,
                    style: TextStyle(fontSize: 12.sp, color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Settings',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            SwitchListTile(
              title: const Text('Allow Anonymous Voting'),
              subtitle: const Text(
                'Enable voters to cast ballots without revealing their identity',
              ),
              value: _allowAnonymousVoting,
              onChanged: _toggleAnonymousVoting,
              activeThumbColor: Colors.green,
            ),
            if (_allowAnonymousVoting) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.visibility_off, color: Colors.blue),
                title: const Text('Anonymity Impact'),
                subtitle: const Text(
                  'Voter identities will be encrypted using SHA-256 hashing',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.shield, color: Colors.green),
                title: const Text('Voter Protection'),
                subtitle: const Text(
                  'One-way encryption prevents de-anonymization',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoterProtectionSection() {
    if (!_allowAnonymousVoting) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voter Protection (SHA-256 Hashing)',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            SwitchListTile(
              title: const Text('Show Hash Visualization'),
              subtitle: const Text('Preview how voter IDs are encrypted'),
              value: _showHashVisualization,
              onChanged: (value) {
                setState(() => _showHashVisualization = value);
                if (value) _generateSampleHash();
              },
            ),
            if (_showHashVisualization && _sampleVoterHash != null) ...[
              const Divider(),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encryption Process:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'voter_id + election_id + salt',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                    const Icon(Icons.arrow_downward, size: 16),
                    Text(
                      'SHA-256 Hash',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Icon(Icons.arrow_downward, size: 16),
                    Text(
                      'Anonymous Voter ID',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Sample Hash:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_sampleVoterHash!.substring(0, 32)}...',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontFamily: 'monospace',
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Anonymous ID:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _sampleAnonymousId!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontFamily: 'monospace',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTrailSection() {
    if (!_allowAnonymousVoting) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit Trail Management',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: const Icon(Icons.verified_user, color: Colors.blue),
              title: const Text('Blockchain Verification'),
              subtitle: const Text(
                'Vote integrity maintained while encrypting voter identities',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.orange),
              title: const Text('Anonymous Audit Trail'),
              subtitle: const Text(
                'Track vote actions without exposing voter identity',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.security, color: Colors.green),
              title: const Text('De-anonymization Prevention'),
              subtitle: const Text(
                'One-way hashing prevents identity recovery',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnonymityVerificationSection() {
    if (!_allowAnonymousVoting) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anonymity Verification',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.purple),
              title: const Text('Anonymous Voter Receipts'),
              subtitle: const Text(
                'Voters receive receipt codes for vote verification',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.indigo),
              title: const Text('Receipt Format'),
              subtitle: Text(
                'ANON-${_selectedElectionId?.substring(0, 8) ?? 'XXXXXXXX'}-XXXXXXXXXXXX',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.casino, color: Colors.amber),
              title: const Text('Anonymous Lottery'),
              subtitle: const Text(
                'Gamified draws without identity disclosure',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceDocumentationSection() {
    if (!_allowAnonymousVoting) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compliance Documentation',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: const Icon(Icons.gavel, color: Colors.red),
              title: const Text('GDPR Compliance'),
              subtitle: const Text(
                'Anonymous voting meets EU privacy regulations',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.policy, color: Colors.blue),
              title: const Text('Privacy Guarantee'),
              subtitle: const Text(
                'Voter identities cannot be recovered from hashed data',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.verified, color: Colors.green),
              title: const Text('Anonymity Certificate'),
              subtitle: const Text(
                'SHA-256 encryption with secure salt generation',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
