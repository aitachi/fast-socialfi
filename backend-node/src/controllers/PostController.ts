import { Request, Response } from 'express';
import postService from '../services/PostService';
import socialService from '../services/SocialService';
import { CreatePostDTO, UpdatePostDTO } from '../types';

/**
 * Post Controller - Handles HTTP requests for post operations
 */
class PostController {
  /**
   * Create a new post
   */
  async createPost(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const postData: CreatePostDTO = {
        ...req.body,
        author_id: userId,
      };

      const post = await postService.createPost(postData);

      res.status(201).json({
        success: true,
        data: post,
      });
    } catch (error) {
      console.error('Create post error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to create post',
        },
      });
    }
  }

  /**
   * Get post by ID
   */
  async getPost(req: Request, res: Response): Promise<void> {
    try {
      const postId = parseInt(req.params.id);

      const post = await postService.getPostById(postId);
      if (!post) {
        res.status(404).json({
          success: false,
          error: {
            code: 'POST_NOT_FOUND',
            message: 'Post not found',
          },
        });
        return;
      }

      // Increment view count
      await postService.incrementViewCount(postId);

      res.json({
        success: true,
        data: post,
      });
    } catch (error) {
      console.error('Get post error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to get post',
        },
      });
    }
  }

  /**
   * Update post
   */
  async updatePost(req: Request, res: Response): Promise<void> {
    try {
      const postId = parseInt(req.params.id);
      const userId = req.user!.userId;
      const updateData: UpdatePostDTO = req.body;

      // Verify ownership
      const post = await postService.getPostById(postId);
      if (!post) {
        res.status(404).json({
          success: false,
          error: {
            code: 'POST_NOT_FOUND',
            message: 'Post not found',
          },
        });
        return;
      }

      if (post.author_id !== userId) {
        res.status(403).json({
          success: false,
          error: {
            code: 'FORBIDDEN',
            message: 'You can only update your own posts',
          },
        });
        return;
      }

      const updatedPost = await postService.updatePost(postId, updateData);

      res.json({
        success: true,
        data: updatedPost,
      });
    } catch (error) {
      console.error('Update post error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to update post',
        },
      });
    }
  }

  /**
   * Delete post
   */
  async deletePost(req: Request, res: Response): Promise<void> {
    try {
      const postId = parseInt(req.params.id);
      const userId = req.user!.userId;

      await postService.deletePost(postId, userId);

      res.json({
        success: true,
        data: {
          message: 'Post deleted successfully',
        },
      });
    } catch (error) {
      console.error('Delete post error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to delete post',
        },
      });
    }
  }

  /**
   * Get user's posts
   */
  async getUserPosts(req: Request, res: Response): Promise<void> {
    try {
      const userId = parseInt(req.params.userId);
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;

      const result = await postService.getUserPosts(userId, page, limit);

      res.json({
        success: true,
        data: result.data,
        meta: result.meta,
      });
    } catch (error) {
      console.error('Get user posts error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to get user posts',
        },
      });
    }
  }

  /**
   * Get feed (posts from followed users)
   */
  async getFeed(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;

      const result = await postService.getFeed(userId, page, limit);

      res.json({
        success: true,
        data: result.data,
        meta: result.meta,
      });
    } catch (error) {
      console.error('Get feed error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to get feed',
        },
      });
    }
  }

  /**
   * Get trending posts
   */
  async getTrending(req: Request, res: Response): Promise<void> {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;

      const result = await postService.getTrendingPosts(page, limit);

      res.json({
        success: true,
        data: result.data,
        meta: result.meta,
      });
    } catch (error) {
      console.error('Get trending error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to get trending posts',
        },
      });
    }
  }

  /**
   * Get posts by hashtag
   */
  async getByHashtag(req: Request, res: Response): Promise<void> {
    try {
      const hashtag = req.params.hashtag;
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;

      const result = await postService.getPostsByHashtag(hashtag, page, limit);

      res.json({
        success: true,
        data: result.data,
        meta: result.meta,
      });
    } catch (error) {
      console.error('Get posts by hashtag error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to get posts by hashtag',
        },
      });
    }
  }

  /**
   * Like a post
   */
  async likePost(req: Request, res: Response): Promise<void> {
    try {
      const postId = parseInt(req.params.id);
      const userId = req.user!.userId;

      await socialService.like(userId, 'post', postId);

      res.json({
        success: true,
        data: {
          message: 'Post liked successfully',
        },
      });
    } catch (error) {
      console.error('Like post error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to like post',
        },
      });
    }
  }

  /**
   * Unlike a post
   */
  async unlikePost(req: Request, res: Response): Promise<void> {
    try {
      const postId = parseInt(req.params.id);
      const userId = req.user!.userId;

      await socialService.unlike(userId, 'post', postId);

      res.json({
        success: true,
        data: {
          message: 'Post unliked successfully',
        },
      });
    } catch (error) {
      console.error('Unlike post error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to unlike post',
        },
      });
    }
  }

  /**
   * Get comments for a post
   */
  async getComments(req: Request, res: Response): Promise<void> {
    try {
      const postId = parseInt(req.params.id);
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;

      const result = await socialService.getComments(postId, page, limit);

      res.json({
        success: true,
        data: result.data,
        meta: result.meta,
      });
    } catch (error) {
      console.error('Get comments error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to get comments',
        },
      });
    }
  }

  /**
   * Create a comment on a post
   */
  async createComment(req: Request, res: Response): Promise<void> {
    try {
      const postId = parseInt(req.params.id);
      const userId = req.user!.userId;

      const comment = await socialService.createComment({
        post_id: postId,
        author_id: userId,
        content: req.body.content,
        parent_id: req.body.parent_id,
        media_urls: req.body.media_urls,
        mentions: req.body.mentions,
      });

      res.status(201).json({
        success: true,
        data: comment,
      });
    } catch (error) {
      console.error('Create comment error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to create comment',
        },
      });
    }
  }

  /**
   * Bookmark a post
   */
  async bookmarkPost(req: Request, res: Response): Promise<void> {
    try {
      const postId = parseInt(req.params.id);
      const userId = req.user!.userId;

      await socialService.bookmarkPost(userId, postId);

      res.json({
        success: true,
        data: {
          message: 'Post bookmarked successfully',
        },
      });
    } catch (error) {
      console.error('Bookmark post error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to bookmark post',
        },
      });
    }
  }

  /**
   * Remove bookmark
   */
  async removeBookmark(req: Request, res: Response): Promise<void> {
    try {
      const postId = parseInt(req.params.id);
      const userId = req.user!.userId;

      await socialService.removeBookmark(userId, postId);

      res.json({
        success: true,
        data: {
          message: 'Bookmark removed successfully',
        },
      });
    } catch (error) {
      console.error('Remove bookmark error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to remove bookmark',
        },
      });
    }
  }
}

export default new PostController();
