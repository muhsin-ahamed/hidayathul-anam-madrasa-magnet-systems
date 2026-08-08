import { Request, Response, NextFunction } from 'express';
import * as dashboardService from './dashboard.service';

export const getDashboard = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const stats = await dashboardService.getDashboardStats(req.user);
    return res.status(200).json({ success: true, data: stats });
  } catch (error) {
    next(error);
  }
};
