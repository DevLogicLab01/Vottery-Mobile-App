// src/screens/main/ProfileScreen.tsx
// User profile screen — Phase 2 revision
import React from 'react';
import { Alert, Pressable, StyleSheet, Text, View } from 'react-native';
import { ScreenContainer } from '../../components/ui';
import { useAuth } from '../../hooks/useAuth';
import { colors, typography, spacing, borderRadius } from '../../config/theme';
import { Routes } from '../../navigation/routes';

interface Props {
  navigation: any;
}

export const ProfileScreen: React.FC<Props> = ({ navigation }) => {
  const { user, profile, signOut } = useAuth();

  const handleSignOut = () => {
    Alert.alert('Sign Out', 'Are you sure you want to sign out?', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Sign Out', style: 'destructive', onPress: () => signOut() },
    ]);
  };

  const displayName = profile?.full_name ?? user?.user_metadata?.full_name ?? 'User';
  const initial = (displayName?.charAt(0) ?? 'U').toUpperCase();

  return (
    <ScreenContainer scrollable padded>
      <View style={styles.profileHeader}>
        <View style={styles.avatarLarge}>
          <Text style={styles.avatarLargeText}>{initial}</Text>
        </View>
        <Text style={styles.displayName}>{displayName}</Text>
        <Text style={styles.email}>{user?.email}</Text>
        <View style={styles.roleBadge}>
          <Text style={styles.roleText}>{(profile?.role ?? 'User').toUpperCase()}</Text>
        </View>
      </View>

      <View style={styles.statsContainer}>
        <StatCard label="Votes" value="0" />
        <StatCard label="Elections" value="0" />
        <StatCard label="VP" value="100" />
      </View>

      <View style={styles.menuSection}>
        <Text style={styles.sectionTitle}>Account</Text>
        <MenuItem icon="👤" label="Edit Profile" onPress={() => {}} />
        <MenuItem icon="💬" label="Messages" onPress={() => navigation.navigate(Routes.MESSAGING)} />
        <MenuItem icon="🔔" label="Notifications" onPress={() => {}} />
      </View>

      <View style={styles.menuSection}>
        <Text style={styles.sectionTitle}>Settings</Text>
        <MenuItem icon="🔒" label="Privacy & Security" onPress={() => {}} />
        <MenuItem icon="🎨" label="Theme Preferences" onPress={() => {}} />
        <MenuItem icon="❓" label="Help & FAQ" onPress={() => {}} />
      </View>

      <Pressable onPress={handleSignOut} style={styles.signOutBtn}>
        <Text style={styles.signOutText}>Sign Out</Text>
      </Pressable>
      <Text style={styles.footerText}>Vottery RN Phase 2 - v1.0.0</Text>
    </ScreenContainer>
  );
};

const StatCard: React.FC<{ label: string; value: string }> = ({ label, value }) => (
  <View style={styles.statCard}>
    <Text style={styles.statValue}>{value}</Text>
    <Text style={styles.statLabel}>{label}</Text>
  </View>
);

const MenuItem: React.FC<{ icon: string; label: string; onPress: () => void }> = ({ icon, label, onPress }) => (
  <Pressable onPress={onPress} style={({ pressed }) => [styles.menuItem, pressed && styles.menuPressed]}>
    <Text style={styles.menuIcon}>{icon}</Text>
    <Text style={styles.menuLabel}>{label}</Text>
    <Text style={styles.menuChevron}>›</Text>
  </Pressable>
);

const styles = StyleSheet.create({
  profileHeader: { alignItems: 'center', paddingVertical: 24, paddingHorizontal: 16 },
  avatarLarge: { width: 80, height: 80, borderRadius: 40, backgroundColor: colors.primary, alignItems: 'center', justifyContent: 'center', marginBottom: 12, elevation: 4 },
  avatarLargeText: { fontSize: 32, fontWeight: '700', color: colors.white },
  displayName: { ...typography.h2, color: colors.textPrimary },
  email: { ...typography.bodySmall, color: colors.textSecondary, marginBottom: 8 },
  roleBadge: { backgroundColor: 'rgba(99, 102, 241, 0.15)', paddingHorizontal: 12, paddingVertical: 4, borderRadius: 12 },
  roleText: { ...typography.caption, color: colors.primary, fontWeight: '600' },
  statsContainer: { flexDirection: 'row', justifyContent: 'space-around', marginVertical: 20 },
  statCard: { alignItems: 'center', flex: 1, backgroundColor: colors.surfaceDark, padding: 12, borderRadius: 12, marginHorizontal: 4, borderWidth: 1, borderColor: colors.border },
  statValue: { ...typography.h3, color: colors.textPrimary },
  statLabel: { ...typography.caption, color: colors.textSecondary },
  menuSection: { marginBottom: 20 },
  sectionTitle: { ...typography.label, color: colors.textMuted, marginLeft: 16, marginBottom: 8, textTransform: 'uppercase' },
  menuItem: { flexDirection: 'row', alignItems: 'center', padding: 16, backgroundColor: colors.surfaceDark, marginBottom: 4, borderBottomWidth: 1, borderBottomColor: colors.border },
  menuPressed: { opacity: 0.7 },
  menuIcon: { marginRight: 12, fontSize: 18 },
  menuLabel: { ...typography.body, color: colors.textPrimary, flex: 1 },
  menuChevron: { fontSize: 22, color: colors.textMuted },
  signOutBtn: { backgroundColor: 'rgba(239, 68, 68, 0.1)', paddingVertical: 14, borderRadius: 12, borderWidth: 1, borderColor: 'rgba(239, 68, 68, 0.2)', alignItems: 'center', marginTop: 12, marginBottom: 12 },
  signOutText: { ...typography.button, color: colors.error },
  footerText: { textAlign: 'center', ...typography.caption, color: colors.textMuted, paddingBottom: 24 },
});
