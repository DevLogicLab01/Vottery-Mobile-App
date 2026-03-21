import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/voting_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

class VoteDashboard extends StatefulWidget {
  const VoteDashboard({super.key});

  @override
  VoteDashboardState createState() => VoteDashboardState();
}

class VoteDashboardState extends State<VoteDashboard> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final VotingService _votingService = VotingService.instance;
  int currentIndex = 0;
  bool _isLoading = false;
  bool _showContextualHelp = false;
  List<Map<String, dynamic>> _activeVotes = [];

  @override
  void initState() {
    super.initState();
    _loadVotes();
  }

  Future<void> _loadVotes() async {
    setState(() => _isLoading = true);
    try {
      final activeVotes = await _votingService.getElections(
        status: 'active',
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _activeVotes = activeVotes;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ALL CustomBottomBar routes in EXACT order matching CustomBottomBar items
  final List<String> routes = [
    AppRoutes.voteDashboard, // Dashboard tab - index 0
    AppRoutes.voteHistory, // History tab - index 1
    AppRoutes.userProfile, // Profile tab - index 2
  ];

  @override
  Widget build(BuildContext context) {
    final helpText = _activeVotes.isEmpty
        ? 'No active votes yet. Use Create Vote to launch a new election or Discover to join available votes.'
        : 'Tap a vote to open details and continue to secure vote casting. Pull down to refresh active elections.';

    return ErrorBoundaryWrapper(
      screenName: 'VoteDashboard',
      onRetry: _loadVotes,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Vote Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                setState(() => _showContextualHelp = !_showContextualHelp);
              },
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 6)
            : _activeVotes.isEmpty
            ? NoActiveVotesEmptyState(
                onCreateVote: () {
                  Navigator.pushNamed(context, AppRoutes.createVote);
                },
                onExploreVotes: () {
                  Navigator.pushNamed(context, AppRoutes.voteDiscovery);
                },
              )
            : RefreshIndicator(
                onRefresh: _loadVotes,
                child: ListView.builder(
                  itemCount: _activeVotes.length,
                  itemBuilder: (context, index) {
                    final vote = _activeVotes[index];
                    final title =
                        vote['title']?.toString() ?? 'Untitled Election';
                    final description = vote['description']?.toString() ??
                        'No description available';
                    final accent = Theme.of(context).colorScheme.primary;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: accent,
                        child: const Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(title),
                      subtitle: Text(description),
                      onTap: () {
                        if (_showContextualHelp) {
                          setState(() {});
                        }
                        Navigator.pushNamed(
                          context,
                          AppRoutes.voteDiscovery,
                          arguments: {
                            'electionId': vote['id'],
                            'title': title,
                            'description': description,
                            ...vote,
                          },
                        );
                      },
                    );
                  },
                ),
              ),
        bottomSheet: _showContextualHelp
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.25),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        helpText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )
            : null,
        bottomNavigationBar: CustomBottomBar(
          currentIndex: currentIndex,
          onTap: (index) {
            // Remove the check for routes existence since AppRoutes doesn't have a 'routes' getter
            if (currentIndex != index) {
              setState(() => currentIndex = index);
              navigatorKey.currentState?.pushReplacementNamed(routes[index]);
            }
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamed(AppRoutes.voteDiscovery);
          },
          icon: const Icon(Icons.explore),
          label: const Text('Discover'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}