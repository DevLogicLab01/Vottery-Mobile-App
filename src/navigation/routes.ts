// src/navigation/routes.ts
// Route constants ported from Flutter app_routes.dart
// Only Phase 1 routes are active; others are listed for future migration.

export const Routes = {
  // Auth flow
  SPLASH: 'Splash',
  SIGN_IN: 'SignIn',
  SIGN_UP: 'SignUp',

  // Main app tabs
  HOME_FEED: 'HomeFeed',
  VOTE_DASHBOARD: 'VoteDashboard',
  CREATE_VOTE: 'CreateVote',
  MESSAGING: 'Messaging',
  PROFILE: 'Profile',

  // Social & Messaging (Phase 2)
  FEED_DETAIL: 'FeedDetail',
  MESSAGING_LIST: 'MessagingList',
  CONVERSATION: 'Conversation',

  // Nested stacks (future phases)
  VOTE_CASTING: 'VoteCasting',
  VOTE_RESULTS: 'VoteResults',
  VOTE_HISTORY: 'VoteHistory',
  VOTE_DISCOVERY: 'VoteDiscovery',
  SETTINGS: 'Settings',
  DIGITAL_WALLET: 'DigitalWallet',
  DIRECT_MESSAGING: 'DirectMessaging',
} as const;

export type RouteName = (typeof Routes)[keyof typeof Routes];
