import { Router } from 'express';
import searchUtil from '../utils/search';
import { optionalAuth } from '../middlewares/auth';
import { searchLimiter } from '../middlewares/rateLimit';
import { Request, Response } from 'express';

const router = Router();

/**
 * Search Routes
 */

// Search users
router.get('/users', optionalAuth, searchLimiter, async (req: Request, res: Response) => {
  try {
    const keyword = req.query.keyword as string;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;

    if (!keyword) {
      res.status(400).json({
        success: false,
        error: {
          code: 'MISSING_KEYWORD',
          message: 'Search keyword is required',
        },
      });
      return;
    }

    const result = await searchUtil.searchUsers({ keyword, page, limit });

    res.json({
      success: true,
      data: result.data,
      meta: result.meta,
    });
  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to search users',
      },
    });
  }
});

// Search posts
router.get('/posts', optionalAuth, searchLimiter, async (req: Request, res: Response) => {
  try {
    const keyword = req.query.keyword as string;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;

    if (!keyword) {
      res.status(400).json({
        success: false,
        error: {
          code: 'MISSING_KEYWORD',
          message: 'Search keyword is required',
        },
      });
      return;
    }

    const result = await searchUtil.searchPosts({ keyword, page, limit });

    res.json({
      success: true,
      data: result.data,
      meta: result.meta,
    });
  } catch (error) {
    console.error('Search posts error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to search posts',
      },
    });
  }
});

// Search hashtags
router.get('/hashtags', optionalAuth, searchLimiter, async (req: Request, res: Response) => {
  try {
    const keyword = req.query.keyword as string;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;

    if (!keyword) {
      res.status(400).json({
        success: false,
        error: {
          code: 'MISSING_KEYWORD',
          message: 'Search keyword is required',
        },
      });
      return;
    }

    const result = await searchUtil.searchHashtags({ keyword, page, limit });

    res.json({
      success: true,
      data: result.data,
      meta: result.meta,
    });
  } catch (error) {
    console.error('Search hashtags error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to search hashtags',
      },
    });
  }
});

// User autocomplete suggestions
router.get('/suggest/users', optionalAuth, searchLimiter, async (req: Request, res: Response) => {
  try {
    const prefix = req.query.prefix as string;
    const size = parseInt(req.query.size as string) || 10;

    if (!prefix) {
      res.status(400).json({
        success: false,
        error: {
          code: 'MISSING_PREFIX',
          message: 'Search prefix is required',
        },
      });
      return;
    }

    const suggestions = await searchUtil.suggestUsers(prefix, size);

    res.json({
      success: true,
      data: suggestions,
    });
  } catch (error) {
    console.error('Suggest users error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to get suggestions',
      },
    });
  }
});

export default router;
