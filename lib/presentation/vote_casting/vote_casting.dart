import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/abstention_service.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_voting_service.dart';
import '../../services/election_permission_service.dart';
import '../../services/mcq_service.dart';
import '../../services/offline_vote_service.dart';
import '../../services/video_watch_service.dart';
import '../../services/voting_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/biometric_confirmation_modal.dart';
import './widgets/disabled_comments_message_widget.dart';
import './widgets/election_comments_widget.dart';
import './widgets/real_time_vote_totals_widget.dart';
import './widgets/vote_info_card_widget.dart';
import './widgets/vote_option_widget.dart';

/// Vote Casting screen for secure vote submission with biometric authentication
/// Implements touch-optimized interface with real-time validation
class VoteCasting extends StatefulWidget {
  const VoteCasting({super.key});

  @override
  State<VoteCasting> createState() => _VoteCastingState();
}

class _VoteCastingState extends State<VoteCasting>
    with SingleTickerProviderStateMixin {
  // Vote data
  final Map<String, dynamic> voteData = {
    "id": "vote_001",
    "title": "Community Park Development Project",
    "description":
        "Vote to approve the proposed community park development project in the downtown area. This initiative includes new playground equipment, walking trails, and green spaces for residents.",
    "creator": {
      "name": "Sarah Johnson",
      "role": "City Council Member",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_14da91c34-1763294780479.png",
      "semanticLabel":
          "Professional headshot of a woman with shoulder-length brown hair wearing a navy blazer",
    },
    "deadline": DateTime.now().add(const Duration(days: 2, hours: 5)),
    "voteType": "single", // single or multi
    "maxSelections": 1,
    "resultsVisible": true,
    "isAnonymous": true,
    "options": [
      {
        "id": "opt_1",
        "title": "Approve Project",
        "description": "Support the full development plan with \$2.5M budget",
        "currentVotes": 1247,
        "percentage": 62.3,
      },
      {
        "id": "opt_2",
        "title": "Approve with Modifications",
        "description": "Support project with reduced budget of \$1.8M",
        "currentVotes": 523,
        "percentage": 26.2,
      },
      {
        "id": "opt_3",
        "title": "Reject Project",
        "description": "Do not proceed with the development",
        "currentVotes": 230,
        "percentage": 11.5,
      },
    ],
  };

  // State management
  Set<String> selectedOptions = {};
  bool isSubmitting = false;
  bool showSuccess = false;
  String? errorMessage;
  late AnimationController _successAnimationController;
  late Animation<double> _successAnimation;
  final OfflineVoteService _offlineService = OfflineVoteService.instance;
  bool _isOnline = true;
  int _pendingVotesCount = 0;

  final ElectionPermissionService _permissionService =
      ElectionPermissionService.instance;
  final BiometricVotingService _biometricService =
      BiometricVotingService.instance;
  final MCQService _mcqService = MCQService.instance;
  final VideoWatchService _videoWatchService = VideoWatchService.instance;

  bool _hasPermission = false;
  bool _checkingPermission = true;
  String? _permissionDeniedReason;
  bool _biometricRequired = false;
  bool _biometricVerified = false;

  // MCQ & Video requirements
  bool _requireMCQ = false;
  bool _mcqCompleted = false;
  bool _requireVideoWatch = false;
  bool _videoWatchCompleted = false;
  String _currentGate = 'permission'; // permission, mcq, video, vote

  String? _electionId;
  bool _initializedFromRoute = false;
  bool _authMethodBlocked = false;
  String _authMethodMessage = '';
  bool _abstained = false;
  bool _electionLoaded = false;
  bool _showContextualHelp = false;
  final AuthService _authService = AuthService.instance;
  final AbstentionService _abstentionService = AbstentionService.instance;

  @override
  void initState() {
    super.initState();
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _successAnimation = CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    );
    _listenToConnectivity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromRoute) return;
    _initializedFromRoute = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    String? electionId;

    if (args is String) {
      electionId = args;
    } else if (args is Map) {
      final dynamic fromMap = args['election_id'] ?? args['id'];
      if (fromMap is String) {
        electionId = fromMap;
      }
    }

    // Fallback to local demo ID if no argument is provided
    _electionId = electionId ?? (voteData['id'] as String);
    voteData['id'] = _electionId!;

    _checkConnectivity();
    _loadDraft();
    _loadElectionAndCheckAuth();
  }

  @override
  void dispose() {
    _successAnimationController.dispose();
    super.dispose();
  }

  bool get canSubmit =>
      _currentGate == 'vote' && selectedOptions.isNotEmpty && !isSubmitting;

  void _handleOptionSelection(String optionId) {
    setState(() {
      if (voteData["voteType"] == "single") {
        selectedOptions = {optionId};
      } else {
        if (selectedOptions.contains(optionId)) {
          selectedOptions.remove(optionId);
        } else {
          if (selectedOptions.length < (voteData["maxSelections"] as int)) {
            selectedOptions.add(optionId);
          } else {
            errorMessage =
                "Maximum ${voteData["maxSelections"]} selections allowed";
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() => errorMessage = null);
              }
            });
          }
        }
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final online = await _offlineService.isOnline();
    final pendingCount = await _offlineService.getPendingVotesCount();
    if (mounted) {
      setState(() {
        _isOnline = online;
        _pendingVotesCount = pendingCount;
      });
    }
  }

  void _listenToConnectivity() {
    _offlineService.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
        if (isOnline && _pendingVotesCount > 0) {
          _syncPendingVotes();
        }
      }
    });
  }

  Future<void> _loadDraft() async {
    final electionId = voteData['id'] as String;
    final draft = await _offlineService.getDraft(electionId);
    if (draft != null && mounted) {
      setState(() {
        if (draft['selected_option_id'] != null) {
          selectedOptions = {draft['selected_option_id']};
        } else if (draft['selected_options'] != null) {
          selectedOptions = Set<String>.from(draft['selected_options']);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Draft loaded'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveDraft() async {
    if (selectedOptions.isEmpty) return;

    final success = await _offlineService.saveDraft(
      electionId: voteData['id'] as String,
      electionTitle: voteData['title'] as String,
      selectedOptionId: voteData['voteType'] == 'single'
          ? selectedOptions.first
          : null,
      selectedOptions: voteData['voteType'] != 'single'
          ? selectedOptions.toList()
          : null,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Draft saved successfully'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _syncPendingVotes() async {
    final result = await _offlineService.syncPendingVotes();
    if (mounted && result['synced'] > 0) {
      setState(() => _pendingVotesCount = result['failed']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result['synced']} votes synced successfully'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Load election from API when id is a real UUID; then check permission and allowed auth.
  Future<void> _loadElectionAndCheckAuth() async {
    setState(() => _checkingPermission = true);
    final electionId = voteData['id'] as String;

    if (_isRealElectionId(electionId)) {
      final election = await VotingService.instance.getElectionById(electionId);
      if (election != null && mounted) {
        final options = await VotingService.instance.getElectionOptions(electionId);
        _applyElectionToVoteData(election, options);
        setState(() => _electionLoaded = true);
      }
    }

    await _checkVotingPermission();

    if (mounted && _authService.isAuthenticated) {
      final allowed = _getAllowedAuthMethods();
      if (allowed != null && allowed.isNotEmpty) {
        final current = await _authService.getCurrentAuthMethod();
        if (current != null && !allowed.contains(current)) {
          final labels = <String, String>{
            'email_password': 'Email & Password',
            'passkey': 'Passkey',
            'magic_link': 'Magic Link',
            'oauth': 'OAuth',
          };
          final allowedLabels = allowed.map((m) => labels[m] ?? m).join(', ');
          setState(() {
            _authMethodBlocked = true;
            _authMethodMessage =
                'This election only allows voting with: $allowedLabels. Please sign in with an allowed method.';
            _checkingPermission = false;
          });
          return;
        }
      }
    }
    if (mounted) setState(() => _checkingPermission = false);
  }

  bool _isRealElectionId(String id) =>
      id.length >= 30 || id.contains('-'); // UUID-like

  List<String>? _getAllowedAuthMethods() {
    final raw = voteData['allowed_auth_methods'] ?? voteData['allowedAuthMethods'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return null;
  }

  void _applyElectionToVoteData(
      Map<String, dynamic> election, List<Map<String, dynamic>> options) {
    voteData['title'] = election['title'] ?? voteData['title'];
    voteData['description'] = election['description'] ?? voteData['description'];
    voteData['allowed_auth_methods'] = election['allowed_auth_methods'];
    voteData['allowedAuthMethods'] = election['allowed_auth_methods'];
    voteData['require_mcq'] = election['require_mcq'] ?? election['mcq_required'];
    voteData['require_video_watch'] =
        election['require_video_watch'] ?? election['video_watch_required'];
    if (election['end_date'] != null && election['end_time'] != null) {
      try {
        voteData['deadline'] = DateTime.parse(
            '${election['end_date']}T${election['end_time']}');
      } catch (_) {}
    }
    if (options.isNotEmpty) {
      voteData['options'] = options.map((o) {
        return {
          'id': o['id'],
          'title': o['title'],
          'description': o['description'] ?? '',
          'currentVotes': o['vote_count'] ?? 0,
          'percentage': 0.0,
        };
      }).toList();
    }
  }

  Future<void> _checkVotingPermission() async {
    final electionId = voteData['id'] as String;

    // Check permission
    final permissionResult = await _permissionService.checkVotingPermission(
      electionId,
    );

    // Check if biometric required
    final biometricRequired = await _biometricService.isBiometricRequired(
      electionId,
    );

    // Check if MCQ required
    final mcqPassed = await _mcqService.hasPassedMCQ(electionId);

    // Check if video watch required
    final videoCompleted = await _videoWatchService.hasCompletedAllVideos(
      electionId,
    );

    if (mounted) {
      setState(() {
        _hasPermission = permissionResult['allowed'] as bool;
        _permissionDeniedReason = permissionResult['reason'] as String?;
        _biometricRequired = biometricRequired;
        _requireMCQ = (voteData['require_mcq'] ?? false) == true;
        _mcqCompleted = mcqPassed;
        _requireVideoWatch = (voteData['require_video_watch'] ?? false) == true;
        _videoWatchCompleted = videoCompleted;

        // Determine current gate
        if (!_hasPermission) {
          _currentGate = 'permission';
        } else if (_requireMCQ && !_mcqCompleted) {
          _currentGate = 'mcq';
        } else if (_requireVideoWatch && !_videoWatchCompleted) {
          _currentGate = 'video';
        } else {
          _currentGate = 'vote';
        }
      });
    }
  }

  Future<void> _recordAbstentionOnLeaveIfNeeded() async {
    if (_abstained || showSuccess) return;
    final electionId = voteData['id'] as String;
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    final hasVoted = await VotingService.instance.hasUserVoted(electionId);
    if (hasVoted) return;
    final already = await _abstentionService.hasAbstained(electionId, userId);
    if (already) return;
    await _abstentionService.recordAbstention(electionId, userId,
        source: 'viewed_no_vote');
  }

  Future<void> _handleAbstain() async {
    final electionId = voteData['id'] as String;
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    final res = await _abstentionService.recordAbstention(
        electionId, userId,
        source: 'explicit', reason: 'User chose to abstain');
    if (mounted && res.ok) {
      setState(() => _abstained = true);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Abstention recorded'),
          content: const Text(
            'You have chosen to abstain. Your choice has been recorded.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } else if (mounted && res.error != null) {
      setState(() => errorMessage = res.error);
    }
  }

  Future<void> _showBiometricConfirmation() async {
    if (!canSubmit) return;

    // Check permission first
    if (!_hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_permissionDeniedReason ?? 'Permission denied'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // If biometric required, authenticate first
    if (_biometricRequired && !_biometricVerified) {
      final authResult = await _biometricService.authenticateForVoting(
        voteData['id'] as String,
      );

      if (authResult['success'] != true) {
        if (mounted) {
          final attemptsRemaining = authResult['attemptsRemaining'] as int?;
          final message = attemptsRemaining != null && attemptsRemaining > 0
              ? '${authResult['reason']}. $attemptsRemaining attempts remaining.'
              : authResult['reason'] as String;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Mark as verified
      setState(() => _biometricVerified = true);
    }

    // Show confirmation modal
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BiometricConfirmationModal(
        voteTitle: voteData["title"] as String,
        selectedOptions: selectedOptions
            .map(
              (id) =>
                  (voteData["options"] as List).firstWhere(
                        (opt) => opt["id"] == id,
                      )["title"]
                      as String,
            )
            .toList(),
      ),
    );

    if (confirmed == true && mounted) {
      await _submitVote();
    }
  }

  Future<void> _submitVote() async {
    if (!canSubmit) return;

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      final selectedOption = selectedOptions.first;
      final result = await VotingService.instance.castVoteWithReceipt(
        electionId: voteData['id'],
        selectedOptionId: selectedOption,
      );

      if (result.success) {
        await _offlineService.deleteDraft(voteData['id'] as String);
        setState(() {
          showSuccess = true;
          isSubmitting = false;
        });
        _successAnimationController.forward();

        // Show VP reward notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Vote submitted! +10 VP earned'),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              duration: const Duration(seconds: 3),
            ),
          );

          // Show cryptographic receipt snippet for verification parity with Web
          final receipt = result.receipt;
          final voteHash = (receipt?['voteHash'] as String?) ?? '';
          if (voteHash.isNotEmpty) {
            final shortCode =
                voteHash.length > 12 ? '${voteHash.substring(0, 12)}…' : voteHash;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Your vote receipt: $shortCode'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        setState(() {
          isSubmitting = false;
          errorMessage =
              result.errorMessage ?? 'Failed to submit vote. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        isSubmitting = false;
        errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.inDays > 0) {
      return "${difference.inDays}d ${difference.inHours % 24}h remaining";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ${difference.inMinutes % 60}m remaining";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m remaining";
    } else {
      return "Expired";
    }
  }

  String _gateHelpText() {
    switch (_currentGate) {
      case 'permission':
        return 'Permission gate verifies eligibility, region/group access, and election participation policy.';
      case 'mcq':
        return 'MCQ gate requires a pre-vote quiz pass before ballots become selectable.';
      case 'video':
        return 'Video gate requires watch completion thresholds before vote submission is enabled.';
      case 'vote':
        return 'Vote gate allows option selection, secure biometric confirmation, and receipt-backed submission.';
      default:
        return 'This screen guides secure voting with policy and security checks before submission.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show loading while checking permission
    if (_checkingPermission) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Vote Casting',
          variant: CustomAppBarVariant.withBack,
          onBackPressed: () => Navigator.pop(context),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => setState(() => _showContextualHelp = !_showContextualHelp),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 2.h),
              Text(
                'Checking voting permissions...',
                style: TextStyle(fontSize: 13.sp),
              ),
            ],
          ),
        ),
      );
    }

    // Show auth method not allowed (parity with Web)
    if (_authMethodBlocked) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Vote Casting',
          variant: CustomAppBarVariant.withBack,
          onBackPressed: () => Navigator.pop(context),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => setState(() => _showContextualHelp = !_showContextualHelp),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined,
                    size: 20.w, color: theme.colorScheme.error),
                SizedBox(height: 3.h),
                Text(
                  'Authentication method not allowed',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),
                Text(
                  _authMethodMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4.h),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show permission denied message
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Vote Casting',
          variant: CustomAppBarVariant.withBack,
          onBackPressed: () => Navigator.pop(context),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => setState(() => _showContextualHelp = !_showContextualHelp),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 20.w, color: theme.colorScheme.error),
                SizedBox(height: 3.h),
                Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _permissionDeniedReason ??
                      'You do not have permission to vote in this election',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4.h),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (showSuccess) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Center(
          child: ScaleTransition(
            scale: _successAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'check',
                    color: theme.colorScheme.onPrimary,
                    size: 15.w,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Vote Submitted',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Your vote has been recorded securely',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_currentGate == 'mcq' || _currentGate == 'video') {
      final isMcqGate = _currentGate == 'mcq';
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Vote Casting',
          variant: CustomAppBarVariant.withBack,
          onBackPressed: () => Navigator.pop(context),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => setState(() => _showContextualHelp = !_showContextualHelp),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isMcqGate ? Icons.quiz_outlined : Icons.ondemand_video_outlined,
                  size: 20.w,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(height: 2.h),
                Text(
                  isMcqGate
                      ? 'Complete pre-vote quiz first'
                      : 'Complete required video watch first',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.5.h),
                Text(
                  'This election requires ${isMcqGate ? 'MCQ completion' : 'video completion'} before vote submission is enabled.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 3.h),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Cast Your Vote',
          variant: CustomAppBarVariant.withBack,
          onBackPressed: () async {
            await _recordAbstentionOnLeaveIfNeeded();
            if (mounted) Navigator.of(context).pop();
          },
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => setState(() => _showContextualHelp = !_showContextualHelp),
            ),
          ],
        ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_showContextualHelp)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.help_outline, color: theme.colorScheme.primary),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          _gateHelpText(),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vote info card
                      VoteInfoCardWidget(
                        title: voteData["title"] as String,
                        description: voteData["description"] as String,
                        creator: voteData["creator"] as Map<String, dynamic>,
                        deadline: voteData["deadline"] as DateTime,
                        isAnonymous: voteData["isAnonymous"] as bool,
                      ),

                      // Vote options
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Your Choice',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              voteData["voteType"] == "single"
                                  ? 'Choose one option'
                                  : 'Choose up to ${voteData["maxSelections"]} options',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            ...(voteData["options"] as List).map((option) {
                              return VoteOptionWidget(
                                option: option as Map<String, dynamic>,
                                isSelected: selectedOptions.contains(
                                  option["id"],
                                ),
                                isSingleSelect:
                                    voteData["voteType"] == "single",
                                showResults: voteData["resultsVisible"] as bool,
                                onTap: () => _handleOptionSelection(
                                  option["id"] as String,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      // Real-time vote totals (if visible)
                      SizedBox(height: 2.h),
                      RealTimeVoteTotalsWidget(
                        electionId: voteData['id'] as String,
                        isCreator: false,
                      ),

                      // Comments section (conditional on comments_enabled / allow_comments — same as Web)
                      if ((voteData['comments_enabled'] ?? voteData['allow_comments'] ?? true) == true)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.h,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Comments',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 1.h),
                              ElectionCommentsWidget(
                                electionId: voteData['id'] as String,
                              ),
                            ],
                          ),
                        )
                      else
                        const DisabledCommentsMessageWidget(),

                      // Security indicators
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(2.w),
                            border: Border.all(
                              color: theme.colorScheme.tertiary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'verified_user',
                                color: theme.colorScheme.tertiary,
                                size: 6.w,
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Secure Voting',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      'End-to-end encrypted • Biometric verified • Anonymous',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Error message
          if (errorMessage != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: EdgeInsets.all(4.w),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'error_outline',
                      color: theme.colorScheme.onError,
                      size: 6.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onError,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 7.h,
                      child: ElevatedButton(
                        onPressed: canSubmit
                            ? _showBiometricConfirmation
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          disabledBackgroundColor: theme
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2.w),
                          ),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: 6.w,
                                height: 6.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'fingerprint',
                                    color: theme.colorScheme.onPrimary,
                                    size: 6.w,
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    'Submit Vote',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 1.5.h),
                    TextButton(
                      onPressed: isSubmitting ? null : _handleAbstain,
                      child: Text(
                        'I abstain from voting',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.5.h),
                    // Save draft button
                    SizedBox(
                      width: double.infinity,
                      height: 6.h,
                      child: OutlinedButton(
                        onPressed: selectedOptions.isNotEmpty
                            ? _saveDraft
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(
                            color: selectedOptions.isNotEmpty
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.3,
                                  ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2.w),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'save',
                              color: selectedOptions.isNotEmpty
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.3),
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Save Draft',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: selectedOptions.isNotEmpty
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
