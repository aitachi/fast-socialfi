/**
 * Author: Aitachi
 * Email: 44158892@qq.com
 * Date: 11-02-2025 17
 */

import { Router } from 'express';
import userRoutes from './user.routes';
import postRoutes from './post.routes';
import socialRoutes from './social.routes';
import searchRoutes from './search.routes';

const router = Router();

/**
 * API Routes Index
 */

// Mount route modules
router.use('/users', userRoutes);
router.use('/posts', postRoutes);
router.use('/social', socialRoutes);
router.use('/search', searchRoutes);

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({
    success: true,
    data: {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    },
  });
});

// API info endpoint
router.get('/', (req, res) => {
  res.json({
    success: true,
    data: {
      name: 'Fast SocialFi API',
      version: '1.0.0',
      description: 'Decentralized Social Finance Platform Backend',
      endpoints: {
        users: '/api/users',
        posts: '/api/posts',
        social: '/api/social',
        search: '/api/search',
      },
    },
  });
});

export default router;
