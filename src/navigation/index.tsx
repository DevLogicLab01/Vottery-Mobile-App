// src/navigation/index.tsx
// Root navigator — handles auth vs main routing
// Matches the Flutter onGenerateRoute pattern in main.dart
import React, { useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { SplashScreen } from '../screens/SplashScreen';
import { AuthNavigator } from './AuthNavigator';
import { MainTabNavigator } from './MainTabNavigator';
import { FeedDetailScreen } from '../screens/main/FeedDetailScreen';
import { ConversationScreen } from '../screens/main/ConversationScreen';
import { useAuth } from '../hooks/useAuth';
import { useAuthStore } from '../store/authStore';
import { authService } from '../services/auth';
import { Routes } from './routes';
import { colors } from '../config/theme';

const RootStack = createNativeStackNavigator();

export const AppNavigator: React.FC = () => {
  const { isAuthenticated, isInitialized } = useAuth();

  console.log(`[NAV] Current State - Initialized: ${isInitialized} | Authenticated: ${isAuthenticated}`);

  // Subscribe to Supabase auth state changes
  useEffect(() => {
    console.log('[NAV] Setting up Auth State listener...');
    const { data: subscription } = authService.onAuthStateChange(
      (_event, session) => {
        console.log(`[NAV] Auth Event: ${_event} | User: ${session?.user?.id ?? 'none'}`);
        // Keep Zustand store in sync with Supabase session changes
        const store = useAuthStore.getState();
        store.setSession(session);
        if (session?.user) {
          store.loadProfile();
        }
      },
    );

    return () => {
      console.log('[NAV] Unsubscribing from Auth State listener');
      subscription?.subscription.unsubscribe();
    };
  }, []);

  return (
    <NavigationContainer
      onReady={() => console.log('[NAV] NavigationContainer is READY')}
    >
      <RootStack.Navigator screenOptions={{ headerShown: false }}>
        {!isInitialized ? (
          <RootStack.Screen name={Routes.SPLASH} component={SplashScreen} />
        ) : isAuthenticated ? (
          <>
            <RootStack.Screen name="Main" component={MainTabNavigator} />
            <RootStack.Screen name={Routes.FEED_DETAIL} component={FeedDetailScreen} />
            <RootStack.Screen name={Routes.CONVERSATION} component={ConversationScreen} />
          </>
        ) : (
          <RootStack.Screen name="Auth" component={AuthNavigator} />
        )}
      </RootStack.Navigator>
    </NavigationContainer>
  );
};
