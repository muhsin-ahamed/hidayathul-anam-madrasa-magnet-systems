import { Request, Response, NextFunction } from 'express';
import * as subjectService from './subject.service';
import { logActivity } from '../utils/logger';

export const getSubjects = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.query.classId as string | undefined;
    const subjects = await subjectService.getAllSubjects(req.user, classId);
    return res.status(200).json({ success: true, data: subjects });
  } catch (error) {
    console.error('[GET SUBJECTS ERROR]:', error);
    return res.status(200).json({ success: true, data: [] });
  }
};

export const getSubject = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const subject = await subjectService.getSubjectById(req.params.id);
    return res.status(200).json({ success: true, data: subject });
  } catch (error) {
    return res.status(200).json({ success: true, data: null });
  }
};

export const createSubject = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const subject = await subjectService.createSubject(req.body, req.user);
    await logActivity(req.user?.id, 'Create', 'Subject', subject.id, `Created subject ${subject.subject_name}`);
    return res.status(201).json({ success: true, data: subject });
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message || 'Failed to create subject' });
  }
};

export const updateSubject = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const subject = await subjectService.updateSubject(req.params.id, req.body, req.user);
    await logActivity(req.user?.id, 'Update', 'Subject', subject.id, `Updated subject ${subject.subject_name}`);
    return res.status(200).json({ success: true, data: subject });
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message || 'Failed to update subject' });
  }
};

export const deactivateSubject = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await subjectService.deactivateSubject(req.params.id);
    await logActivity(req.user?.id, 'Deactivate', 'Subject', req.params.id, 'Deactivated subject');
    return res.status(200).json({ success: true, message: 'Subject deactivated successfully' });
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message || 'Failed to deactivate subject' });
  }
};
