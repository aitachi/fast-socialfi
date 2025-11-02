/**
 * Author: Aitachi
 * Email: 44158892@qq.com
 * Date: 11-02-2025 17
 */

import { Router } from 'express';
import postController from '../controllers/PostController';
import { authenticate, optionalAuth } from '../middlewares/auth';
import { validate, createPostSchema, updatePostSchema, createCommentSchema } from '../middlewares/validation';
import { postCreationLimiter, commentLimiter } from '../middlewares/rateLimit';

const router = Router();

/**
 * Post Routes
 */

// Post CRUD
router.post('/', authenticate, postCreationLimiter, validate(createPostSchema), postController.createPost);
router.get('/feed', authenticate, postController.getFeed);
router.get('/trending', optionalAuth, postController.getTrending);
router.get('/hashtag/:hashtag', optionalAuth, postController.getByHashtag);
router.get('/user/:userId', optionalAuth, postController.getUserPosts);
router.get('/:id', optionalAuth, postController.getPost);
router.put('/:id', authenticate, validate(updatePostSchema), postController.updatePost);
router.delete('/:id', authenticate, postController.deletePost);

// Interactions
router.post('/:id/like', authenticate, postController.likePost);
router.delete('/:id/like', authenticate, postController.unlikePost);
router.post('/:id/bookmark', authenticate, postController.bookmarkPost);
router.delete('/:id/bookmark', authenticate, postController.removeBookmark);

// Comments
router.get('/:id/comments', optionalAuth, postController.getComments);
router.post('/:id/comments', authenticate, commentLimiter, validate(createCommentSchema), postController.createComment);

export default router;
