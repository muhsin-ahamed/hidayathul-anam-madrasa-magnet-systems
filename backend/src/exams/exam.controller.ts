import { Request, Response, NextFunction } from 'express';
import * as examService from './exam.service';
import { logActivity } from '../utils/logger';

export const getExams = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.query.classId as string | undefined;
    const exams = await examService.getAllExams(req.user, classId);
    return res.status(200).json({ success: true, data: exams });
  } catch (error) {
    console.error('[GET EXAMS ERROR]:', error);
    return res.status(200).json({ success: true, data: [] });
  }
};

export const getExam = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const exam = await examService.getExamById(req.params.id);
    return res.status(200).json({ success: true, data: exam });
  } catch (error) {
    return res.status(200).json({ success: true, data: null });
  }
};

export const createExam = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const exam = await examService.createExam(req.body, req.user);
    await logActivity(req.user?.id, 'Create', 'Exam', exam.id, `Created exam ${exam.exam_name}`);
    return res.status(201).json({ success: true, data: exam });
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message || 'Failed to create exam' });
  }
};

export const updateExam = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const exam = await examService.updateExam(req.params.id, req.body, req.user);
    await logActivity(req.user?.id, 'Update', 'Exam', exam.id, `Updated exam ${exam.exam_name}`);
    return res.status(200).json({ success: true, data: exam });
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message || 'Failed to update exam' });
  }
};

export const deleteExam = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await examService.deleteExam(req.params.id);
    await logActivity(req.user?.id, 'Delete', 'Exam', req.params.id, 'Deleted exam');
    return res.status(200).json({ success: true, message: 'Exam deleted successfully' });
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message || 'Failed to delete exam' });
  }
};

export const setResultsPublishedHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const published = req.body.published ?? req.body.is_published ?? true;
    const exam = await examService.setResultsPublished(req.params.id, published);
    await logActivity(req.user?.id, 'Publish Results', 'Exam', req.params.id, `Results publish state set to ${published}`);
    return res.status(200).json({ success: true, data: exam });
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message || 'Failed to update results published status' });
  }
};

export const setHallTicketsLockedHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const locked = req.body.locked ?? req.body.hall_ticket_locked ?? true;
    const exam = await examService.setHallTicketsLocked(req.params.id, locked);
    await logActivity(req.user?.id, 'Lock Hall Tickets', 'Exam', req.params.id, `Hall tickets lock state set to ${locked}`);
    return res.status(200).json({ success: true, data: exam });
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message || 'Failed to update hall tickets locked status' });
  }
};

export const getExamSubjectsHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const subjects = await examService.getExamSubjects(req.params.id);
    return res.status(200).json({ success: true, data: subjects });
  } catch (error) {
    return res.status(200).json({ success: true, data: [] });
  }
};

export const saveExamSubjectsHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const rawSubjects = req.body.subjects || req.body;
    const subjects = await examService.saveExamSubjects(req.params.id, rawSubjects);
    await logActivity(req.user?.id, 'Save Exam Subjects', 'Exam', req.params.id, `Updated exam subjects`);
    return res.status(200).json({ success: true, data: subjects });
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message || 'Failed to save exam subjects' });
  }
};
