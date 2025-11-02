/**
 * Author: Aitachi
 * Email: 44158892@qq.com
 * Date: 11-02-2025 17
 */

import { createClient, RedisClientType } from 'redis';
import dotenv from 'dotenv';

dotenv.config();

/**
 * Redis Cache Configuration and Connection Manager
 */
class RedisClient {
  private static instance: RedisClient;
  private client: RedisClientType;
  private isConnected: boolean = false;

  private constructor() {
    this.client = createClient({
      socket: {
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379'),
      },
      password: process.env.REDIS_PASSWORD || undefined,
      database: parseInt(process.env.REDIS_DB || '0'),
    });

    this.setupEventHandlers();
    this.connect();
  }

  /**
   * Setup event handlers
   */
  private setupEventHandlers(): void {
    this.client.on('connect', () => {
      console.log('Redis client connecting...');
    });

    this.client.on('ready', () => {
      console.log('Redis client ready');
      this.isConnected = true;
    });

    this.client.on('error', (err) => {
      console.error('Redis client error:', err);
      this.isConnected = false;
    });

    this.client.on('end', () => {
      console.log('Redis client disconnected');
      this.isConnected = false;
    });

    this.client.on('reconnecting', () => {
      console.log('Redis client reconnecting...');
    });
  }

  /**
   * Connect to Redis
   */
  private async connect(): Promise<void> {
    try {
      await this.client.connect();
    } catch (error) {
      console.error('Failed to connect to Redis:', error);
    }
  }

  /**
   * Get singleton instance
   */
  public static getInstance(): RedisClient {
    if (!RedisClient.instance) {
      RedisClient.instance = new RedisClient();
    }
    return RedisClient.instance;
  }

  /**
   * Get Redis client
   */
  public getClient(): RedisClientType {
    return this.client;
  }

  /**
   * Set value with optional TTL
   */
  public async set(
    key: string,
    value: string,
    ttl?: number
  ): Promise<string | null> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    if (ttl) {
      return await this.client.setEx(key, ttl, value);
    }
    return await this.client.set(key, value);
  }

  /**
   * Get value
   */
  public async get(key: string): Promise<string | null> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return await this.client.get(key);
  }

  /**
   * Delete key
   */
  public async del(key: string): Promise<number> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return await this.client.del(key);
  }

  /**
   * Check if key exists
   */
  public async exists(key: string): Promise<number> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return await this.client.exists(key);
  }

  /**
   * Set JSON object
   */
  public async setJSON(
    key: string,
    value: any,
    ttl?: number
  ): Promise<string | null> {
    return await this.set(key, JSON.stringify(value), ttl);
  }

  /**
   * Get JSON object
   */
  public async getJSON<T = any>(key: string): Promise<T | null> {
    const value = await this.get(key);
    return value ? JSON.parse(value) : null;
  }

  /**
   * Increment counter
   */
  public async incr(key: string): Promise<number> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return await this.client.incr(key);
  }

  /**
   * Decrement counter
   */
  public async decr(key: string): Promise<number> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return await this.client.decr(key);
  }

  /**
   * Add to sorted set
   */
  public async zadd(
    key: string,
    score: number,
    member: string
  ): Promise<number> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return await this.client.zAdd(key, { score, value: member });
  }

  /**
   * Get sorted set range
   */
  public async zrange(
    key: string,
    start: number,
    stop: number
  ): Promise<string[]> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return await this.client.zRange(key, start, stop);
  }

  /**
   * Get sorted set range with scores (descending)
   */
  public async zrevrange(
    key: string,
    start: number,
    stop: number
  ): Promise<string[]> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return await this.client.zRange(key, start, stop, { REV: true });
  }

  /**
   * Add to set
   */
  public async sadd(key: string, ...members: string[]): Promise<number> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return await this.client.sAdd(key, members);
  }

  /**
   * Remove from set
   */
  public async srem(key: string, ...members: string[]): Promise<number> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return await this.client.sRem(key, members);
  }

  /**
   * Check if member exists in set
   */
  public async sismember(key: string, member: string): Promise<boolean> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return await this.client.sIsMember(key, member);
  }

  /**
   * Get all members of set
   */
  public async smembers(key: string): Promise<string[]> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return await this.client.sMembers(key);
  }

  /**
   * Set expiration time
   */
  public async expire(key: string, seconds: number): Promise<boolean> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return await this.client.expire(key, seconds);
  }

  /**
   * Flush all data (use with caution!)
   */
  public async flushAll(): Promise<string> {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return await this.client.flushAll();
  }

  /**
   * Test Redis connection
   */
  public async testConnection(): Promise<boolean> {
    try {
      const pong = await this.client.ping();
      console.log('Redis connection test successful:', pong);
      return true;
    } catch (error) {
      console.error('Redis connection test failed:', error);
      return false;
    }
  }

  /**
   * Close connection
   */
  public async close(): Promise<void> {
    await this.client.quit();
    console.log('Redis connection closed');
  }

  /**
   * Check if connected
   */
  public get connected(): boolean {
    return this.isConnected;
  }
}

export default RedisClient.getInstance();
