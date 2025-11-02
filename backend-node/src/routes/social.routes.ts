import { Router } from 'express';
import socialService from '../services/SocialService';
import { authenticate } from '../middlewares/auth';
import { Request, Response } from 'express';

const router = Router();

/**
 * Social Routes - Follow, Like, Comment, Bookmark
 */

// Follow operations
router.post('/follow/:userId', authenticate, async (req: Request, res: Response) => {
  try {
    const followerId = req.user!.userId;
    const followingId = parseInt(req.params.userId);

    await socialService.follow(followerId, followingId);

    res.json({
      success: true,
      data: {
        message: 'User followed successfully',
      },
    });
  } catch (error: any) {
    console.error('Follow error:', error);
    res.status(error.message === 'Cannot follow yourself' ? 400 : 500).json({
      success: false,
      error: {
        code: error.message === 'Cannot follow yourself' ? 'INVALID_OPERATION' : 'INTERNAL_ERROR',
        message: error.message || 'Failed to follow user',
      },
    });
  }
});

router.delete('/follow/:userId', authenticate, async (req: Request, res: Response) => {
  try {
    const followerId = req.user!.userId;
    const followingId = parseInt(req.params.userId);

    await socialService.unfollow(followerId, followingId);

    res.json({
      success: true,
      data: {
        message: 'User unfollowed successfully',
      },
    });
  } catch (error) {
    console.error('Unfollow error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to unfollow user',
      },
    });
  }
});

router.get('/following/:userId', authenticate, async (req: Request, res: Response) => {
  try {
    const followerId = req.user!.userId;
    const followingId = parseInt(req.params.userId);

    const isFollowing = await socialService.isFollowing(followerId, followingId);

    res.json({
      success: true,
      data: {
        isFollowing,
      },
    });
  } catch (error) {
    console.error('Check following error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to check following status',
      },
    });
  }
});

// Bookmark operations
router.get('/bookmarks', authenticate, async (req: Request, res: Response) => {
  try {
    const userId = req.user!.userId;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;

    const result = await socialService.getBookmarks(userId, page, limit);

    res.json({
      success: true,
      data: result.data,
      meta: result.meta,
    });
  } catch (error) {
    console.error('Get bookmarks error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to get bookmarks',
      },
    });
  }
});

export default router;
