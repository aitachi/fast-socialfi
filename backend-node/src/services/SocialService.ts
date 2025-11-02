import db from '../config/database';
import { Like, Follow, Comment, CreateCommentDTO } from '../types';
import cacheUtil from '../utils/cache';
import queueUtil from '../utils/queue';

/**
 * Social Service - Handles social interactions (likes, follows, comments)
 */
class SocialService {
  /**
   * Like a post or comment
   */
  async like(userId: number, targetType: string, targetId: number): Promise<Like> {
    const query = `
      INSERT INTO likes (user_id, target_type, target_id)
      VALUES ($1, $2, $3)
      ON CONFLICT (user_id, target_type, target_id) DO NOTHING
      RETURNING *
    `;

    const result = await db.query<Like>(query, [userId, targetType, targetId]);

    if (result.rows.length > 0) {
      // Publish like event
      await queueUtil.publishLikeCreated(userId, targetType, targetId);

      // Invalidate cache
      if (targetType === 'post') {
        await cacheUtil.invalidatePost(targetId);
      }
    }

    return result.rows[0];
  }

  /**
   * Unlike a post or comment
   */
  async unlike(userId: number, targetType: string, targetId: number): Promise<void> {
    const query = `
      DELETE FROM likes
      WHERE user_id = $1 AND target_type = $2 AND target_id = $3
    `;

    await db.query(query, [userId, targetType, targetId]);

    // Invalidate cache
    if (targetType === 'post') {
      await cacheUtil.invalidatePost(targetId);
    }
  }

  /**
   * Check if user has liked a target
   */
  async hasLiked(
    userId: number,
    targetType: string,
    targetId: number
  ): Promise<boolean> {
    const query = `
      SELECT id FROM likes
      WHERE user_id = $1 AND target_type = $2 AND target_id = $3
    `;

    const result = await db.query(query, [userId, targetType, targetId]);
    return result.rows.length > 0;
  }

  /**
   * Follow a user
   */
  async follow(followerId: number, followingId: number): Promise<Follow> {
    if (followerId === followingId) {
      throw new Error('Cannot follow yourself');
    }

    const query = `
      INSERT INTO follows (follower_id, following_id)
      VALUES ($1, $2)
      ON CONFLICT (follower_id, following_id) DO NOTHING
      RETURNING *
    `;

    const result = await db.query<Follow>(query, [followerId, followingId]);

    if (result.rows.length > 0) {
      // Cache follow relationship
      await cacheUtil.cacheFollow(followerId, followingId);

      // Publish follow event
      await queueUtil.publishFollowCreated(followerId, followingId);

      // Invalidate user cache
      await cacheUtil.invalidateUser(followerId);
      await cacheUtil.invalidateUser(followingId);
    }

    return result.rows[0];
  }

  /**
   * Unfollow a user
   */
  async unfollow(followerId: number, followingId: number): Promise<void> {
    const query = `
      DELETE FROM follows
      WHERE follower_id = $1 AND following_id = $2
    `;

    await db.query(query, [followerId, followingId]);

    // Remove from cache
    await cacheUtil.removeFollow(followerId, followingId);

    // Invalidate user cache
    await cacheUtil.invalidateUser(followerId);
    await cacheUtil.invalidateUser(followingId);
  }

  /**
   * Check if user is following another user
   */
  async isFollowing(followerId: number, followingId: number): Promise<boolean> {
    // Try cache first
    const cached = await cacheUtil.isFollowing(followerId, followingId);
    if (cached !== null) {
      return cached;
    }

    const query = `
      SELECT id FROM follows
      WHERE follower_id = $1 AND following_id = $2
    `;

    const result = await db.query(query, [followerId, followingId]);
    const isFollowing = result.rows.length > 0;

    // Cache the result
    if (isFollowing) {
      await cacheUtil.cacheFollow(followerId, followingId);
    }

    return isFollowing;
  }

  /**
   * Create a comment
   */
  async createComment(data: CreateCommentDTO): Promise<Comment> {
    const query = `
      INSERT INTO comments (
        post_id, author_id, parent_id, content, media_urls, mentions
      )
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `;

    const values = [
      data.post_id,
      data.author_id,
      data.parent_id || null,
      data.content,
      JSON.stringify(data.media_urls || []),
      data.mentions || [],
    ];

    const result = await db.query<Comment>(query, values);
    const comment = result.rows[0];

    // Invalidate post cache
    await cacheUtil.invalidatePost(data.post_id);

    return comment;
  }

  /**
   * Get comments for a post
   */
  async getComments(
    postId: number,
    page: number = 1,
    limit: number = 20
  ): Promise<any> {
    const offset = (page - 1) * limit;

    const query = `
      SELECT
        c.*,
        u.username as author_username,
        u.display_name as author_display_name,
        u.avatar_url as author_avatar
      FROM comments c
      INNER JOIN users u ON c.author_id = u.id
      WHERE c.post_id = $1 AND c.deleted_at IS NULL AND c.parent_id IS NULL
      ORDER BY c.created_at DESC
      LIMIT $2 OFFSET $3
    `;

    const countQuery = `
      SELECT COUNT(*) as total
      FROM comments
      WHERE post_id = $1 AND deleted_at IS NULL AND parent_id IS NULL
    `;

    const [dataResult, countResult] = await Promise.all([
      db.query(query, [postId, limit, offset]),
      db.query<{ total: string }>(countQuery, [postId]),
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
   * Get replies to a comment
   */
  async getReplies(commentId: number): Promise<Comment[]> {
    const query = `
      SELECT
        c.*,
        u.username as author_username,
        u.display_name as author_display_name,
        u.avatar_url as author_avatar
      FROM comments c
      INNER JOIN users u ON c.author_id = u.id
      WHERE c.parent_id = $1 AND c.deleted_at IS NULL
      ORDER BY c.created_at ASC
    `;

    const result = await db.query<Comment>(query, [commentId]);
    return result.rows;
  }

  /**
   * Delete a comment
   */
  async deleteComment(commentId: number, userId: number): Promise<void> {
    const query = `
      UPDATE comments
      SET deleted_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND author_id = $2 AND deleted_at IS NULL
    `;

    await db.query(query, [commentId, userId]);
  }

  /**
   * Bookmark a post
   */
  async bookmarkPost(userId: number, postId: number): Promise<void> {
    const query = `
      INSERT INTO bookmarks (user_id, post_id)
      VALUES ($1, $2)
      ON CONFLICT (user_id, post_id) DO NOTHING
    `;

    await db.query(query, [userId, postId]);
  }

  /**
   * Remove bookmark
   */
  async removeBookmark(userId: number, postId: number): Promise<void> {
    const query = `
      DELETE FROM bookmarks
      WHERE user_id = $1 AND post_id = $2
    `;

    await db.query(query, [userId, postId]);
  }

  /**
   * Get user's bookmarks
   */
  async getBookmarks(userId: number, page: number = 1, limit: number = 20): Promise<any> {
    const offset = (page - 1) * limit;

    const query = `
      SELECT p.*, b.created_at as bookmarked_at
      FROM posts p
      INNER JOIN bookmarks b ON b.post_id = p.id
      WHERE b.user_id = $1 AND p.deleted_at IS NULL
      ORDER BY b.created_at DESC
      LIMIT $2 OFFSET $3
    `;

    const countQuery = `
      SELECT COUNT(*) as total
      FROM bookmarks b
      INNER JOIN posts p ON b.post_id = p.id
      WHERE b.user_id = $1 AND p.deleted_at IS NULL
    `;

    const [dataResult, countResult] = await Promise.all([
      db.query(query, [userId, limit, offset]),
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
}

export default new SocialService();
