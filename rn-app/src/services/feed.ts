// src/services/feed.ts
// Feed service — fetches home feed data from Supabase
// Ported from Flutter social_home_feed and voting_service patterns
import { supabase } from '../lib/supabase';
import type { FeedItem } from '../types/voting';

class FeedService {
  /** Fetch the home feed — active elections, ordered by recency */
  async getHomeFeed(limit = 20, offset = 0): Promise<FeedItem[]> {
    const { data, error } = await supabase
      .from('elections')
      .select(
        `
        id,
        title,
        description,
        category,
        status,
        total_votes,
        image_url,
        created_at,
        creator_id,
        user_profiles!elections_creator_id_fkey (
          id,
          username,
          full_name,
          avatar_url
        )
      `,
      )
      .in('status', ['active', 'closed'])
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.warn('getHomeFeed error:', error.message);
      return [];
    }

    return (data ?? []).map((item: any) => ({
      id: item.id,
      type: 'election' as const,
      title: item.title,
      description: item.description,
      creator: {
        id: item.user_profiles?.id ?? item.creator_id,
        username: item.user_profiles?.username ?? 'unknown',
        full_name: item.user_profiles?.full_name ?? 'Unknown User',
        avatar_url: item.user_profiles?.avatar_url,
      },
      image_url: item.image_url,
      total_votes: item.total_votes ?? 0,
      created_at: item.created_at,
      category: item.category,
      status: item.status,
    }));
  }

  /** Fetch trending elections */
  async getTrending(limit = 10): Promise<FeedItem[]> {
    const { data, error } = await supabase
      .from('elections')
      .select(
        `
        id, title, description, category, status, total_votes, image_url, created_at, creator_id,
        user_profiles!elections_creator_id_fkey ( id, username, full_name, avatar_url )
      `,
      )
      .eq('status', 'active')
      .order('total_votes', { ascending: false })
      .limit(limit);

    if (error) {
      console.warn('getTrending error:', error.message);
      return [];
    }

    return (data ?? []).map((item: any) => ({
      id: item.id,
      type: 'election' as const,
      title: item.title,
      description: item.description,
      creator: {
        id: item.user_profiles?.id ?? item.creator_id,
        username: item.user_profiles?.username ?? 'unknown',
        full_name: item.user_profiles?.full_name ?? 'Unknown User',
        avatar_url: item.user_profiles?.avatar_url,
      },
      image_url: item.image_url,
      total_votes: item.total_votes ?? 0,
      created_at: item.created_at,
      category: item.category,
      status: item.status,
    }));
  }
}

export const feedService = new FeedService();
