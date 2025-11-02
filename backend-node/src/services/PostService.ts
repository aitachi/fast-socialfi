/**
 * Author: Aitachi
 * Email: 44158892@qq.com
 * Date: 11-02-2025 17
 */

import db from '../config/database';
import { Post, CreatePostDTO, UpdatePostDTO, PaginatedResult } from '../types';
import cacheUtil from '../utils/cache';
import searchUtil from '../utils/search';
import queueUtil from '../utils/queue';

/**
 * Post Service - Handles all post-related business logic
 */
class PostService {
  /**
   * Create a new post
   */
  async createPost(data: CreatePostDTO): Promise<Post> {
    const query = `
      INSERT INTO posts (
        author_id, content, media_urls, media_type,
        hashtags, mentions, visibility, is_sensitive
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *
    `;

    const values = [
      data.author_id,
      data.content,
      JSON.stringify(data.media_urls || []),
      data.media_type || 'text',
      data.hashtags || [],
      data.mentions || [],
      data.visibility || 'public',
      data.is_sensitive || false,
    ];

    const result = await db.query<Post>(query, values);
    const post = result.rows[0];

    // Process hashtags
    if (data.hashtags && data.hashtags.length > 0) {
      await this.processHashtags(post.id, data.hashtags);
    }

    // Cache the post
    await cacheUtil.cachePost(post.id, post);

    // Publish post created event
    await queueUtil.publishPostCreated(post.id, post.author_id);

    return post;
  }

  /**
   * Get post by ID
   */
  async getPostById(postId: number): Promise<Post | null> {
    // Try cache first
    const cached = await cacheUtil.getPost(postId);
    if (cached) {
      return cached;
    }

    const query = 'SELECT * FROM posts WHERE id = $1 AND deleted_at IS NULL';
    const result = await db.query<Post>(query, [postId]);

    if (result.rows.length === 0) {
      return null;
    }

    const post = result.rows[0];
    await cacheUtil.cachePost(postId, post);

    return post;
  }

  /**
   * Update post
   */
  async updatePost(postId: number, data: UpdatePostDTO): Promise<Post> {
    const fields: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    if (data.content !== undefined) {
      fields.push(`content = $${paramIndex++}`);
      values.push(data.content);
    }
    if (data.media_urls !== undefined) {
      fields.push(`media_urls = $${paramIndex++}`);
      values.push(JSON.stringify(data.media_urls));
    }
    if (data.hashtags !== undefined) {
      fields.push(`hashtags = $${paramIndex++}`);
      values.push(data.hashtags);
    }
    if (data.is_pinned !== undefined) {
      fields.push(`is_pinned = $${paramIndex++}`);
      values.push(data.is_pinned);
    }
    if (data.is_sensitive !== undefined) {
      fields.push(`is_sensitive = $${paramIndex++}`);
      values.push(data.is_sensitive);
    }

    if (fields.length === 0) {
      const post = await this.getPostById(postId);
      if (!post) throw new Error('Post not found');
      return post;
    }

    values.push(postId);
    const query = `
      UPDATE posts
      SET ${fields.join(', ')}, updated_at = CURRENT_TIMESTAMP
      WHERE id = $${paramIndex} AND deleted_at IS NULL
      RETURNING *
    `;

    const result = await db.query<Post>(query, values);
    const post = result.rows[0];

    // Invalidate cache
    await cacheUtil.invalidatePost(postId);

    // Update search index
    await searchUtil.updatePost(postId, post);

    return post;
  }

  /**
   * Delete post (soft delete)
   */
  async deletePost(postId: number, userId: number): Promise<void> {
    const query = `
      UPDATE posts
      SET deleted_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND author_id = $2 AND deleted_at IS NULL
    `;

    await db.query(query, [postId, userId]);

    // Invalidate cache
    await cacheUtil.invalidatePost(postId);

    // Remove from search index
    await searchUtil.deletePost(postId);
  }

  /**
   * Get user's posts
   */
  async getUserPosts(
    userId: number,
    page: number = 1,
    limit: number = 20
  ): Promise<PaginatedResult<Post>> {
    const offset = (page - 1) * limit;

    const query = `
      SELECT p.*
      FROM posts p
      WHERE p.author_id = $1 AND p.deleted_at IS NULL
      ORDER BY p.created_at DESC
      LIMIT $2 OFFSET $3
    `;

    const countQuery = `
      SELECT COUNT(*) as total
      FROM posts
      WHERE author_id = $1 AND deleted_at IS NULL
    `;

    const [dataResult, countResult] = await Promise.all([
      db.query<Post>(query, [userId, limit, offset]),
      db.query<{ total: string }>(countQuery, [userId]),
    ]);

    const total = parseInt(countResult.rows[0].total);

    return {
      data: dataResult.rows,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasMore: offset + limit < total,
      },
    };
  }

  /**
   * Get feed for a user (posts from followed users)
   */
  async getFeed(
    userId: number,
    page: number = 1,
    limit: number = 20
  ): Promise<PaginatedResult<Post>> {
    // Try cache first for page 1
    if (page === 1) {
      const cached = await cacheUtil.getFeed(userId);
      if (cached) {
        return {
          data: cached,
          meta: {
            page: 1,
            limit,
            total: cached.length,
            totalPages: 1,
            hasMore: false,
          },
        };
      }
    }

    const offset = (page - 1) * limit;

    const query = `
      SELECT p.*
      FROM posts p
      INNER JOIN follows f ON f.following_id = p.author_id
      WHERE f.follower_id = $1
        AND p.deleted_at IS NULL
        AND p.visibility = 'public'
        AND p.moderation_status = 'approved'
      ORDER BY p.created_at DESC
      LIMIT $2 OFFSET $3
    `;

    const countQuery = `
      SELECT COUNT(*) as total
      FROM posts p
      INNER JOIN follows f ON f.following_id = p.author_id
      WHERE f.follower_id = $1
        AND p.deleted_at IS NULL
        AND p.visibility = 'public'
        AND p.moderation_status = 'approved'
    `;

    const [dataResult, countResult] = await Promise.all([
      db.query<Post>(query, [userId, limit, offset]),
      db.query<{ total: string }>(countQuery, [userId]),
    ]);

    const total = parseInt(countResult.rows[0].total);

    // Cache first page
    if (page === 1 && dataResult.rows.length > 0) {
      await cacheUtil.cacheFeed(userId, dataResult.rows, 300); // Cache for 5 minutes
    }

    return {
      data: dataResult.rows,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasMore: offset + limit < total,
      },
    };
  }

  /**
   * Get trending posts
   */
  async getTrendingPosts(
    page: number = 1,
    limit: number = 20
  ): Promise<PaginatedResult<Post>> {
    const offset = (page - 1) * limit;

    const query = `
      SELECT *
      FROM trending_posts
      LIMIT $1 OFFSET $2
    `;

    const countQuery = `
      SELECT COUNT(*) as total
      FROM trending_posts
    `;

    const [dataResult, countResult] = await Promise.all([
      db.query<Post>(query, [limit, offset]),
      db.query<{ total: string }>(countQuery),
    ]);

    const total = parseInt(countResult.rows[0].total);

    return {
      data: dataResult.rows,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasMore: offset + limit < total,
      },
    };
  }

  /**
   * Get posts by hashtag
   */
  async getPostsByHashtag(
    hashtag: string,
    page: number = 1,
    limit: number = 20
  ): Promise<PaginatedResult<Post>> {
    const offset = (page - 1) * limit;

    const query = `
      SELECT p.*
      FROM posts p
      WHERE $1 = ANY(p.hashtags)
        AND p.deleted_at IS NULL
        AND p.visibility = 'public'
        AND p.moderation_status = 'approved'
      ORDER BY p.created_at DESC
      LIMIT $2 OFFSET $3
    `;

    const countQuery = `
      SELECT COUNT(*) as total
      FROM posts p
      WHERE $1 = ANY(p.hashtags)
        AND p.deleted_at IS NULL
        AND p.visibility = 'public'
        AND p.moderation_status = 'approved'
    `;

    const [dataResult, countResult] = await Promise.all([
      db.query<Post>(query, [hashtag, limit, offset]),
      db.query<{ total: string }>(countQuery, [hashtag]),
    ]);

    const total = parseInt(countResult.rows[0].total);

    return {
      data: dataResult.rows,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasMore: offset + limit < total,
      },
    };
  }

  /**
   * Increment post view count
   */
  async incrementViewCount(postId: number): Promise<void> {
    const query = 'UPDATE posts SET view_count = view_count + 1 WHERE id = $1';
    await db.query(query, [postId]);
    await cacheUtil.invalidatePost(postId);
  }

  /**
   * Process hashtags
   */
  private async processHashtags(postId: number, hashtags: string[]): Promise<void> {
    for (const tag of hashtags) {
      const normalized = tag.toLowerCase().replace(/\s+/g, '');

      // Insert or update hashtag
      const hashtagQuery = `
        INSERT INTO hashtags (tag, tag_normalized, post_count)
        VALUES ($1, $2, 1)
        ON CONFLICT (tag_normalized)
        DO UPDATE SET post_count = hashtags.post_count + 1
        RETURNING id
      `;

      const hashtagResult = await db.query(hashtagQuery, [tag, normalized]);
      const hashtagId = hashtagResult.rows[0].id;

      // Link post to hashtag
      const linkQuery = `
        INSERT INTO post_hashtags (post_id, hashtag_id)
        VALUES ($1, $2)
        ON CONFLICT DO NOTHING
      `;

      await db.query(linkQuery, [postId, hashtagId]);
    }
  }
}

export default new PostService();
