import { Request, Response, NextFunction } from 'express';
import * as classService from './class.service';
import { logActivity } from '../utils/logger';

export const createClass = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classData = await classService.createClass(req.body);
    await logActivity(req.user?.id, 'Create', 'Class', classData.id, `Created class ${classData.class_name}`);
    return res.status(201).json({ success: true, data: classData });
  } catch (error: any) {
    if (error.message === 'Teacher is already assigned to another class') {
      return res.status(409).json({ success: false, message: error.message });
    }
    next(error);
  }
};

export const getClasses = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classes = await classService.getAllClasses();
    return res.status(200).json({ success: true, data: classes });
  } catch (error) {
    next(error);
  }
};

export const getClass = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classData = await classService.getClassById(req.params.id);
    return res.status(200).json({ success: true, data: classData });
  } catch (error: any) {
    if (error.message === 'Class not found') return res.status(404).json({ success: false, message: error.message });
    next(error);
  }
};

export const updateClass = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classData = await classService.updateClass(req.params.id, req.body);
    await logActivity(req.user?.id, 'Update', 'Class', classData.id, `Updated class ${classData.class_name}`);
    return res.status(200).json({ success: true, data: classData });
  } catch (error: any) {
    if (error.message === 'Class not found') return res.status(404).json({ success: false, message: error.message });
    if (error.message === 'Teacher is already assigned to another class') return res.status(409).json({ success: false, message: error.message });
    next(error);
  }
};

export const deleteClass = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await classService.deleteClass(req.params.id);
    await logActivity(req.user?.id, 'Delete', 'Class', req.params.id, 'Deleted class');
    return res.status(200).json({ success: true, message: 'Class deleted successfully' });
  } catch (error: any) {
    if (error.message === 'Class not found') return res.status(404).json({ success: false, message: error.message });
    next(error);
  }
};
