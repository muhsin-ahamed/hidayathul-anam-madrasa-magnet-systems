import { Request, Response, NextFunction } from 'express';
import { loginUser, getMe } from './auth.service';
import { logActivity } from '../utils/logger';

export const login = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { username, password } = req.body;
    const result = await loginUser(username, password);
    
    return res.status(200).json({
      success: true,
      ...result
    });
  } catch (error: any) {
    if (
      error.message === 'Invalid credentials' ||
      error.message === 'User not found' ||
      error.message === 'Invalid password' ||
      error.message === 'Credentials not setup'
    ) {
      return res.status(401).json({ success: false, message: error.message });
    }
    if (error.message === 'Account is disabled') {
      return res.status(403).json({ success: false, message: error.message });
    }
    if (error.message === 'Super Admin profile not found in database.') {
      return res.status(404).json({ success: false, message: error.message });
    }
    return res.status(400).json({ success: false, message: error.message || 'Login failed' });
  }
};

export const logout = async (req: Request, res: Response, next: NextFunction) => {
  try {
    if (req.user) {
      await logActivity(req.user.id, 'Logout');
    }
    return res.status(200).json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    next(error);
  }
};

export const me = async (req: Request, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }
    const userProfile = await getMe(req.user.id);
    return res.status(200).json({ success: true, data: userProfile });
  } catch (error: any) {
    if (error.message === 'User not found') {
      return res.status(404).json({ success: false, message: error.message });
    }
    next(error);
  }
};
