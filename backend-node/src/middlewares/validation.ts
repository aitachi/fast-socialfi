import { Request, Response, NextFunction } from 'express';
import Joi from 'joi';

/**
 * Validation middleware factory
 */
export const validate = (schema: Joi.ObjectSchema) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    const { error } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));

      res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          details: errors,
        },
      });
      return;
    }

    next();
  };
};

/**
 * Validation schemas
 */

// User registration schema
export const registerSchema = Joi.object({
  wallet_address: Joi.string()
    .pattern(/^0x[a-fA-F0-9]{40}$/)
    .required()
    .messages({
      'string.pattern.base': 'Invalid Ethereum wallet address',
    }),
  signature: Joi.string().required(),
  message: Joi.string().required(),
  username: Joi.string().alphanum().min(3).max(30).optional(),
  display_name: Joi.string().max(100).optional(),
  bio: Joi.string().max(500).optional(),
  avatar_url: Joi.string().uri().optional(),
});

// User update schema
export const updateUserSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(30).optional(),
  display_name: Joi.string().max(100).optional(),
  bio: Joi.string().max(500).optional(),
  avatar_url: Joi.string().uri().optional(),
  cover_url: Joi.string().uri().optional(),
  email: Joi.string().email().optional(),
});

// Post creation schema
export const createPostSchema = Joi.object({
  content: Joi.string().min(1).max(5000).required(),
  media_urls: Joi.array().items(Joi.string().uri()).max(10).optional(),
  media_type: Joi.string()
    .valid('text', 'image', 'video', 'mixed')
    .optional(),
  hashtags: Joi.array().items(Joi.string().max(50)).max(20).optional(),
  mentions: Joi.array().items(Joi.number().integer()).max(50).optional(),
  visibility: Joi.string().valid('public', 'followers', 'private').optional(),
  is_sensitive: Joi.boolean().optional(),
});

// Post update schema
export const updatePostSchema = Joi.object({
  content: Joi.string().min(1).max(5000).optional(),
  media_urls: Joi.array().items(Joi.string().uri()).max(10).optional(),
  hashtags: Joi.array().items(Joi.string().max(50)).max(20).optional(),
  is_pinned: Joi.boolean().optional(),
  is_sensitive: Joi.boolean().optional(),
});

// Comment creation schema
export const createCommentSchema = Joi.object({
  content: Joi.string().min(1).max(2000).required(),
  parent_id: Joi.number().integer().optional(),
  media_urls: Joi.array().items(Joi.string().uri()).max(4).optional(),
  mentions: Joi.array().items(Joi.number().integer()).max(20).optional(),
});

// Pagination schema
export const paginationSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

// Search schema
export const searchSchema = Joi.object({
  keyword: Joi.string().min(1).max(100).required(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

// Wallet login schema
export const loginSchema = Joi.object({
  wallet_address: Joi.string()
    .pattern(/^0x[a-fA-F0-9]{40}$/)
    .required()
    .messages({
      'string.pattern.base': 'Invalid Ethereum wallet address',
    }),
  signature: Joi.string().required(),
  message: Joi.string().required(),
});
