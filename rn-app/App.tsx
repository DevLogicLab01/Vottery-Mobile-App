import React, { useState, useEffect } from 'react';
import { LogBox, View } from 'react-native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { useAuthStore } from './src/store/authStore';
import { SplashScreen } from './src/screens/SplashScreen';
import { SignInScreen } from './src/screens/auth/SignInScreen';
import { SignUpScreen } from './src/screens/auth/SignUpScreen';
import { MainTabNavigator } from './src/navigation/MainTabNavigator';
import { NavigationContainer } from '@react-navigation/native';

// Suppress non-critical RN logs in dev
LogBox.ignoreLogs(['In React 18', 'newArchEnabled', 'SafeAreaView has been deprecated']);

// React Query client — global instance
const queryClient = new QueryClient();

const AppHub: React.FC = () => {
  const { isInitialized, isAuthenticated, initialize } = useAuthStore();
  const [currentAuthScreen, setCurrentAuthScreen] = useState<'SignIn' | 'SignUp'>('SignIn');

  useEffect(() => {
    // Database handshake on start
    initialize();
  }, []);

  // ─── STAGE 1: Waking up the Database ─────────────────────────────────────
  if (!isInitialized) {
    return <SplashScreen />;
  }

  // ─── STAGE 2: If User is Logged In, Show the Content ─────────────────────
  if (isAuthenticated) {
    // Note: We use NavigationContainer here because MainTabNavigator is more complex,
    // but if it crashes, we'll safe-mode that next!
    return (
      <NavigationContainer>
        <MainTabNavigator />
      </NavigationContainer>
    );
  }

  // ─── STAGE 3: If User is Guest, Show the Auth Flow ────────────────────────
  return (
    <View style={{ flex: 1, backgroundColor: '#0F172A' }}>
      {currentAuthScreen === 'SignIn' ? (
        <SignInScreen 
          navigation={{ navigate: (target: string) => {
            if (target === 'SignUp') setCurrentAuthScreen('SignUp');
          }}} 
        />
      ) : (
        <SignUpScreen 
          onSwitchToSignIn={() => setCurrentAuthScreen('SignIn')} 
        />
      )}
    </View>
  );
};

const App: React.FC = () => {
  return (
    <SafeAreaProvider>
      <QueryClientProvider client={queryClient}>
        <AppHub />
      </QueryClientProvider>
    </SafeAreaProvider>
  );
};

export default App;
