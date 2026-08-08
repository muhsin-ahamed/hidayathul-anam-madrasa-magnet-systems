import { Request, Response, NextFunction } from 'express';
import * as studentService from './student.service';
import { logActivity } from '../utils/logger';

export const createStudent = async (req: Request, res: Response, next: NextFunction) => {
  console.log('[POST /api/students] Incoming request body:', JSON.stringify(req.body, null, 2));
  try {
    const student = await studentService.createStudent(req.body, req.user);
    await logActivity(req.user?.id, 'Create', 'Student', student.id, `Created student ${student.admission_number}`, student.class_id ?? undefined);
    return res.status(201).json({ success: true, data: student });
  } catch (error: any) {
    console.error('[POST /api/students ERROR]:', error);

    if (error.message?.includes('already exists')) {
      return res.status(409).json({ success: false, message: error.message });
    }
    if (error.message === 'Teachers can only create students in their assigned class.' || error.message === 'Not authorized to add student to this class') {
      return res.status(403).json({ success: false, message: error.message });
    }
    if (error.message?.includes('not found')) {
      return res.status(404).json({ success: false, message: error.message });
    }

    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to create student',
      error: process.env.NODE_ENV === 'production' ? undefined : (error.stack || error.toString()),
    });
  }
};

export const getStudents = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const students = await studentService.getAllStudents(req.user);
    return res.status(200).json({ success: true, data: students });
  } catch (error) {
    next(error);
  }
};

export const getStudent = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const student = await studentService.getStudentById(req.params.id, req.user);
    return res.status(200).json({ success: true, data: student });
  } catch (error: any) {
    if (error.message === 'Student not found') return res.status(404).json({ success: false, message: error.message });
    if (error.message === 'Not authorized to access this student') return res.status(403).json({ success: false, message: error.message });
    next(error);
  }
};

export const getStudentProfileHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const profileIdOrId = req.params.profileId || req.user?.id || req.user?.userId;
    if (!profileIdOrId) {
      return res.status(400).json({ success: false, message: 'User profile ID required' });
    }
    const profile = await studentService.getStudentProfile(profileIdOrId, req.user);
    return res.status(200).json({
      success: true,
      data: profile,
      ...profile,
    });
  } catch (error: any) {
    if (error.message === 'Student profile not found') {
      return res.status(404).json({ success: false, message: error.message });
    }
    if (error.message === 'Not authorized to access this profile') {
      return res.status(403).json({ success: false, message: error.message });
    }
    return res.status(400).json({ success: false, message: error.message || 'Failed to fetch student profile' });
  }
};

export const getStudentDashboardHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const dashboardData = await studentService.getStudentDashboard(req.user);
    return res.status(200).json({
      success: true,
      data: dashboardData,
      student: dashboardData.student,
      summary: dashboardData.summary,
    });
  } catch (error: any) {
    if (error.message === 'Student not found') {
      return res.status(404).json({ success: false, message: error.message });
    }
    return res.status(400).json({ success: false, message: error.message || 'Failed to load dashboard' });
  }
};

export const getStudentNotesHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.query.classId as string | undefined;
    const notes = await studentService.getStudentNotes(req.user, classId);
    return res.status(200).json({
      success: true,
      data: notes,
      notes: notes,
    });
  } catch (error: any) {
    return res.status(200).json({ success: true, data: [], notes: [] });
  }
};

export const getStudentResultsHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const studentId = req.query.studentId as string | undefined;
    const results = await studentService.getStudentResults(req.user, studentId);
    return res.status(200).json({
      success: true,
      data: results,
      results: results,
    });
  } catch (error: any) {
    return res.status(200).json({ success: true, data: [], results: [] });
  }
};

export const getStudentHallTicketHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const studentId = req.query.studentId as string | undefined;
    const examId = req.query.examId as string | undefined;
    const tickets = await studentService.getStudentHallTicket(req.user, studentId, examId);
    return res.status(200).json({
      success: true,
      data: tickets,
      hallTickets: tickets,
      hallTicket: tickets.length > 0 ? tickets[0] : null,
    });
  } catch (error: any) {
    return res.status(200).json({ success: true, data: [], hallTickets: [], hallTicket: null });
  }
};

export const updateStudent = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const student = await studentService.updateStudent(req.params.id, req.body, req.user);
    await logActivity(req.user?.id, 'Update', 'Student', student.id, `Updated student ${student.admission_number}`, student.class_id ?? undefined);
    return res.status(200).json({ success: true, data: student });
  } catch (error: any) {
    if (error.message?.includes('already exists')) {
      return res.status(409).json({ success: false, message: error.message });
    }
    if (error.message === 'Student not found') return res.status(404).json({ success: false, message: error.message });
    if (error.message === 'Not authorized to update this student' || error.message === 'Teachers cannot change a student\'s class') {
      return res.status(403).json({ success: false, message: error.message });
    }
    next(error);
  }
};

export const deleteStudent = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await studentService.deleteStudent(req.params.id, req.user);
    await logActivity(req.user?.id, 'Delete', 'Student', req.params.id, 'Deleted student');
    return res.status(200).json({ success: true, message: 'Student deleted successfully' });
  } catch (error: any) {
    if (error.message === 'Student not found') return res.status(404).json({ success: false, message: error.message });
    if (error.message === 'Not authorized to delete this student') return res.status(403).json({ success: false, message: error.message });
    next(error);
  }
};
