import 'package:flutter/material.dart';

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
  int currentIndex = 0;
  bool _isLoading = false;
  final List<dynamic> _activeVotes = [];

  @override
  void initState() {
    super.initState();
    _loadVotes();
  }

  Future<void> _loadVotes() async {
    setState(() => _isLoading = true);
    // TODO: Implement vote loading logic
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  // ALL CustomBottomBar routes in EXACT order matching CustomBottomBar items
  final List<String> routes = [
    '/vote-dashboard', // Dashboard tab - index 0
    '/vote-history', // History tab - index 1
    '/user-profile', // Profile tab - index 2
  ];

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'VoteDashboard',
      onRetry: _loadVotes,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Vote Dashboard')),
        body: _isLoading
            ? const SkeletonList(itemCount: 6)
            : _activeVotes.isEmpty
            ? NoActiveVotesEmptyState(
                onCreateVote: () {
                  Navigator.pushNamed(context, '/create-vote');
                },
                onExploreVotes: () {
                  Navigator.pushNamed(context, '/vote-discovery');
                },
              )
            : RefreshIndicator(
                onRefresh: _loadVotes,
                child: ListView.builder(
                  itemCount: _activeVotes.length,
                  itemBuilder: (context, index) {
                    final vote = _activeVotes[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: vote.color,
                        child: const Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(vote.title),
                      subtitle: Text(vote.description),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/vote-discovery',
                          arguments: vote,
                        );
                      },
                    );
                  },
                ),
              ),
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
            ).pushNamed('/vote-discovery');
          },
          icon: const Icon(Icons.explore),
          label: const Text('Discover'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}