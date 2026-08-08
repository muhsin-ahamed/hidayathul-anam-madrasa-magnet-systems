import jwt from 'jsonwebtoken';
import { env } from '../config/env';

export interface JwtPayload {
  id: string;
  userId?: string;
  username?: string;
  role: string;
}

export const signToken = (payload: JwtPayload): string => {
  const tokenPayload = {
    id: payload.id,
    userId: payload.userId || payload.id,
    username: payload.username || '',
    role: payload.role,
  };
  return jwt.sign(tokenPayload, env.JWT_SECRET, { expiresIn: '1d' });
};

export const verifyToken = (token: string): JwtPayload | null => {
  try {
    return jwt.verify(token, env.JWT_SECRET) as JwtPayload;
  } catch (error) {
    return null;
  }
};
