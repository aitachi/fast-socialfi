/**
 * Author: Aitachi
 * Email: 44158892@qq.com
 * Date: 11-02-2025 17
 */

import redisClient from '../config/redis';
import { CacheOptions } from '../types';

/**
 * Cache utility class for Redis operations
 */
class CacheUtil {
  private readonly DEFAULT_TTL = 3600; // 1 hour
  private readonly PREFIX = 'socialfi:';

  /**
   * Generate cache key with prefix
   */
  private getKey(key: string, prefix?: string): string {
    const finalPrefix = prefix || this.PREFIX;
    return `${finalPrefix}${key}`;
  }

  /**
   * Set cache value
   */
  async set(
    key: string,
    value: any,
    options?: CacheOptions
  ): Promise<void> {
    const cacheKey = this.getKey(key, options?.prefix);
    const ttl = options?.ttl || this.DEFAULT_TTL;
    await redisClient.setJSON(cacheKey, value, ttl);
  }

  /**
   * Get cache value
   */
  async get<T = any>(key: string, prefix?: string): Promise<T | null> {
    const cacheKey = this.getKey(key, prefix);
    return await redisClient.getJSON<T>(cacheKey);
  }

  /**
   * Delete cache value
   */
  async del(key: string, prefix?: string): Promise<void> {
    const cacheKey = this.getKey(key, prefix);
    await redisClient.del(cacheKey);
  }

  /**
   * Cache user data
   */
  async cacheUser(userId: number, userData: any, ttl?: number): Promise<void> {
    await this.set(`user:${userId}`, userData, { ttl, prefix: this.PREFIX });
  }

  /**
   * Get cached user data
   */
  async getUser(userId: number): Promise<any> {
    return await this.get(`user:${userId}`);
  }

  /**
   * Cache post data
   */
  async cachePost(postId: number, postData: any, ttl?: number): Promise<void> {
    await this.set(`post:${postId}`, postData, { ttl, prefix: this.PREFIX });
  }

  /**
   * Get cached post data
   */
  async getPost(postId: number): Promise<any> {
    return await this.get(`post:${postId}`);
  }

  /**
   * Cache feed data
   */
  async cacheFeed(
    userId: number,
    feedData: any[],
    ttl: number = 300
  ): Promise<void> {
    await this.set(`feed:${userId}`, feedData, { ttl, prefix: this.PREFIX });
  }

  /**
   * Get cached feed data
   */
  async getFeed(userId: number): Promise<any[] | null> {
    return await this.get(`feed:${userId}`);
  }

  /**
   * Increment counter
   */
  async incrementCounter(key: string, prefix?: string): Promise<number> {
    const cacheKey = this.getKey(key, prefix);
    return await redisClient.incr(cacheKey);
  }

  /**
   * Decrement counter
   */
  async decrementCounter(key: string, prefix?: string): Promise<number> {
    const cacheKey = this.getKey(key, prefix);
    return await redisClient.decr(cacheKey);
  }

  /**
   * Add to sorted set (for leaderboards/rankings)
   */
  async addToLeaderboard(
    leaderboardKey: string,
    userId: number,
    score: number
  ): Promise<void> {
    const key = this.getKey(`leaderboard:${leaderboardKey}`);
    await redisClient.zadd(key, score, userId.toString());
  }

  /**
   * Get leaderboard
   */
  async getLeaderboard(
    leaderboardKey: string,
    start: number = 0,
    stop: number = 9
  ): Promise<string[]> {
    const key = this.getKey(`leaderboard:${leaderboardKey}`);
    return await redisClient.zrevrange(key, start, stop);
  }

  /**
   * Check if user is following another user (using Set)
   */
  async isFollowing(followerId: number, followingId: number): Promise<boolean> {
    const key = this.getKey(`user:${followerId}:following`);
    return await redisClient.sismember(key, followingId.toString());
  }

  /**
   * Add follow relationship to cache
   */
  async cacheFollow(followerId: number, followingId: number): Promise<void> {
    const followerKey = this.getKey(`user:${followerId}:following`);
    const followingKey = this.getKey(`user:${followingId}:followers`);
    await redisClient.sadd(followerKey, followingId.toString());
    await redisClient.sadd(followingKey, followerId.toString());
  }

  /**
   * Remove follow relationship from cache
   */
  async removeFollow(followerId: number, followingId: number): Promise<void> {
    const followerKey = this.getKey(`user:${followerId}:following`);
    const followingKey = this.getKey(`user:${followingId}:followers`);
    await redisClient.srem(followerKey, followingId.toString());
    await redisClient.srem(followingKey, followerId.toString());
  }

  /**
   * Invalidate user cache
   */
  async invalidateUser(userId: number): Promise<void> {
    await this.del(`user:${userId}`);
    await this.del(`feed:${userId}`);
  }

  /**
   * Invalidate post cache
   */
  async invalidatePost(postId: number): Promise<void> {
    await this.del(`post:${postId}`);
  }
}

export default new CacheUtil();
