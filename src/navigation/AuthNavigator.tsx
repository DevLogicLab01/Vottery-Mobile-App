import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import { SignInScreen } from '../screens/auth/SignInScreen';
import { SignUpScreen } from '../screens/auth/SignUpScreen';
import { Routes } from './routes';

const Stack = createStackNavigator();

export const AuthNavigator: React.FC = () => {
  return (
    <Stack.Navigator
      screenOptions={{
        headerShown: false,
      }}
    >
      <Stack.Screen name={Routes.SIGN_IN} component={SignInScreen} />
      <Stack.Screen name={Routes.SIGN_UP} component={SignUpScreen} />
    </Stack.Navigator>
  );
};
