/**
 * Author: Aitachi
 * Email: 44158892@qq.com
 * Date: 11-02-2025 17
 */

import esClient from '../config/elasticsearch';
import { SearchParams } from '../types';

/**
 * Search utility class for Elasticsearch operations
 */
class SearchUtil {
  /**
   * Index user document
   */
  async indexUser(userId: number, userData: any): Promise<void> {
    await esClient.indexDocument(
      esClient.constructor['INDICES'].USERS,
      userId.toString(),
      {
        id: userData.id,
        wallet_address: userData.wallet_address,
        username: userData.username,
        display_name: userData.display_name,
        bio: userData.bio,
        verified: userData.verified,
        reputation_score: userData.reputation_score,
        follower_count: userData.follower_count,
        created_at: userData.created_at,
      }
    );
  }

  /**
   * Index post document
   */
  async indexPost(postId: number, postData: any): Promise<void> {
    await esClient.indexDocument(
      esClient.constructor['INDICES'].POSTS,
      postId.toString(),
      {
        id: postData.id,
        author_id: postData.author_id,
        author_username: postData.author_username,
        content: postData.content,
        hashtags: postData.hashtags,
        media_type: postData.media_type,
        visibility: postData.visibility,
        like_count: postData.like_count,
        comment_count: postData.comment_count,
        repost_count: postData.repost_count,
        view_count: postData.view_count,
        created_at: postData.created_at,
        updated_at: postData.updated_at,
      }
    );
  }

  /**
   * Index hashtag document
   */
  async indexHashtag(hashtagId: number, hashtagData: any): Promise<void> {
    await esClient.indexDocument(
      esClient.constructor['INDICES'].HASHTAGS,
      hashtagId.toString(),
      hashtagData
    );
  }

  /**
   * Update user document
   */
  async updateUser(userId: number, updates: any): Promise<void> {
    await esClient.updateDocument(
      esClient.constructor['INDICES'].USERS,
      userId.toString(),
      updates
    );
  }

  /**
   * Update post document
   */
  async updatePost(postId: number, updates: any): Promise<void> {
    await esClient.updateDocument(
      esClient.constructor['INDICES'].POSTS,
      postId.toString(),
      updates
    );
  }

  /**
   * Delete post document
   */
  async deletePost(postId: number): Promise<void> {
    await esClient.deleteDocument(
      esClient.constructor['INDICES'].POSTS,
      postId.toString()
    );
  }

  /**
   * Search users
   */
  async searchUsers(params: SearchParams): Promise<any> {
    const { keyword, page = 1, limit = 20 } = params;
    const from = (page - 1) * limit;
    const results = await esClient.searchUsers(keyword, from, limit);

    return {
      data: results.hits.map((hit: any) => hit._source),
      meta: {
        total: results.total.value,
        page,
        limit,
        totalPages: Math.ceil(results.total.value / limit),
        hasMore: from + limit < results.total.value,
      },
    };
  }

  /**
   * Search posts
   */
  async searchPosts(params: SearchParams): Promise<any> {
    const { keyword, filters, page = 1, limit = 20 } = params;
    const from = (page - 1) * limit;
    const results = await esClient.searchPosts(keyword, from, limit, filters);

    return {
      data: results.hits.map((hit: any) => hit._source),
      meta: {
        total: results.total.value,
        page,
        limit,
        totalPages: Math.ceil(results.total.value / limit),
        hasMore: from + limit < results.total.value,
      },
    };
  }

  /**
   * Search hashtags
   */
  async searchHashtags(params: SearchParams): Promise<any> {
    const { keyword, page = 1, limit = 20 } = params;
    const from = (page - 1) * limit;
    const results = await esClient.searchHashtags(keyword, from, limit);

    return {
      data: results.hits.map((hit: any) => hit._source),
      meta: {
        total: results.total.value,
        page,
        limit,
        totalPages: Math.ceil(results.total.value / limit),
        hasMore: from + limit < results.total.value,
      },
    };
  }

  /**
   * Get user autocomplete suggestions
   */
  async suggestUsers(prefix: string, size: number = 10): Promise<string[]> {
    const results = await esClient.suggestUsers(prefix, size);
    return results.map((result: any) => result.text);
  }

  /**
   * Bulk index posts
   */
  async bulkIndexPosts(posts: any[]): Promise<void> {
    await esClient.bulkIndex(esClient.constructor['INDICES'].POSTS, posts);
  }

  /**
   * Bulk index users
   */
  async bulkIndexUsers(users: any[]): Promise<void> {
    await esClient.bulkIndex(esClient.constructor['INDICES'].USERS, users);
  }
}

export default new SearchUtil();
