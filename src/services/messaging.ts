// src/services/messaging.ts
// Messaging service — chat list and message history
// Ported from Flutter direct_messaging patterns
import { supabase } from '../lib/supabase';

export interface ChatChannel {
  id: string;
  created_at: string;
  creator_id: string;
  participant_ids: string[];
  last_message_content?: string;
  last_message_at?: string;
  metadata?: {
    is_group?: boolean;
    channel_name?: string;
    description?: string;
  };
}

export interface DirectMessage {
  id: string;
  channel_id: string;
  user_id: string;
  content: string;
  created_at: string;
  profile: {
    username: string;
    full_name: string;
    avatar_url?: string;
  };
}

class MessagingService {
  /** Fetch all chat channels for current user */
  async getChannels() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Unauthorized');

    const { data, error } = await supabase
      .from('messaging_channels')
      .select('*')
      .contains('participant_ids', [user.id])
      .order('last_message_at', { ascending: false });

    if (error) {
      console.warn('getChannels error:', error.message);
      return [];
    }

    return data as ChatChannel[];
  }

  /** Fetch messages for a specific channel */
  async getMessages(channelId: string) {
    const { data, error } = await supabase
      .from('direct_messages')
      .select(`
        *,
        user_profiles (*)
      `)
      .eq('channel_id', channelId)
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) {
      console.warn('getMessages error:', error.message);
      return [];
    }

    return (data ?? []).map((m: any) => ({
      id: m.id,
      channel_id: m.channel_id,
      user_id: m.user_id,
      content: m.content,
      created_at: m.created_at,
      profile: {
        username: m.user_profiles?.username ?? 'user',
        full_name: m.user_profiles?.full_name ?? 'Anonymous',
        avatar_url: m.user_profiles?.avatar_url,
      },
    }));
  }

  /** Send a direct message */
  async sendMessage(channelId: string, content: string) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Unauthorized');

    const { data, error } = await supabase
      .from('direct_messages')
      .insert({
        channel_id: channelId,
        user_id: user.id,
        content: content.trim(),
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /** Subscribe to real-time messages in a channel */
  subscribeToChannel(channelId: string, onNewMessage: (payload: any) => void) {
    return supabase
      .channel(`chat-channel-${channelId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'direct_messages',
          filter: `channel_id=eq.${channelId}`,
        },
        onNewMessage
      )
      .subscribe();
  }
}

export const messagingService = new MessagingService();
