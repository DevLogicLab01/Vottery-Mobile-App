import React, { useEffect } from 'react';
import { Text, View } from 'react-native';
import { useAuth } from '../hooks/useAuth';

export const SplashScreen: React.FC = () => {
  const { initialize } = useAuth();

  useEffect(() => {
    console.log('[UI] SplashScreen Mounting (Safe Mode)...');
    initialize().catch(err => {
      console.error('[UI] Init Failed:', err.message);
    });
  }, []);

  return (
    <View style={{ flex: 1, backgroundColor: '#0F172A', alignItems: 'center', justifyContent: 'center' }}>
      <View style={{ width: 80, height: 80, borderRadius: 40, backgroundColor: '#6366F1', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
        <Text style={{ fontSize: 36, color: '#FFFFFF', fontWeight: 'bold' }}>V</Text>
      </View>
      <Text style={{ fontSize: 28, color: '#F8FAFC', fontWeight: 'bold' }}>Vottery [Live]</Text>
      <Text style={{ fontSize: 14, color: '#94A3B8', marginTop: 4 }}>Syncing with Database...</Text>
      <Text style={{ color: '#64748B', fontSize: 11, position: 'absolute', bottom: 32 }}>v1.0.0 (Safe Mode)</Text>
    </View>
  );
};
