/**
 * Type Definitions for Fast SocialFi Backend
 */

// User Types
export interface User {
  id: number;
  wallet_address: string;
  username: string | null;
  display_name: string | null;
  bio: string | null;
  avatar_url: string | null;
  cover_url: string | null;
  email: string | null;
  verified: boolean;
  verification_level: number;
  reputation_score: number;
  follower_count: number;
  following_count: number;
  post_count: number;
  created_at: Date;
  updated_at: Date;
  last_login_at: Date | null;
  is_active: boolean;
  is_banned: boolean;
  banned_until: Date | null;
  metadata: Record<string, any>;
}

export interface CreateUserDTO {
  wallet_address: string;
  username?: string;
  display_name?: string;
  bio?: string;
  avatar_url?: string;
}

export interface UpdateUserDTO {
  username?: string;
  display_name?: string;
  bio?: string;
  avatar_url?: string;
  cover_url?: string;
  email?: string;
}

// Post Types
export interface Post {
  id: number;
  author_id: number;
  content: string;
  media_urls: string[];
  media_type: string | null;
  hashtags: string[];
  mentions: number[];
  visibility: string;
  is_pinned: boolean;
  is_sensitive: boolean;
  moderation_status: string;
  like_count: number;
  comment_count: number;
  repost_count: number;
  view_count: number;
  share_count: number;
  bookmark_count: number;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
  metadata: Record<string, any>;
}

export interface CreatePostDTO {
  author_id: number;
  content: string;
  media_urls?: string[];
  media_type?: string;
  hashtags?: string[];
  mentions?: number[];
  visibility?: string;
  is_sensitive?: boolean;
}

export interface UpdatePostDTO {
  content?: string;
  media_urls?: string[];
  hashtags?: string[];
  is_pinned?: boolean;
  is_sensitive?: boolean;
}

// Comment Types
export interface Comment {
  id: number;
  post_id: number;
  author_id: number;
  parent_id: number | null;
  content: string;
  media_urls: string[];
  mentions: number[];
  like_count: number;
  reply_count: number;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
  metadata: Record<string, any>;
}

export interface CreateCommentDTO {
  post_id: number;
  author_id: number;
  content: string;
  parent_id?: number;
  media_urls?: string[];
  mentions?: number[];
}

// Like Types
export interface Like {
  id: number;
  user_id: number;
  target_type: string;
  target_id: number;
  created_at: Date;
}

// Follow Types
export interface Follow {
  id: number;
  follower_id: number;
  following_id: number;
  created_at: Date;
}

// Notification Types
export interface Notification {
  id: number;
  user_id: number;
  actor_id: number | null;
  type: string;
  title: string | null;
  content: string | null;
  target_type: string | null;
  target_id: number | null;
  is_read: boolean;
  read_at: Date | null;
  created_at: Date;
  metadata: Record<string, any>;
}

export interface CreateNotificationDTO {
  user_id: number;
  actor_id?: number;
  type: string;
  title?: string;
  content?: string;
  target_type?: string;
  target_id?: number;
  metadata?: Record<string, any>;
}

// NFT Types
export interface NFT {
  id: number;
  token_id: string;
  contract_address: string;
  chain_id: number;
  owner_address: string;
  creator_address: string | null;
  name: string | null;
  description: string | null;
  image_url: string | null;
  external_url: string | null;
  attributes: any[];
  token_uri: string | null;
  metadata: Record<string, any>;
  created_at: Date;
  updated_at: Date;
}

// Transaction Types
export interface Transaction {
  id: number;
  tx_hash: string;
  chain_id: number;
  from_address: string;
  to_address: string;
  value: string | null;
  gas_used: string | null;
  gas_price: string | null;
  block_number: number | null;
  transaction_type: string;
  status: string;
  contract_address: string | null;
  token_symbol: string | null;
  token_decimals: number | null;
  timestamp: Date | null;
  created_at: Date;
  metadata: Record<string, any>;
}

// Hashtag Types
export interface Hashtag {
  id: number;
  tag: string;
  tag_normalized: string;
  post_count: number;
  trend_score: number;
  description: string | null;
  created_at: Date;
  updated_at: Date;
}

// Auth Types
export interface AuthPayload {
  userId: number;
  walletAddress: string;
}

export interface JWTPayload extends AuthPayload {
  iat: number;
  exp: number;
}

// API Response Types
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
  meta?: {
    page?: number;
    limit?: number;
    total?: number;
    hasMore?: boolean;
  };
}

// Pagination Types
export interface PaginationParams {
  page: number;
  limit: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface PaginatedResult<T> {
  data: T[];
  meta: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasMore: boolean;
  };
}

// Search Types
export interface SearchParams {
  keyword: string;
  filters?: Record<string, any>;
  page?: number;
  limit?: number;
}

// Cache Types
export interface CacheOptions {
  ttl?: number;
  prefix?: string;
}
