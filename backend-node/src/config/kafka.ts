import { Kafka, Producer, Consumer, Admin, logLevel } from 'kafkajs';
import dotenv from 'dotenv';

dotenv.config();

/**
 * Kafka Message Queue Configuration and Manager
 */
class KafkaClient {
  private static instance: KafkaClient;
  private kafka: Kafka;
  private producer: Producer | null = null;
  private consumers: Map<string, Consumer> = new Map();
  private admin: Admin;

  // Topic names
  public static readonly TOPICS = {
    USER_REGISTERED: 'user.registered',
    USER_UPDATED: 'user.updated',
    POST_CREATED: 'post.created',
    POST_UPDATED: 'post.updated',
    POST_DELETED: 'post.deleted',
    COMMENT_CREATED: 'comment.created',
    LIKE_CREATED: 'like.created',
    FOLLOW_CREATED: 'follow.created',
    NOTIFICATION_CREATED: 'notification.created',
    TRANSACTION_CREATED: 'transaction.created',
  };

  private constructor() {
    const brokers = (process.env.KAFKA_BROKERS || 'localhost:9092').split(',');
    const clientId = process.env.KAFKA_CLIENT_ID || 'fast-socialfi-backend';

    this.kafka = new Kafka({
      clientId,
      brokers,
      logLevel: logLevel.INFO,
      retry: {
        initialRetryTime: 100,
        retries: 8,
      },
    });

    this.admin = this.kafka.admin();
  }

  /**
   * Get singleton instance
   */
  public static getInstance(): KafkaClient {
    if (!KafkaClient.instance) {
      KafkaClient.instance = new KafkaClient();
    }
    return KafkaClient.instance;
  }

  /**
   * Initialize Kafka (create topics)
   */
  public async initialize(): Promise<void> {
    try {
      await this.admin.connect();
      console.log('Kafka admin connected');

      // Create topics if they don't exist
      const topics = Object.values(KafkaClient.TOPICS).map((topic) => ({
        topic,
        numPartitions: 3,
        replicationFactor: 1,
      }));

      await this.admin.createTopics({
        topics,
        waitForLeaders: true,
      });

      console.log('Kafka topics created/verified');
      await this.admin.disconnect();
    } catch (error) {
      console.error('Failed to initialize Kafka:', error);
    }
  }

  /**
   * Get or create producer
   */
  private async getProducer(): Promise<Producer> {
    if (!this.producer) {
      this.producer = this.kafka.producer({
        allowAutoTopicCreation: true,
        transactionTimeout: 30000,
      });

      this.producer.on('producer.connect', () => {
        console.log('Kafka producer connected');
      });

      this.producer.on('producer.disconnect', () => {
        console.log('Kafka producer disconnected');
      });

      await this.producer.connect();
    }
    return this.producer;
  }

  /**
   * Send message to topic
   */
  public async sendMessage(
    topic: string,
    message: any,
    key?: string
  ): Promise<void> {
    try {
      const producer = await this.getProducer();
      await producer.send({
        topic,
        messages: [
          {
            key: key || Date.now().toString(),
            value: JSON.stringify(message),
            timestamp: Date.now().toString(),
          },
        ],
      });
      console.log(`Message sent to topic ${topic}`);
    } catch (error) {
      console.error('Failed to send Kafka message:', error);
      throw error;
    }
  }

  /**
   * Send batch messages
   */
  public async sendBatch(
    topic: string,
    messages: any[],
    keyPrefix?: string
  ): Promise<void> {
    try {
      const producer = await this.getProducer();
      await producer.send({
        topic,
        messages: messages.map((msg, index) => ({
          key: keyPrefix ? `${keyPrefix}-${index}` : index.toString(),
          value: JSON.stringify(msg),
          timestamp: Date.now().toString(),
        })),
      });
      console.log(`Batch of ${messages.length} messages sent to topic ${topic}`);
    } catch (error) {
      console.error('Failed to send Kafka batch:', error);
      throw error;
    }
  }

  /**
   * Create consumer and subscribe to topics
   */
  public async createConsumer(
    groupId: string,
    topics: string[],
    handler: (topic: string, message: any) => Promise<void>
  ): Promise<void> {
    try {
      const consumer = this.kafka.consumer({
        groupId: groupId || process.env.KAFKA_GROUP_ID || 'socialfi-consumer-group',
        sessionTimeout: 30000,
        heartbeatInterval: 3000,
      });

      await consumer.connect();
      await consumer.subscribe({ topics, fromBeginning: false });

      await consumer.run({
        eachMessage: async ({ topic, partition, message }) => {
          try {
            const value = message.value?.toString();
            if (value) {
              const data = JSON.parse(value);
              await handler(topic, data);
            }
          } catch (error) {
            console.error(
              `Error processing message from topic ${topic}:`,
              error
            );
          }
        },
      });

      this.consumers.set(groupId, consumer);
      console.log(`Consumer ${groupId} created and subscribed to:`, topics);
    } catch (error) {
      console.error('Failed to create Kafka consumer:', error);
      throw error;
    }
  }

  /**
   * Publish user registered event
   */
  public async publishUserRegistered(userId: number, walletAddress: string): Promise<void> {
    await this.sendMessage(KafkaClient.TOPICS.USER_REGISTERED, {
      userId,
      walletAddress,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Publish post created event
   */
  public async publishPostCreated(postId: number, authorId: number): Promise<void> {
    await this.sendMessage(KafkaClient.TOPICS.POST_CREATED, {
      postId,
      authorId,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Publish like created event
   */
  public async publishLikeCreated(
    userId: number,
    targetType: string,
    targetId: number
  ): Promise<void> {
    await this.sendMessage(KafkaClient.TOPICS.LIKE_CREATED, {
      userId,
      targetType,
      targetId,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Publish follow created event
   */
  public async publishFollowCreated(followerId: number, followingId: number): Promise<void> {
    await this.sendMessage(KafkaClient.TOPICS.FOLLOW_CREATED, {
      followerId,
      followingId,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Publish notification created event
   */
  public async publishNotificationCreated(notification: any): Promise<void> {
    await this.sendMessage(KafkaClient.TOPICS.NOTIFICATION_CREATED, notification);
  }

  /**
   * Test Kafka connection
   */
  public async testConnection(): Promise<boolean> {
    try {
      await this.admin.connect();
      const topics = await this.admin.listTopics();
      console.log('Kafka connection test successful. Topics:', topics);
      await this.admin.disconnect();
      return true;
    } catch (error) {
      console.error('Kafka connection test failed:', error);
      return false;
    }
  }

  /**
   * Disconnect all consumers and producer
   */
  public async disconnect(): Promise<void> {
    try {
      // Disconnect all consumers
      for (const [groupId, consumer] of this.consumers) {
        await consumer.disconnect();
        console.log(`Consumer ${groupId} disconnected`);
      }
      this.consumers.clear();

      // Disconnect producer
      if (this.producer) {
        await this.producer.disconnect();
        console.log('Kafka producer disconnected');
        this.producer = null;
      }

      console.log('Kafka client disconnected');
    } catch (error) {
      console.error('Error disconnecting Kafka client:', error);
    }
  }
}

export default KafkaClient.getInstance();
