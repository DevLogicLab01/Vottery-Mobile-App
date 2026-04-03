// src/types/voting.ts
// TypeScript types for the voting domain (from Flutter voting_service.dart)

export interface Election {
  id: string;
  title: string;
  description: string;
  creator_id: string;
  category: string;
  status: 'draft' | 'active' | 'closed' | 'archived';
  start_date: string;
  end_date: string;
  total_votes: number;
  options: ElectionOption[];
  created_at: string;
  updated_at?: string;
  image_url?: string;
  is_anonymous?: boolean;
  requires_auth?: boolean;
}

export interface ElectionOption {
  id: string;
  election_id: string;
  title: string;
  description?: string;
  image_url?: string;
  vote_count: number;
  order_index: number;
}

export interface Vote {
  id: string;
  election_id: string;
  user_id: string;
  option_id: string;
  created_at: string;
}

export interface FeedItem {
  id: string;
  type: 'election' | 'post' | 'moment';
  title: string;
  description?: string;
  creator: {
    id: string;
    username: string;
    full_name: string;
    avatar_url?: string;
  };
  image_url?: string;
  total_votes?: number;
  total_comments?: number;
  total_shares?: number;
  created_at: string;
  category?: string;
  status?: string;
}
