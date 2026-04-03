// src/screens/messaging/ConversationScreen.tsx
// Direct Messaging — Phase 2 Social Foundation
import React, { useEffect, useState, useRef } from 'react';
import {
  FlatList,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
  Alert,
} from 'react-native';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ScreenContainer, Loader, AppInput } from '../../components/ui';
import { messagingService, type DirectMessage } from '../../services/messaging';
import { useAuth } from '../../hooks/useAuth';
import { colors, typography, spacing, borderRadius } from '../../config/theme';

interface Props {
  route: any;
  navigation: any;
}

export const ConversationScreen: React.FC<Props> = ({ route, navigation }) => {
  const { channelId, name } = route.params;
  const { user } = useAuth();
  const [newMessage, setNewMessage] = useState('');
  const queryClient = useQueryClient();
  const flatListRef = useRef<FlatList>(null);

  // Fetch messages
  const {
    data: messages,
    isLoading,
    refetch,
  } = useQuery({
    queryKey: ['messages', channelId],
    queryFn: () => messagingService.getMessages(channelId),
  });

  // Mutate message sending
  const messageMutation = useMutation({
    mutationFn: (content: string) => messagingService.sendMessage(channelId, content),
    onSuccess: (data) => {
      setNewMessage('');
      queryClient.setQueryData(['messages', channelId], (old: DirectMessage[] | undefined) => [
        {
          id: data.id,
          channel_id: channelId,
          user_id: user?.id!,
          content: data.content,
          created_at: data.created_at,
          profile: {
            username: user?.user_metadata?.username || 'me',
            full_name: user?.user_metadata?.full_name || 'Me',
          },
        },
        ...(old ?? []),
      ]);
    },
    onError: (err: any) => {
        Alert.alert("Error", err.message || "Failed to send message");
    },
  });

  // Subscribe to real-time messages
  useEffect(() => {
    const subscription = messagingService.subscribeToChannel(channelId, (payload) => {
      if (payload.new) {
        queryClient.invalidateQueries({ queryKey: ['messages', channelId] });
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [channelId, queryClient]);

  const handleSendMessage = () => {
    if (!newMessage.trim()) return;
    messageMutation.mutate(newMessage.trim());
  };

  const renderMessage = ({ item }: { item: DirectMessage }) => {
    const isMe = item.user_id === user?.id;

    return (
      <View style={[styles.messageWrapper, isMe ? styles.myMessage : styles.theirMessage]}>
        {!isMe && (
          <View style={styles.miniAvatar}>
            <Text style={styles.miniAvatarText}>{item.profile.full_name.charAt(0)}</Text>
          </View>
        )}
        <View style={[styles.bubble, isMe ? styles.myBubble : styles.theirBubble]}>
          <Text style={[styles.messageText, isMe ? styles.myText : styles.theirText]}>
            {item.content}
          </Text>
          <Text style={[styles.messageTime, isMe ? styles.myTime : styles.theirTime]}>
             {new Date(item.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </Text>
        </View>
      </View>
    );
  };

  return (
    <ScreenContainer padded={false}>
      <View style={styles.header}>
        <Pressable onPress={() => navigation.goBack()} style={styles.backBtn}>
          <Text style={styles.backIcon}>←</Text>
        </Pressable>
        <Text style={styles.navTitle} numberOfLines={1}>{name || 'Conversation'}</Text>
      </View>

      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 0}
      >
        <FlatList
          ref={flatListRef}
          data={messages ?? []}
          keyExtractor={(item) => item.id}
          renderItem={renderMessage}
          contentContainerStyle={styles.listContent}
          inverted
          showsVerticalScrollIndicator={false}
        />

        <View style={styles.inputArea}>
          <AppInput
            placeholder="Type a message..."
            value={newMessage}
            onChangeText={setNewMessage}
            containerStyle={styles.inputContainer}
            onSubmitEditing={handleSendMessage}
            returnKeyType="send"
            multiline
          />
          <Pressable
            onPress={handleSendMessage}
            disabled={!newMessage.trim() || messageMutation.isPending}
            style={[styles.sendBtn, !newMessage.trim() && styles.sendBtnDisabled]}
          >
             <Text style={styles.sendIcon}>➔</Text>
          </Pressable>
        </View>
      </KeyboardAvoidingView>
    </ScreenContainer>
  );
};

const styles = StyleSheet.create({
  flex: { flex: 1 },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
    backgroundColor: colors.surfaceDark,
  },
  backBtn: { padding: 4, marginRight: 12 },
  backIcon: { fontSize: 24, color: colors.primary },
  navTitle: { ...typography.h3, color: colors.textPrimary, flex: 1 },
  listContent: { padding: 16, paddingBottom: 20 },
  messageWrapper: { flexDirection: 'row', marginBottom: 12, maxWidth: '80%' },
  myMessage: { alignSelf: 'flex-end', justifyContent: 'flex-end' },
  theirMessage: { alignSelf: 'flex-start', justifyContent: 'flex-start' },
  miniAvatar: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: colors.elevatedDark,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 8,
    alignSelf: 'flex-end',
    marginBottom: 4,
  },
  miniAvatarText: { color: colors.white, fontSize: 10, fontWeight: '700' },
  bubble: {
    paddingVertical: 10,
    paddingHorizontal: 14,
    borderRadius: 18,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 1,
    elevation: 1,
  },
  myBubble: { backgroundColor: colors.primary, borderBottomRightRadius: 4 },
  theirBubble: { backgroundColor: colors.elevatedDark, borderBottomLeftRadius: 4 },
  messageText: { ...typography.body, color: colors.white },
  myText: { color: colors.white },
  theirText: { color: colors.textPrimary },
  messageTime: { ...typography.caption, marginTop: 4, alignSelf: 'flex-end', fontSize: 9 },
  myTime: { color: 'rgba(255,255,255,0.7)' },
  theirTime: { color: colors.textMuted },
  inputArea: {
    flexDirection: 'row',
    padding: 12,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    backgroundColor: colors.surfaceDark,
    alignItems: 'center',
  },
  inputContainer: { flex: 1, marginBottom: 0 },
  sendBtn: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginLeft: 10,
  },
  sendBtnDisabled: { backgroundColor: colors.elevatedDark, opacity: 0.5 },
  sendIcon: { fontSize: 20, color: colors.white },
});
