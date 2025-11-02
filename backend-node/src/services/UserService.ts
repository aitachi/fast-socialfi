import db from '../config/database';
import { User, CreateUserDTO, UpdateUserDTO, PaginatedResult } from '../types';
import cacheUtil from '../utils/cache';
import searchUtil from '../utils/search';
import queueUtil from '../utils/queue';

/**
 * User Service - Handles all user-related business logic
 */
class UserService {
  /**
   * Create a new user
   */
  async createUser(data: CreateUserDTO): Promise<User> {
    const query = `
      INSERT INTO users (wallet_address, username, display_name, bio, avatar_url)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;

    const values = [
      data.wallet_address,
      data.username || null,
      data.display_name || null,
      data.bio || null,
      data.avatar_url || null,
    ];

    const result = await db.query<User>(query, values);
    const user = result.rows[0];

    // Cache the user
    await cacheUtil.cacheUser(user.id, user);

    // Index user in Elasticsearch
    await searchUtil.indexUser(user.id, user);

    // Publish user registered event
    await queueUtil.publishUserRegistered(user.id, user.wallet_address);

    return user;
  }

  /**
   * Get user by ID
   */
  async getUserById(userId: number): Promise<User | null> {
    // Try cache first
    const cached = await cacheUtil.getUser(userId);
    if (cached) {
      return cached;
    }

    const query = 'SELECT * FROM users WHERE id = $1 AND is_active = true';
    const result = await db.query<User>(query, [userId]);

    if (result.rows.length === 0) {
      return null;
    }

    const user = result.rows[0];
    await cacheUtil.cacheUser(userId, user);

    return user;
  }

  /**
   * Get user by wallet address
   */
  async getUserByWallet(walletAddress: string): Promise<User | null> {
    const query =
      'SELECT * FROM users WHERE wallet_address = $1 AND is_active = true';
    const result = await db.query<User>(query, [walletAddress]);

    return result.rows[0] || null;
  }

  /**
   * Get user by username
   */
  async getUserByUsername(username: string): Promise<User | null> {
    const query = 'SELECT * FROM users WHERE username = $1 AND is_active = true';
    const result = await db.query<User>(query, [username]);

    return result.rows[0] || null;
  }

  /**
   * Update user
   */
  async updateUser(userId: number, data: UpdateUserDTO): Promise<User> {
    const fields: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    if (data.username !== undefined) {
      fields.push(`username = $${paramIndex++}`);
      values.push(data.username);
    }
    if (data.display_name !== undefined) {
      fields.push(`display_name = $${paramIndex++}`);
      values.push(data.display_name);
    }
    if (data.bio !== undefined) {
      fields.push(`bio = $${paramIndex++}`);
      values.push(data.bio);
    }
    if (data.avatar_url !== undefined) {
      fields.push(`avatar_url = $${paramIndex++}`);
      values.push(data.avatar_url);
    }
    if (data.cover_url !== undefined) {
      fields.push(`cover_url = $${paramIndex++}`);
      values.push(data.cover_url);
    }
    if (data.email !== undefined) {
      fields.push(`email = $${paramIndex++}`);
      values.push(data.email);
    }

    if (fields.length === 0) {
      const user = await this.getUserById(userId);
      if (!user) throw new Error('User not found');
      return user;
    }

    values.push(userId);
    const query = `
      UPDATE users
      SET ${fields.join(', ')}, updated_at = CURRENT_TIMESTAMP
      WHERE id = $${paramIndex}
      RETURNING *
    `;

    const result = await db.query<User>(query, values);
    const user = result.rows[0];

    // Invalidate cache
    await cacheUtil.invalidateUser(userId);

    // Update search index
    await searchUtil.updateUser(userId, user);

    return user;
  }

  /**
   * Get user's followers
   */
  async getFollowers(
    userId: number,
    page: number = 1,
    limit: number = 20
  ): Promise<PaginatedResult<User>> {
    const offset = (page - 1) * limit;

    const query = `
      SELECT u.*
      FROM users u
      INNER JOIN follows f ON f.follower_id = u.id
      WHERE f.following_id = $1 AND u.is_active = true
      ORDER BY f.created_at DESC
      LIMIT $2 OFFSET $3
    `;

    const countQuery = `
      SELECT COUNT(*) as total
      FROM follows f
      INNER JOIN users u ON f.follower_id = u.id
      WHERE f.following_id = $1 AND u.is_active = true
    `;

    const [dataResult, countResult] = await Promise.all([
      db.query<User>(query, [userId, limit, offset]),
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
   * Get user's following
   */
  async getFollowing(
    userId: number,
    page: number = 1,
    limit: number = 20
  ): Promise<PaginatedResult<User>> {
    const offset = (page - 1) * limit;

    const query = `
      SELECT u.*
      FROM users u
      INNER JOIN follows f ON f.following_id = u.id
      WHERE f.follower_id = $1 AND u.is_active = true
      ORDER BY f.created_at DESC
      LIMIT $2 OFFSET $3
    `;

    const countQuery = `
      SELECT COUNT(*) as total
      FROM follows f
      INNER JOIN users u ON f.following_id = u.id
      WHERE f.follower_id = $1 AND u.is_active = true
    `;

    const [dataResult, countResult] = await Promise.all([
      db.query<User>(query, [userId, limit, offset]),
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
   * Update last login time
   */
  async updateLastLogin(userId: number): Promise<void> {
    const query = `
      UPDATE users
      SET last_login_at = CURRENT_TIMESTAMP
      WHERE id = $1
    `;
    await db.query(query, [userId]);
    await cacheUtil.invalidateUser(userId);
  }

  /**
   * Check if username is available
   */
  async isUsernameAvailable(username: string): Promise<boolean> {
    const query = 'SELECT id FROM users WHERE username = $1';
    const result = await db.query(query, [username]);
    return result.rows.length === 0;
  }

  /**
   * Get user statistics
   */
  async getUserStats(userId: number): Promise<any> {
    const query = `
      SELECT
        follower_count,
        following_count,
        post_count,
        reputation_score,
        (SELECT COUNT(*) FROM likes l
         INNER JOIN posts p ON l.target_id = p.id
         WHERE l.target_type = 'post' AND p.author_id = $1) as total_likes_received,
        (SELECT COUNT(*) FROM comments c
         INNER JOIN posts p ON c.post_id = p.id
         WHERE p.author_id = $1) as total_comments_received
      FROM users
      WHERE id = $1
    `;

    const result = await db.query(query, [userId]);
    return result.rows[0];
  }
}

export default new UserService();
