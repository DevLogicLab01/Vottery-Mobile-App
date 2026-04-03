// src/screens/messaging/MessagingListScreen.tsx
// Chat Inbox — Phase 2 Social Foundation
import React, { useEffect } from 'react';
import {
  FlatList,
  Pressable,
  RefreshControl,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { ScreenContainer, Loader, EmptyState } from '../../components/ui';
import { messagingService, type ChatChannel } from '../../services/messaging';
import { colors, typography, spacing, borderRadius } from '../../config/theme';
import { Routes } from '../../navigation/routes';

interface Props {
  navigation: any;
}

export const MessagingListScreen: React.FC<Props> = ({ navigation }) => {
  const {
    data: channels,
    isLoading,
    isRefetching,
    refetch,
  } = useQuery({
    queryKey: ['chatChannels'],
    queryFn: () => messagingService.getChannels(),
  });

  const renderChannel = ({ item }: { item: ChatChannel }) => {
    const channelName = item.metadata?.channel_name || 'Group Chat';

    return (
      <Pressable
        onPress={() => navigation.navigate(Routes.CONVERSATION, { channelId: item.id, name: channelName })}
        style={({ pressed }) => [styles.channelItem, pressed && styles.channelPressed]}
      >
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{channelName.charAt(0)}</Text>
        </View>
        <View style={styles.channelBody}>
          <View style={styles.channelHeader}>
            <Text style={styles.channelName}>{channelName}</Text>
            <Text style={styles.timeText}>
              {item.last_message_at ? new Date(item.last_message_at).toLocaleDateString() : ''}
            </Text>
          </View>
          <Text style={styles.lastMessage} numberOfLines={1}>
            {item.last_message_content || 'No messages yet'}
          </Text>
        </View>
      </Pressable>
    );
  };

  return (
    <ScreenContainer padded={false}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Messages</Text>
        <Pressable style={styles.newBtn}>
          <Text style={styles.newIcon}>+</Text>
        </Pressable>
      </View>

      <FlatList
        data={channels ?? []}
        keyExtractor={(item) => item.id}
        renderItem={renderChannel}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl refreshing={isRefetching} onRefresh={refetch} tintColor={colors.primary} />
        }
        ListEmptyComponent={
          isLoading ? null : (
            <EmptyState
              icon="💬"
              title="Inbox is empty"
              subtitle="Start a new message with a friend or creator!"
              actionLabel="Refresh"
              onAction={() => refetch()}
            />
          )
        }
        ItemSeparatorComponent={() => <View style={styles.separator} />}
      />
    </ScreenContainer>
  );
};

const styles = StyleSheet.create({
  header: {
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.surfaceDark,
  },
  headerTitle: { ...typography.h2, color: colors.textPrimary },
  newBtn: { padding: 8 },
  newIcon: { fontSize: 24, color: colors.primary },
  listContent: { paddingBottom: 100 },
  channelItem: {
    flexDirection: 'row',
    padding: 16,
    backgroundColor: colors.surfaceDark,
    alignItems: 'center',
  },
  channelPressed: { opacity: 0.8 },
  avatar: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: colors.elevatedDark,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  avatarText: { color: colors.white, fontWeight: '700', fontSize: 18 },
  channelBody: { flex: 1 },
  channelHeader: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 4 },
  channelName: { ...typography.label, color: colors.textPrimary, fontSize: 16 },
  timeText: { ...typography.caption, color: colors.textMuted },
  lastMessage: { ...typography.bodySmall, color: colors.textSecondary },
  separator: { height: 1, backgroundColor: colors.border },
});
