/**
 * Author: Aitachi
 * Email: 44158892@qq.com
 * Date: 11-02-2025 17
 */

import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import dotenv from 'dotenv';

// Import configurations
import db from './config/database';
import redisClient from './config/redis';
import kafkaClient from './config/kafka';
import esClient from './config/elasticsearch';

// Import routes
import routes from './routes';

// Import middlewares
import { apiLimiter } from './middlewares/rateLimit';

// Load environment variables
dotenv.config();

/**
 * Express Application Setup
 */
class App {
  public app: Express;
  private port: number;

  constructor() {
    this.app = express();
    this.port = parseInt(process.env.PORT || '3000');

    this.initializeMiddlewares();
    this.initializeRoutes();
    this.initializeErrorHandling();
  }

  /**
   * Initialize middlewares
   */
  private initializeMiddlewares(): void {
    // Security middleware
    this.app.use(helmet());

    // CORS configuration
    const corsOptions = {
      origin: (process.env.CORS_ORIGIN || 'http://localhost:5173').split(','),
      credentials: true,
      optionsSuccessStatus: 200,
    };
    this.app.use(cors(corsOptions));

    // Body parsing middleware
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true, limit: '10mb' }));

    // Compression middleware
    this.app.use(compression());

    // Logging middleware
    if (process.env.NODE_ENV === 'development') {
      this.app.use(morgan('dev'));
    } else {
      this.app.use(morgan('combined'));
    }

    // Rate limiting
    this.app.use('/api', apiLimiter);
  }

  /**
   * Initialize routes
   */
  private initializeRoutes(): void {
    // API routes
    this.app.use('/api', routes);

    // Root endpoint
    this.app.get('/', (req: Request, res: Response) => {
      res.json({
        success: true,
        data: {
          name: 'Fast SocialFi Backend API',
          version: '1.0.0',
          status: 'running',
          timestamp: new Date().toISOString(),
        },
      });
    });

    // 404 handler
    this.app.use((req: Request, res: Response) => {
      res.status(404).json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Endpoint not found',
        },
      });
    });
  }

  /**
   * Initialize error handling
   */
  private initializeErrorHandling(): void {
    this.app.use(
      (err: Error, req: Request, res: Response, next: NextFunction) => {
        console.error('Error:', err);

        res.status(500).json({
          success: false,
          error: {
            code: 'INTERNAL_SERVER_ERROR',
            message:
              process.env.NODE_ENV === 'development'
                ? err.message
                : 'Internal server error',
          },
        });
      }
    );
  }

  /**
   * Initialize database connections
   */
  private async initializeConnections(): Promise<void> {
    console.log('Initializing database connections...');

    try {
      // Test PostgreSQL connection
      const dbConnected = await db.testConnection();
      console.log(
        `PostgreSQL: ${dbConnected ? 'Connected' : 'Connection failed'}`
      );

      // Test Redis connection
      const redisConnected = await redisClient.testConnection();
      console.log(
        `Redis: ${redisConnected ? 'Connected' : 'Connection failed'}`
      );

      // Initialize Elasticsearch
      await esClient.initialize();
      const esConnected = await esClient.testConnection();
      console.log(
        `Elasticsearch: ${esConnected ? 'Connected' : 'Connection failed'}`
      );

      // Initialize Kafka
      await kafkaClient.initialize();
      const kafkaConnected = await kafkaClient.testConnection();
      console.log(`Kafka: ${kafkaConnected ? 'Connected' : 'Connection failed'}`);

      console.log('All database connections initialized');
    } catch (error) {
      console.error('Failed to initialize connections:', error);
      throw error;
    }
  }

  /**
   * Start the server
   */
  public async start(): Promise<void> {
    try {
      // Initialize connections
      await this.initializeConnections();

      // Start listening
      this.app.listen(this.port, () => {
        console.log('');
        console.log('========================================');
        console.log('  Fast SocialFi Backend API Started');
        console.log('========================================');
        console.log(`  Port: ${this.port}`);
        console.log(`  Environment: ${process.env.NODE_ENV || 'development'}`);
        console.log(`  API URL: http://localhost:${this.port}/api`);
        console.log('========================================');
        console.log('');
      });
    } catch (error) {
      console.error('Failed to start server:', error);
      process.exit(1);
    }
  }

  /**
   * Graceful shutdown
   */
  public async shutdown(): Promise<void> {
    console.log('Shutting down gracefully...');

    try {
      await db.close();
      await redisClient.close();
      await kafkaClient.disconnect();
      await esClient.close();

      console.log('All connections closed');
      process.exit(0);
    } catch (error) {
      console.error('Error during shutdown:', error);
      process.exit(1);
    }
  }
}

// Create and export app instance
const app = new App();

// Handle graceful shutdown
process.on('SIGTERM', () => app.shutdown());
process.on('SIGINT', () => app.shutdown());

// Start the server
if (require.main === module) {
  app.start();
}

export default app;
