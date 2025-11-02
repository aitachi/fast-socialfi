/**
 * Author: Aitachi
 * Email: 44158892@qq.com
 * Date: 11-02-2025 17
 */

import { Client } from '@elastic/elasticsearch';
import dotenv from 'dotenv';

dotenv.config();

/**
 * Elasticsearch Configuration and Search Manager
 */
class ElasticsearchClient {
  private static instance: ElasticsearchClient;
  private client: Client;

  // Index names
  public static readonly INDICES = {
    USERS: 'users',
    POSTS: 'posts',
    HASHTAGS: 'hashtags',
  };

  private constructor() {
    this.client = new Client({
      node: process.env.ES_NODE || 'http://localhost:9200',
      auth:
        process.env.ES_USERNAME && process.env.ES_PASSWORD
          ? {
              username: process.env.ES_USERNAME,
              password: process.env.ES_PASSWORD,
            }
          : undefined,
      maxRetries: 5,
      requestTimeout: 60000,
      sniffOnStart: false,
    });
  }

  /**
   * Get singleton instance
   */
  public static getInstance(): ElasticsearchClient {
    if (!ElasticsearchClient.instance) {
      ElasticsearchClient.instance = new ElasticsearchClient();
    }
    return ElasticsearchClient.instance;
  }

  /**
   * Get Elasticsearch client
   */
  public getClient(): Client {
    return this.client;
  }

  /**
   * Initialize indices with mappings
   */
  public async initialize(): Promise<void> {
    try {
      // Create users index
      await this.createIndexIfNotExists(ElasticsearchClient.INDICES.USERS, {
        properties: {
          id: { type: 'long' },
          wallet_address: { type: 'keyword' },
          username: {
            type: 'text',
            fields: {
              keyword: { type: 'keyword' },
              suggest: { type: 'completion' },
            },
          },
          display_name: {
            type: 'text',
            fields: {
              keyword: { type: 'keyword' },
            },
          },
          bio: { type: 'text' },
          verified: { type: 'boolean' },
          reputation_score: { type: 'integer' },
          follower_count: { type: 'integer' },
          created_at: { type: 'date' },
        },
      });

      // Create posts index
      await this.createIndexIfNotExists(ElasticsearchClient.INDICES.POSTS, {
        properties: {
          id: { type: 'long' },
          author_id: { type: 'long' },
          author_username: { type: 'keyword' },
          content: { type: 'text' },
          hashtags: { type: 'keyword' },
          media_type: { type: 'keyword' },
          visibility: { type: 'keyword' },
          like_count: { type: 'integer' },
          comment_count: { type: 'integer' },
          repost_count: { type: 'integer' },
          view_count: { type: 'integer' },
          created_at: { type: 'date' },
          updated_at: { type: 'date' },
        },
      });

      // Create hashtags index
      await this.createIndexIfNotExists(ElasticsearchClient.INDICES.HASHTAGS, {
        properties: {
          id: { type: 'long' },
          tag: {
            type: 'text',
            fields: {
              keyword: { type: 'keyword' },
              suggest: { type: 'completion' },
            },
          },
          tag_normalized: { type: 'keyword' },
          post_count: { type: 'integer' },
          trend_score: { type: 'float' },
          description: { type: 'text' },
          created_at: { type: 'date' },
        },
      });

      console.log('Elasticsearch indices initialized');
    } catch (error) {
      console.error('Failed to initialize Elasticsearch indices:', error);
    }
  }

  /**
   * Create index if it doesn't exist
   */
  private async createIndexIfNotExists(
    index: string,
    mappings: any
  ): Promise<void> {
    try {
      const exists = await this.client.indices.exists({ index });
      if (!exists) {
        await this.client.indices.create({
          index,
          body: {
            mappings,
            settings: {
              number_of_shards: 1,
              number_of_replicas: 0,
            },
          },
        });
        console.log(`Index ${index} created`);
      } else {
        console.log(`Index ${index} already exists`);
      }
    } catch (error) {
      console.error(`Failed to create index ${index}:`, error);
    }
  }

  /**
   * Index a document
   */
  public async indexDocument(
    index: string,
    id: string,
    document: any
  ): Promise<void> {
    try {
      await this.client.index({
        index,
        id,
        body: document,
        refresh: 'true',
      });
      console.log(`Document indexed in ${index} with id ${id}`);
    } catch (error) {
      console.error('Failed to index document:', error);
      throw error;
    }
  }

  /**
   * Bulk index documents
   */
  public async bulkIndex(index: string, documents: any[]): Promise<void> {
    try {
      const body = documents.flatMap((doc) => [
        { index: { _index: index, _id: doc.id } },
        doc,
      ]);

      const result = await this.client.bulk({ body, refresh: 'true' });
      console.log(
        `Bulk indexed ${documents.length} documents in ${index}. Errors: ${result.errors}`
      );
    } catch (error) {
      console.error('Failed to bulk index:', error);
      throw error;
    }
  }

  /**
   * Update a document
   */
  public async updateDocument(
    index: string,
    id: string,
    document: any
  ): Promise<void> {
    try {
      await this.client.update({
        index,
        id,
        body: {
          doc: document,
        },
        refresh: 'true',
      });
      console.log(`Document ${id} updated in ${index}`);
    } catch (error) {
      console.error('Failed to update document:', error);
      throw error;
    }
  }

  /**
   * Delete a document
   */
  public async deleteDocument(index: string, id: string): Promise<void> {
    try {
      await this.client.delete({
        index,
        id,
        refresh: 'true',
      });
      console.log(`Document ${id} deleted from ${index}`);
    } catch (error) {
      console.error('Failed to delete document:', error);
      throw error;
    }
  }

  /**
   * Search documents
   */
  public async search(index: string, query: any): Promise<any> {
    try {
      const result = await this.client.search({
        index,
        body: query,
      });
      return result.hits;
    } catch (error) {
      console.error('Search failed:', error);
      throw error;
    }
  }

  /**
   * Search users
   */
  public async searchUsers(
    keyword: string,
    from: number = 0,
    size: number = 20
  ): Promise<any> {
    const query = {
      from,
      size,
      query: {
        multi_match: {
          query: keyword,
          fields: ['username^3', 'display_name^2', 'bio'],
          fuzziness: 'AUTO',
        },
      },
      sort: [
        { _score: 'desc' },
        { follower_count: 'desc' },
        { reputation_score: 'desc' },
      ],
    };
    return await this.search(ElasticsearchClient.INDICES.USERS, query);
  }

  /**
   * Search posts
   */
  public async searchPosts(
    keyword: string,
    from: number = 0,
    size: number = 20,
    filters?: any
  ): Promise<any> {
    const mustClauses: any[] = [
      {
        multi_match: {
          query: keyword,
          fields: ['content^2', 'hashtags'],
          fuzziness: 'AUTO',
        },
      },
    ];

    if (filters?.hashtag) {
      mustClauses.push({
        term: { hashtags: filters.hashtag },
      });
    }

    if (filters?.author_id) {
      mustClauses.push({
        term: { author_id: filters.author_id },
      });
    }

    const query = {
      from,
      size,
      query: {
        bool: {
          must: mustClauses,
        },
      },
      sort: [{ _score: 'desc' }, { created_at: 'desc' }],
    };

    return await this.search(ElasticsearchClient.INDICES.POSTS, query);
  }

  /**
   * Search hashtags
   */
  public async searchHashtags(
    keyword: string,
    from: number = 0,
    size: number = 20
  ): Promise<any> {
    const query = {
      from,
      size,
      query: {
        multi_match: {
          query: keyword,
          fields: ['tag^3', 'description'],
          fuzziness: 'AUTO',
        },
      },
      sort: [{ _score: 'desc' }, { trend_score: 'desc' }, { post_count: 'desc' }],
    };
    return await this.search(ElasticsearchClient.INDICES.HASHTAGS, query);
  }

  /**
   * Get autocomplete suggestions for users
   */
  public async suggestUsers(prefix: string, size: number = 10): Promise<any> {
    try {
      const result = await this.client.search({
        index: ElasticsearchClient.INDICES.USERS,
        body: {
          suggest: {
            user_suggest: {
              prefix,
              completion: {
                field: 'username.suggest',
                size,
                skip_duplicates: true,
              },
            },
          },
        },
      });
      return result.suggest?.user_suggest[0]?.options || [];
    } catch (error) {
      console.error('Autocomplete failed:', error);
      throw error;
    }
  }

  /**
   * Test Elasticsearch connection
   */
  public async testConnection(): Promise<boolean> {
    try {
      const info = await this.client.info();
      console.log('Elasticsearch connection test successful:', info);
      return true;
    } catch (error) {
      console.error('Elasticsearch connection test failed:', error);
      return false;
    }
  }

  /**
   * Close connection
   */
  public async close(): Promise<void> {
    await this.client.close();
    console.log('Elasticsearch connection closed');
  }
}

export default ElasticsearchClient.getInstance();
