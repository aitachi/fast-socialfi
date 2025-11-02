import { Request, Response } from 'express';
import userService from '../services/UserService';
import blockchainClient from '../config/blockchain';
import { generateToken, generateRefreshToken } from '../middlewares/auth';
import { CreateUserDTO, UpdateUserDTO } from '../types';

/**
 * User Controller - Handles HTTP requests for user operations
 */
class UserController {
  /**
   * Register a new user with wallet signature
   */
  async register(req: Request, res: Response): Promise<void> {
    try {
      const { wallet_address, signature, message, ...userData } = req.body;

      // Verify wallet signature
      const isValid = await blockchainClient.verifySignature(
        message,
        signature,
        wallet_address
      );

      if (!isValid) {
        res.status(401).json({
          success: false,
          error: {
            code: 'INVALID_SIGNATURE',
            message: 'Invalid wallet signature',
          },
        });
        return;
      }

      // Check if user already exists
      const existingUser = await userService.getUserByWallet(wallet_address);
      if (existingUser) {
        res.status(409).json({
          success: false,
          error: {
            code: 'USER_EXISTS',
            message: 'User with this wallet address already exists',
          },
        });
        return;
      }

      // Check username availability
      if (userData.username) {
        const isAvailable = await userService.isUsernameAvailable(
          userData.username
        );
        if (!isAvailable) {
          res.status(409).json({
            success: false,
            error: {
              code: 'USERNAME_TAKEN',
              message: 'Username is already taken',
            },
          });
          return;
        }
      }

      // Create user
      const createData: CreateUserDTO = {
        wallet_address,
        ...userData,
      };
      const user = await userService.createUser(createData);

      // Generate tokens
      const token = generateToken({
        userId: user.id,
        walletAddress: user.wallet_address,
      });
      const refreshToken = generateRefreshToken({
        userId: user.id,
        walletAddress: user.wallet_address,
      });

      res.status(201).json({
        success: true,
        data: {
          user,
          token,
          refreshToken,
        },
      });
    } catch (error) {
      console.error('Register error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to register user',
        },
      });
    }
  }

  /**
   * Login with wallet signature
   */
  async login(req: Request, res: Response): Promise<void> {
    try {
      const { wallet_address, signature, message } = req.body;

      // Verify wallet signature
      const isValid = await blockchainClient.verifySignature(
        message,
        signature,
        wallet_address
      );

      if (!isValid) {
        res.status(401).json({
          success: false,
          error: {
            code: 'INVALID_SIGNATURE',
            message: 'Invalid wallet signature',
          },
        });
        return;
      }

      // Get user
      const user = await userService.getUserByWallet(wallet_address);
      if (!user) {
        res.status(404).json({
          success: false,
          error: {
            code: 'USER_NOT_FOUND',
            message: 'User not found',
          },
        });
        return;
      }

      // Check if user is banned
      if (user.is_banned) {
        res.status(403).json({
          success: false,
          error: {
            code: 'USER_BANNED',
            message: 'User account is banned',
          },
        });
        return;
      }

      // Update last login
      await userService.updateLastLogin(user.id);

      // Generate tokens
      const token = generateToken({
        userId: user.id,
        walletAddress: user.wallet_address,
      });
      const refreshToken = generateRefreshToken({
        userId: user.id,
        walletAddress: user.wallet_address,
      });

      res.json({
        success: true,
        data: {
          user,
          token,
          refreshToken,
        },
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to login',
        },
      });
    }
  }

  /**
   * Get user profile
   */
  async getProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = parseInt(req.params.id);

      const user = await userService.getUserById(userId);
      if (!user) {
        res.status(404).json({
          success: false,
          error: {
            code: 'USER_NOT_FOUND',
            message: 'User not found',
          },
        });
        return;
      }

      // Get user stats
      const stats = await userService.getUserStats(userId);

      res.json({
        success: true,
        data: {
          ...user,
          stats,
        },
      });
    } catch (error) {
      console.error('Get profile error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to get user profile',
        },
      });
    }
  }

  /**
   * Update user profile
   */
  async updateProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const updateData: UpdateUserDTO = req.body;

      // Check username availability if changing
      if (updateData.username) {
        const currentUser = await userService.getUserById(userId);
        if (
          currentUser &&
          currentUser.username !== updateData.username
        ) {
          const isAvailable = await userService.isUsernameAvailable(
            updateData.username
          );
          if (!isAvailable) {
            res.status(409).json({
              success: false,
              error: {
                code: 'USERNAME_TAKEN',
                message: 'Username is already taken',
              },
            });
            return;
          }
        }
      }

      const user = await userService.updateUser(userId, updateData);

      res.json({
        success: true,
        data: user,
      });
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to update profile',
        },
      });
    }
  }

  /**
   * Get user's followers
   */
  async getFollowers(req: Request, res: Response): Promise<void> {
    try {
      const userId = parseInt(req.params.id);
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;

      const result = await userService.getFollowers(userId, page, limit);

      res.json({
        success: true,
        data: result.data,
        meta: result.meta,
      });
    } catch (error) {
      console.error('Get followers error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to get followers',
        },
      });
    }
  }

  /**
   * Get user's following
   */
  async getFollowing(req: Request, res: Response): Promise<void> {
    try {
      const userId = parseInt(req.params.id);
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;

      const result = await userService.getFollowing(userId, page, limit);

      res.json({
        success: true,
        data: result.data,
        meta: result.meta,
      });
    } catch (error) {
      console.error('Get following error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to get following',
        },
      });
    }
  }

  /**
   * Get current user's profile
   */
  async getMe(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;

      const user = await userService.getUserById(userId);
      if (!user) {
        res.status(404).json({
          success: false,
          error: {
            code: 'USER_NOT_FOUND',
            message: 'User not found',
          },
        });
        return;
      }

      const stats = await userService.getUserStats(userId);

      res.json({
        success: true,
        data: {
          ...user,
          stats,
        },
      });
    } catch (error) {
      console.error('Get me error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to get user data',
        },
      });
    }
  }
}

export default new UserController();
