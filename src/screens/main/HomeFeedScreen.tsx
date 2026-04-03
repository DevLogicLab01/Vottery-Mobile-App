// src/screens/main/HomeFeedScreen.tsx
// Home feed screen — ported from Flutter social_home_feed
import React, { useCallback } from 'react';
import {
  FlatList,
  Pressable,
  RefreshControl,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { ScreenContainer, EmptyState, Loader } from '../../components/ui';
import { feedService } from '../../services/feed';
import { colors, typography, spacing, borderRadius } from '../../config/theme';
import { Routes } from '../../navigation/routes';
import type { FeedItem } from '../../types/voting';

interface Props {
  navigation: any;
}

export const HomeFeedScreen: React.FC<Props> = ({ navigation }) => {
  const {
    data: feedItems,
    isLoading,
    isRefetching,
    refetch,
  } = useQuery({
    queryKey: ['homeFeed'],
    queryFn: () => feedService.getHomeFeed(20, 0),
    staleTime: 30_000,
  });

  const renderFeedCard = useCallback(({ item }: { item: FeedItem }) => {
    return <FeedCard item={item} onPress={() => navigation.navigate(Routes.FEED_DETAIL, { postId: item.id, title: item.title })} />;
  }, [navigation]);

  if (isLoading) {
    return <Loader message="Loading feed..." />;
  }

  return (
    <ScreenContainer padded={false}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Vottery</Text>
        <Text style={styles.headerSubtitle}>What's trending today</Text>
      </View>

      <FlatList
        data={feedItems ?? []}
        keyExtractor={(item) => item.id}
        renderItem={renderFeedCard}
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={isRefetching}
            onRefresh={refetch}
            tintColor={colors.primary}
            colors={[colors.primary]}
          />
        }
        ListEmptyComponent={
          <EmptyState
            icon="🗳️"
            title="No votes yet"
            subtitle="Be the first to create a vote!"
            actionLabel="Refresh"
            onAction={() => refetch()}
          />
        }
        ItemSeparatorComponent={() => <View style={styles.separator} />}
      />
    </ScreenContainer>
  );
};

// ─── Feed Card Component ────────────────────────────────────
const FeedCard: React.FC<{ item: FeedItem; onPress: () => void }> = ({ item, onPress }) => {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [styles.card, pressed && styles.cardPressed]}
    >
      <View style={styles.creatorRow}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{item.creator.full_name?.charAt(0) ?? '?'}</Text>
        </View>
        <View style={styles.creatorInfo}>
          <Text style={styles.creatorName}>{item.creator.full_name}</Text>
          <Text style={styles.timeAgo}>{timeAgo(item.created_at)}</Text>
        </View>
      </View>

      <Text style={styles.cardTitle}>{item.title}</Text>
      {item.description && <Text style={styles.cardDescription} numberOfLines={2}>{item.description}</Text>}

      <View style={styles.statsRow}>
        <View style={styles.statItem}>
          <Text style={styles.statIcon}>🗳️</Text>
          <Text style={styles.statValue}>{item.total_votes?.toLocaleString() ?? 0} votes</Text>
        </View>
        <View style={styles.voteButton}>
          <Text style={styles.voteButtonText}>View Details</Text>
        </View>
      </View>
    </Pressable>
  );
};

function timeAgo(date: string) {
  const diff = Date.now() - new Date(date).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  return new Date(date).toLocaleDateString();
}

const styles = StyleSheet.create({
  header: { padding: 16, borderBottomWidth: 1, borderBottomColor: colors.border, backgroundColor: colors.surfaceDark },
  headerTitle: { ...typography.h2, color: colors.textPrimary },
  headerSubtitle: { ...typography.bodySmall, color: colors.textSecondary },
  listContent: { padding: 16, paddingBottom: 100 },
  separator: { height: 12 },
  card: { backgroundColor: colors.surfaceDark, borderRadius: borderRadius.lg, padding: 16, borderWidth: 1, borderColor: colors.border },
  cardPressed: { opacity: 0.9 },
  creatorRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 12 },
  avatar: { width: 36, height: 36, borderRadius: 18, backgroundColor: colors.primary, alignItems: 'center', justifyContent: 'center', marginRight: 10 },
  avatarText: { color: colors.white, fontWeight: '700' },
  creatorInfo: { flex: 1 },
  creatorName: { ...typography.label, color: colors.textPrimary },
  timeAgo: { ...typography.caption, color: colors.textMuted },
  cardTitle: { ...typography.h3, color: colors.textPrimary, marginBottom: 6 },
  cardDescription: { ...typography.bodySmall, color: colors.textSecondary, marginBottom: 10 },
  statsRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', borderTopWidth: 1, borderTopColor: colors.border, paddingTop: 12 },
  statItem: { flexDirection: 'row', alignItems: 'center' },
  statIcon: { fontSize: 14, marginRight: 4 },
  statValue: { ...typography.bodySmall, color: colors.textSecondary },
  voteButton: { backgroundColor: colors.primary, paddingHorizontal: 16, paddingVertical: 8, borderRadius: borderRadius.md },
  voteButtonText: { ...typography.label, color: colors.white },
});
