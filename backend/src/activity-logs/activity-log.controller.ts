import { Request, Response, NextFunction } from 'express';
import { getActivityLogsService } from './activity-log.service';
import { logActivity } from '../utils/logger';

export const getActivityLogs = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.query.classId as string | undefined;
    const logs = await getActivityLogsService(req.user, classId);
    return res.status(200).json({ success: true, data: logs || [] });
  } catch (error: any) {
    return res.status(200).json({ success: true, data: [] });
  }
};

export const createActivityLog = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { action, entityType, entityId, description, classId } = req.body || {};
    await logActivity(
      req.user?.id,
      action || 'Activity',
      entityType,
      entityId,
      description,
      classId
    );
    return res.status(201).json({ success: true, message: 'Activity logged' });
  } catch (error) {
    return res.status(200).json({ success: true, message: 'Activity log skipped' });
  }
};
