// src/navigation/MainTabNavigator.tsx
// Bottom tab navigator — shown when user is authenticated
// Matches the Flutter custom_bottom_bar.dart + social_media_navigation_hub pattern
import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { StyleSheet, Text, View } from 'react-native';
import { HomeFeedScreen } from '../screens/main/HomeFeedScreen';
import { ProfileScreen } from '../screens/main/ProfileScreen';
import { Routes } from './routes';
import { colors, typography } from '../config/theme';

// Placeholder screens for tabs not yet migrated
const PlaceholderScreen: React.FC<{ title: string; icon: string }> = ({
  title,
  icon,
}) => (
  <View style={placeholderStyles.container}>
    <Text style={placeholderStyles.icon}>{icon}</Text>
    <Text style={placeholderStyles.title}>{title}</Text>
    <Text style={placeholderStyles.subtitle}>Coming in Phase 2</Text>
  </View>
);

const VoteDashboardPlaceholder = () => (
  <PlaceholderScreen title="Vote Dashboard" icon="🗳️" />
);

import { MessagingListScreen } from '../screens/main/MessagingListScreen';

const Tab = createBottomTabNavigator();

export const MainTabNavigator: React.FC = () => {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarStyle: styles.tabBar,
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.textMuted,
        tabBarLabelStyle: styles.tabLabel,
      }}
    >
      <Tab.Screen
        name={Routes.HOME_FEED}
        component={HomeFeedScreen}
        options={{
          tabBarLabel: 'Home',
          tabBarIcon: ({ focused }) => (
            <Text style={[styles.tabIcon, focused && styles.tabIconActive]}>
              🏠
            </Text>
          ),
        }}
      />
      <Tab.Screen
        name={Routes.VOTE_DASHBOARD}
        component={VoteDashboardPlaceholder}
        options={{
          tabBarLabel: 'Vote',
          tabBarIcon: ({ focused }) => (
            <Text style={[styles.tabIcon, focused && styles.tabIconActive]}>
              🗳️
            </Text>
          ),
        }}
      />
      <Tab.Screen
        name={Routes.MESSAGING}
        component={MessagingListScreen}
        options={{
          tabBarLabel: 'Messages',
          tabBarIcon: ({ focused }) => (
            <Text style={[styles.tabIcon, focused && styles.tabIconActive]}>
              💬
            </Text>
          ),
        }}
      />
      <Tab.Screen
        name={Routes.PROFILE}
        component={ProfileScreen}
        options={{
          tabBarLabel: 'Profile',
          tabBarIcon: ({ focused }) => (
            <Text style={[styles.tabIcon, focused && styles.tabIconActive]}>
              👤
            </Text>
          ),
        }}
      />
    </Tab.Navigator>
  );
};

const styles = StyleSheet.create({
  tabBar: {
    backgroundColor: colors.surfaceDark,
    borderTopColor: colors.border,
    borderTopWidth: 1,
    paddingTop: 6,
    height: 60,
  },
  tabLabel: {
    ...typography.caption,
    marginBottom: 4,
  },
  tabIcon: {
    fontSize: 20,
    opacity: 0.5,
  },
  tabIconActive: {
    opacity: 1,
  },
});

const placeholderStyles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.backgroundDark,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 32,
  },
  icon: {
    fontSize: 48,
    marginBottom: 16,
  },
  title: {
    ...typography.h2,
    color: colors.textPrimary,
    marginBottom: 8,
  },
  subtitle: {
    ...typography.body,
    color: colors.textSecondary,
  },
});
