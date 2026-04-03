// src/screens/main/FeedDetailScreen.tsx
// Post Details and Comments — Phase 2 Social Foundation
import React, { useCallback, useEffect, useState } from 'react';
import {
  Alert,
  FlatList,
  Keyboard,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  RefreshControl,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ScreenContainer, Loader, AppInput } from '../../components/ui';
import { useAuth } from '../../hooks/useAuth';
import { socialService, type Comment } from '../../services/social';
import { colors, typography, spacing, borderRadius } from '../../config/theme';

interface Props {
  route: any;
  navigation: any;
}

export const FeedDetailScreen: React.FC<Props> = ({ route, navigation }) => {
  const { postId, title } = route.params;
  const { user, profile } = useAuth();
  const [newComment, setNewComment] = useState('');
  const queryClient = useQueryClient();

  // Fetch comments
  const {
    data: comments,
    isLoading,
    isRefetching,
    refetch,
  } = useQuery({
    queryKey: ['comments', postId],
    queryFn: () => socialService.getComments(postId),
  });

  // Post comment mutation
  const commentMutation = useMutation({
    mutationFn: (content: string) => socialService.addComment(postId, content),
    onSuccess: (data) => {
      setNewComment('');
      Keyboard.dismiss();
      queryClient.setQueryData(['comments', postId], (old: Comment[] | undefined) => [
        ...(old ?? []),
        {
          id: data.id,
          post_id: postId,
          user_id: data.user_id,
          content: data.content,
          created_at: data.created_at,
          profile: {
            username: profile?.username || user?.user_metadata?.username || 'me',
            full_name: profile?.full_name || user?.user_metadata?.full_name || 'Me',
            avatar_url: profile?.avatar_url,
          },
        },
      ]);
      refetch();
    },
    onError: (err: any) => {
      Alert.alert('Error', err.message || 'Failed to post comment');
    },
  });

  // Real-time listener setup
  useEffect(() => {
    const subscription = socialService.subscribeToComments(postId, (payload) => {
      if (payload.new) {
        queryClient.invalidateQueries({ queryKey: ['comments', postId] });
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [postId, queryClient]);

  const handlePostComment = () => {
    if (!newComment.trim()) return;
    commentMutation.mutate(newComment.trim());
  };

  const renderComment = useCallback(({ item }: { item: Comment }) => (
    <View style={styles.commentContainer}>
      <View style={styles.avatar}>
        <Text style={styles.avatarText}>{item.profile.full_name.charAt(0)}</Text>
      </View>
      <View style={styles.commentBody}>
        <View style={styles.commentHeader}>
          <Text style={styles.commentAuthor}>{item.profile.full_name}</Text>
          <Text style={styles.commentTime}>
            {new Date(item.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </Text>
        </View>
        <Text style={styles.commentText}>{item.content}</Text>
      </View>
    </View>
  ), []);

  return (
    <ScreenContainer padded={false}>
      <View style={styles.navHeader}>
        <Pressable onPress={() => navigation.goBack()} style={styles.backBtn}>
          <Text style={styles.backIcon}>←</Text>
        </Pressable>
        <Text style={styles.navTitle} numberOfLines={1}>{title || 'Post Details'}</Text>
      </View>

      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <FlatList
          data={comments ?? []}
          keyExtractor={(item) => item.id}
          renderItem={renderComment}
          contentContainerStyle={styles.listContent}
          refreshControl={
            <RefreshControl refreshing={isRefetching} onRefresh={refetch} tintColor={colors.primary} />
          }
          ListEmptyComponent={
            isLoading ? null : (
              <View style={styles.emptyContainer}>
                <Text style={styles.emptyText}>No comments yet. Start the conversation!</Text>
              </View>
            )
          }
        />

        <View style={styles.inputArea}>
          <AppInput
            placeholder="Write a comment..."
            value={newComment}
            onChangeText={setNewComment}
            containerStyle={styles.inputContainer}
            onSubmitEditing={handlePostComment}
            returnKeyType="send"
          />
          <Pressable
            onPress={handlePostComment}
            disabled={!newComment.trim() || commentMutation.isPending}
            style={[styles.sendBtn, !newComment.trim() && styles.sendBtnDisabled]}
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
  navHeader: {
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
  listContent: { padding: 16, paddingBottom: 24 },
  commentContainer: {
    flexDirection: 'row',
    marginBottom: 20,
  },
  avatar: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: colors.elevatedDark,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  avatarText: { color: colors.white, fontWeight: '600' },
  commentBody: { flex: 1 },
  commentHeader: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 4 },
  commentAuthor: { ...typography.label, color: colors.textPrimary },
  commentTime: { ...typography.caption, color: colors.textMuted },
  commentText: { ...typography.body, color: colors.textSecondary },
  emptyContainer: { padding: 40, alignItems: 'center' },
  emptyText: { ...typography.bodySmall, color: colors.textMuted, textAlign: 'center' },
  inputArea: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    padding: 12,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    backgroundColor: colors.surfaceDark,
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
    marginTop: 2,
  },
  sendBtnDisabled: { backgroundColor: colors.elevatedDark, opacity: 0.5 },
  sendIcon: { fontSize: 20, color: colors.white },
});
