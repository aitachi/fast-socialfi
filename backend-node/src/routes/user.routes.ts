/**
 * Author: Aitachi
 * Email: 44158892@qq.com
 * Date: 11-02-2025 17
 */

import { Router } from 'express';
import userController from '../controllers/UserController';
import { authenticate } from '../middlewares/auth';
import { validate, registerSchema, loginSchema, updateUserSchema } from '../middlewares/validation';
import { authLimiter } from '../middlewares/rateLimit';

const router = Router();

/**
 * User Routes
 */

// Authentication
router.post('/register', authLimiter, validate(registerSchema), userController.register);
router.post('/login', authLimiter, validate(loginSchema), userController.login);

// Profile
router.get('/me', authenticate, userController.getMe);
router.get('/:id', userController.getProfile);
router.put('/:id', authenticate, validate(updateUserSchema), userController.updateProfile);

// Social
router.get('/:id/followers', userController.getFollowers);
router.get('/:id/following', userController.getFollowing);

export default router;
