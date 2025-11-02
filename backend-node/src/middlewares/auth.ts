import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { JWTPayload, AuthPayload } from '../types';

// Extend Express Request type
declare global {
  namespace Express {
    interface Request {
      user?: AuthPayload;
    }
  }
}

/**
 * Authentication middleware
 */
export const authenticate = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      res.status(401).json({
        success: false,
        error: {
          code: 'UNAUTHORIZED',
          message: 'No authorization header provided',
        },
      });
      return;
    }

    const parts = authHeader.split(' ');

    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      res.status(401).json({
        success: false,
        error: {
          code: 'INVALID_TOKEN_FORMAT',
          message: 'Invalid authorization header format. Expected: Bearer <token>',
        },
      });
      return;
    }

    const token = parts[1];
    const secret = process.env.JWT_SECRET || 'your-super-secret-jwt-key';

    const decoded = jwt.verify(token, secret) as JWTPayload;

    req.user = {
      userId: decoded.userId,
      walletAddress: decoded.walletAddress,
    };

    next();
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      res.status(401).json({
        success: false,
        error: {
          code: 'TOKEN_EXPIRED',
          message: 'Token has expired',
        },
      });
      return;
    }

    if (error instanceof jwt.JsonWebTokenError) {
      res.status(401).json({
        success: false,
        error: {
          code: 'INVALID_TOKEN',
          message: 'Invalid token',
        },
      });
      return;
    }

    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Internal server error',
      },
    });
  }
};

/**
 * Optional authentication middleware (doesn't fail if no token)
 */
export const optionalAuth = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      next();
      return;
    }

    const parts = authHeader.split(' ');

    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      next();
      return;
    }

    const token = parts[1];
    const secret = process.env.JWT_SECRET || 'your-super-secret-jwt-key';

    const decoded = jwt.verify(token, secret) as JWTPayload;

    req.user = {
      userId: decoded.userId,
      walletAddress: decoded.walletAddress,
    };

    next();
  } catch (error) {
    // Ignore errors and continue without authentication
    next();
  }
};

/**
 * Generate JWT token
 */
export const generateToken = (payload: AuthPayload): string => {
  const secret = process.env.JWT_SECRET || 'your-super-secret-jwt-key';
  const expiresIn = process.env.JWT_EXPIRES_IN || '24h';

  return jwt.sign(payload, secret, { expiresIn });
};

/**
 * Generate refresh token
 */
export const generateRefreshToken = (payload: AuthPayload): string => {
  const secret =
    process.env.JWT_REFRESH_SECRET || 'your-super-secret-refresh-key';
  const expiresIn = process.env.JWT_REFRESH_EXPIRES_IN || '7d';

  return jwt.sign(payload, secret, { expiresIn });
};

/**
 * Verify refresh token
 */
export const verifyRefreshToken = (token: string): JWTPayload => {
  const secret =
    process.env.JWT_REFRESH_SECRET || 'your-super-secret-refresh-key';
  return jwt.verify(token, secret) as JWTPayload;
};
