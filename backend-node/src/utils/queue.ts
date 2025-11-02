/**
 * Author: Aitachi
 * Email: 44158892@qq.com
 * Date: 11-02-2025 17
 */

import kafkaClient from '../config/kafka';

/**
 * Queue utility class for Kafka operations
 */
class QueueUtil {
  /**
   * Publish user registered event
   */
  async publishUserRegistered(
    userId: number,
    walletAddress: string
  ): Promise<void> {
    await kafkaClient.publishUserRegistered(userId, walletAddress);
  }

  /**
   * Publish post created event
   */
  async publishPostCreated(postId: number, authorId: number): Promise<void> {
    await kafkaClient.publishPostCreated(postId, authorId);
  }

  /**
   * Publish like created event
   */
  async publishLikeCreated(
    userId: number,
    targetType: string,
    targetId: number
  ): Promise<void> {
    await kafkaClient.publishLikeCreated(userId, targetType, targetId);
  }

  /**
   * Publish follow created event
   */
  async publishFollowCreated(
    followerId: number,
    followingId: number
  ): Promise<void> {
    await kafkaClient.publishFollowCreated(followerId, followingId);
  }

  /**
   * Publish notification created event
   */
  async publishNotification(notification: any): Promise<void> {
    await kafkaClient.publishNotificationCreated(notification);
  }

  /**
   * Send custom event
   */
  async sendEvent(topic: string, event: any, key?: string): Promise<void> {
    await kafkaClient.sendMessage(topic, event, key);
  }

  /**
   * Setup event consumers
   */
  async setupConsumers(): Promise<void> {
    // Consumer for processing notifications
    await kafkaClient.createConsumer(
      'notification-processor',
      [
        kafkaClient.constructor['TOPICS'].LIKE_CREATED,
        kafkaClient.constructor['TOPICS'].COMMENT_CREATED,
        kafkaClient.constructor['TOPICS'].FOLLOW_CREATED,
      ],
      async (topic: string, message: any) => {
        console.log(`Processing ${topic}:`, message);
        // Here you would process the event and create notifications
        // This is a placeholder - actual implementation would call NotificationService
      }
    );

    // Consumer for indexing posts to Elasticsearch
    await kafkaClient.createConsumer(
      'search-indexer',
      [
        kafkaClient.constructor['TOPICS'].POST_CREATED,
        kafkaClient.constructor['TOPICS'].POST_UPDATED,
        kafkaClient.constructor['TOPICS'].USER_UPDATED,
      ],
      async (topic: string, message: any) => {
        console.log(`Indexing ${topic}:`, message);
        // Here you would index the document to Elasticsearch
        // This is a placeholder - actual implementation would call SearchUtil
      }
    );
  }
}

export default new QueueUtil();
