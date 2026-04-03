import React, { useState } from 'react';
import { StyleSheet, Text, View, TextInput, Pressable, ActivityIndicator, Keyboard, Alert } from 'react-native';
import { useAuth } from '../../hooks/useAuth';

interface Props {
  onSwitchToSignIn: () => void;
}

export const SignUpScreen: React.FC<Props> = ({ onSwitchToSignIn }) => {
  const { signUp, isLoading, error, clearError } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');

  const handleSignUp = async () => {
    if (!email || !password || !fullName) {
      console.warn('[UI] All fields required');
      return;
    }
    Keyboard.dismiss();
    clearError();
    try {
      console.log('[UI] Attempting sign-up for:', email);
      await signUp(email.trim(), password, fullName.trim());
    } catch (err: any) {
      console.error('[UI] Sign-up failed:', err.message);
    }
  };

  return (
    <View style={{ flex: 1, backgroundColor: '#0F172A', padding: 20, justifyContent: 'center' }}>
      <Text style={{ fontSize: 32, color: '#FFFFFF', fontWeight: 'bold', marginBottom: 10 }}>Create Account</Text>
      <Text style={{ fontSize: 16, color: '#94A3B8', marginBottom: 30 }}>Join Vottery to start voting</Text>

      {/* Error banner */}
      {error && (
        <View style={{ backgroundColor: 'rgba(239, 68, 68, 0.15)', padding: 12, borderRadius: 8, marginBottom: 20 }}>
          <Text style={{ color: '#EF4444', fontSize: 14 }}>{error}</Text>
        </View>
      )}

      <View style={{ marginBottom: 15 }}>
        <Text style={{ color: '#94A3B8', marginBottom: 5 }}>Full Name</Text>
        <TextInput
          style={{ height: 50, backgroundColor: '#1E293B', borderRadius: 8, color: '#FFFFFF', paddingHorizontal: 15 }}
          placeholder="John Doe"
          placeholderTextColor="#64748B"
          value={fullName}
          onChangeText={setFullName}
        />
      </View>

      <View style={{ marginBottom: 15 }}>
        <Text style={{ color: '#94A3B8', marginBottom: 5 }}>Email</Text>
        <TextInput
          style={{ height: 50, backgroundColor: '#1E293B', borderRadius: 8, color: '#FFFFFF', paddingHorizontal: 15 }}
          placeholder="you@example.com"
          placeholderTextColor="#64748B"
          autoCapitalize="none"
          keyboardType="email-address"
          value={email}
          onChangeText={setEmail}
        />
      </View>

      <View style={{ marginBottom: 30 }}>
        <Text style={{ color: '#94A3B8', marginBottom: 5 }}>Password</Text>
        <TextInput
          style={{ height: 50, backgroundColor: '#1E293B', borderRadius: 8, color: '#FFFFFF', paddingHorizontal: 15 }}
          placeholder="Password"
          placeholderTextColor="#64748B"
          secureTextEntry
          value={password}
          onChangeText={setPassword}
        />
      </View>

      <Pressable 
        onPress={handleSignUp}
        disabled={isLoading}
        style={({ pressed }) => ({
          height: 50,
          backgroundColor: '#6366F1',
          borderRadius: 8,
          alignItems: 'center',
          justifyContent: 'center',
          opacity: (pressed || isLoading) ? 0.7 : 1
        })}
      >
        {isLoading ? (
          <ActivityIndicator color="#FFFFFF" />
        ) : (
          <Text style={{ color: '#FFFFFF', fontSize: 16, fontWeight: 'bold' }}>Sign Up</Text>
        )}
      </Pressable>

      <View style={{ flexDirection: 'row', justifyContent: 'center', marginTop: 20 }}>
        <Text style={{ color: '#94A3B8' }}>Already have an account? </Text>
        <Pressable onPress={onSwitchToSignIn}>
          <Text style={{ color: '#6366F1', fontWeight: 'bold' }}>Sign In</Text>
        </Pressable>
      </View>
    </View>
  );
};
