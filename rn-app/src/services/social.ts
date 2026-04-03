// src/services/social.ts
// Social service — handles reactions, comments, and post details
// Ported from Flutter social_home_feed and direct_messaging patterns
import { supabase } from '../lib/supabase';

export interface Comment {
  id: string;
  post_id: string;
  user_id: string;
  content: string;
  created_at: string;
  profile: {
    username: string;
    full_name: string;
    avatar_url?: string;
  };
}

class SocialService {
  /** Fetch detailed post/election info with options */
  async getPostDetails(postId: string) {
    const { data, error } = await supabase
      .from('elections')
      .select(`
        *,
        options (*),
        user_profiles!elections_creator_id_fkey (*)
      `)
      .eq('id', postId)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  /** Fetch comments for a specific post */
  async getComments(postId: string): Promise<Comment[]> {
    const { data, error } = await supabase
      .from('post_comments')
      .select(`
        *,
        user_profiles (*)
      `)
      .eq('post_id', postId)
      .order('created_at', { ascending: true });

    if (error) {
      console.warn('getComments error:', error.message);
      return [];
    }

    return (data ?? []).map((c: any) => ({
      id: c.id,
      post_id: c.post_id,
      user_id: c.user_id,
      content: c.content,
      created_at: c.created_at,
      profile: {
        username: c.user_profiles?.username ?? 'user',
        full_name: c.user_profiles?.full_name ?? 'Anonymous',
        avatar_url: c.user_profiles?.avatar_url,
      },
    }));
  }

  /** Add a comment to a post */
  async addComment(postId: string, content: string) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Unauthorized');

    const { data, error } = await supabase
      .from('post_comments')
      .insert({
        post_id: postId,
        user_id: user.id,
        content: content.trim(),
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /** Subscribe to real-time comments for a post */
  subscribeToComments(postId: string, onNewComment: (payload: any) => void) {
    return supabase
      .channel(`post-comments-${postId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'post_comments',
          filter: `post_id=eq.${postId}`,
        },
        onNewComment
      )
      .subscribe();
  }

  /** Add a reaction/like */
  async reactToPost(postId: string, reactionType: string = 'like') {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Unauthorized');

    const { error } = await supabase
      .from('post_reactions')
      .upsert({
        post_id: postId,
        user_id: user.id,
        reaction_type: reactionType,
      });

    if (error) throw error;
  }
}

export const socialService = new SocialService();
