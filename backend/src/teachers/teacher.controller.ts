import { Request, Response, NextFunction } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import * as teacherService from './teacher.service';
import { logActivity } from '../utils/logger';

const avatarUploadsDir = path.join(process.cwd(), 'uploads', 'avatars');
if (!fs.existsSync(avatarUploadsDir)) {
  fs.mkdirSync(avatarUploadsDir, { recursive: true });
}

const avatarStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, avatarUploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname) || '.png';
    cb(null, `avatar-${uniqueSuffix}${ext}`);
  },
});

const avatarUpload = multer({
  storage: avatarStorage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
});

export const multerAvatarFile = (req: Request, res: Response, next: NextFunction) => {
  avatarUpload.single('file')(req, res, (err: any) => {
    if (err) {
      console.error('[MULTER AVATAR UPLOAD ERROR]:', err);
      return res.status(400).json({ success: false, message: err.message || 'File upload failed' });
    }
    next();
  });
};

export const getTeacherProfileHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const profileIdOrId = req.params.profileId || req.user?.id || req.user?.userId || '';
    const teacher = await teacherService.getOrEnsureTeacherProfile(profileIdOrId);
    console.log(`[TEACHER REQUEST LOG] Endpoint: GET /teacher/profile | JWT Payload: ${JSON.stringify(req.user)} | User: ${req.user?.username} | Teacher ID: ${teacher.id} | Assigned Class: ${teacher.assignedClassName} | HTTP 200`);
    return res.status(200).json({
      success: true,
      data: teacher,
      ...teacher,
    });
  } catch (error: any) {
    console.error('[TEACHER PROFILE ERROR]:', error);
    if (error.message === 'Teacher profile not found') {
      return res.status(404).json({ success: false, message: error.message });
    }
    return res.status(400).json({ success: false, message: error.message || 'Failed to fetch teacher profile' });
  }
};

export const updateTeacherProfileHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const profileIdOrId = req.params.profileId || req.user?.id || req.user?.userId || '';
    const { fullName, full_name, email, phone } = req.body;
    const nameToUpdate = fullName || full_name;

    const teacher = await teacherService.updateTeacherProfileDetails(profileIdOrId, {
      fullName: nameToUpdate,
      email,
      phone,
    });

    return res.status(200).json({
      success: true,
      data: teacher,
      ...teacher,
    });
  } catch (error: any) {
    console.error('[TEACHER PROFILE UPDATE ERROR]:', error);
    return res.status(400).json({ success: false, message: error.message || 'Failed to update teacher profile' });
  }
};

export const uploadTeacherAvatarHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const profileIdOrId = req.params.profileId || req.user?.id || req.user?.userId || '';
    const file = req.file;
    if (!file) {
      return res.status(400).json({ success: false, message: 'File is required' });
    }

    const ext = path.extname(file.originalname).toLowerCase();
    const validExts = ['.jpg', '.jpeg', '.png', '.webp'];
    if (!validExts.includes(ext)) {
      try { fs.unlinkSync(file.path); } catch (_) {}
      return res.status(400).json({ success: false, message: 'Invalid image format. Supported: JPG, JPEG, PNG, WEBP' });
    }

    const avatarUrl = `/uploads/avatars/${file.filename}`;
    const teacher = await teacherService.updateTeacherAvatar(profileIdOrId, avatarUrl);

    return res.status(200).json({
      success: true,
      data: {
        avatarUrl,
        teacher,
        ...teacher,
      },
    });
  } catch (error: any) {
    console.error('[TEACHER AVATAR UPLOAD ERROR]:', error);
    return res.status(400).json({ success: false, message: error.message || 'Failed to upload avatar' });
  }
};

export const getTeacherDashboardHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const dashboardData = await teacherService.getTeacherDashboard(req.user);
    console.log(`[TEACHER REQUEST LOG] Endpoint: GET /teacher/dashboard | JWT Payload: ${JSON.stringify(req.user)} | User: ${req.user?.username} | Teacher ID: ${dashboardData.teacher.id} | Assigned Class: ${dashboardData.assignedClass.className} | Students: ${dashboardData.studentCount} | HTTP 200`);
    return res.status(200).json({
      success: true,
      data: dashboardData,
      ...dashboardData,
    });
  } catch (error: any) {
    console.error('[TEACHER DASHBOARD ERROR]:', error);
    return res.status(400).json({ success: false, message: error.message || 'Failed to load teacher dashboard' });
  }
};

export const getTeacherStudentsHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const students = await teacherService.getTeacherStudents(req.user);
    console.log(`[TEACHER REQUEST LOG] Endpoint: GET /teacher/students | JWT Payload: ${JSON.stringify(req.user)} | User: ${req.user?.username} | Count: ${students.length} | HTTP 200`);
    return res.status(200).json({
      success: true,
      data: students,
      students,
    });
  } catch (error: any) {
    console.error('[TEACHER STUDENTS ERROR]:', error);
    return res.status(200).json({ success: true, data: [], students: [] });
  }
};

export const getTeacherResultsHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const results = await teacherService.getTeacherResults(req.user);
    console.log(`[TEACHER REQUEST LOG] Endpoint: GET /teacher/results | JWT Payload: ${JSON.stringify(req.user)} | User: ${req.user?.username} | Count: ${results.length} | HTTP 200`);
    return res.status(200).json({
      success: true,
      data: results,
      results,
    });
  } catch (error: any) {
    console.error('[TEACHER RESULTS ERROR]:', error);
    return res.status(200).json({ success: true, data: [], results: [] });
  }
};

export const getTeacherNotesHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const notes = await teacherService.getTeacherNotes(req.user);
    console.log(`[TEACHER REQUEST LOG] Endpoint: GET /teacher/notes | JWT Payload: ${JSON.stringify(req.user)} | User: ${req.user?.username} | Count: ${notes.length} | HTTP 200`);
    return res.status(200).json({
      success: true,
      data: notes,
      notes,
    });
  } catch (error: any) {
    console.error('[TEACHER NOTES ERROR]:', error);
    return res.status(200).json({ success: true, data: [], notes: [] });
  }
};

export const getTeacherHallTicketsHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const tickets = await teacherService.getTeacherHallTickets(req.user);
    console.log(`[TEACHER REQUEST LOG] Endpoint: GET /teacher/hall-tickets | JWT Payload: ${JSON.stringify(req.user)} | User: ${req.user?.username} | Count: ${tickets.length} | HTTP 200`);
    return res.status(200).json({
      success: true,
      data: tickets,
      hallTickets: tickets,
    });
  } catch (error: any) {
    console.error('[TEACHER HALL TICKETS ERROR]:', error);
    return res.status(200).json({ success: true, data: [], hallTickets: [] });
  }
};

export const createTeacher = async (req: Request, res: Response, next: NextFunction) => {
  console.log('[POST /api/teachers] Incoming request body:', JSON.stringify(req.body, null, 2));
  try {
    const teacher = await teacherService.createTeacher(req.body);
    await logActivity(req.user?.id, 'Create', 'Teacher', teacher.id, `Created teacher ${teacher.profile?.username || teacher.id}`);
    return res.status(201).json({ success: true, data: teacher });
  } catch (error: any) {
    console.error('[POST /api/teachers ERROR]:', error);

    if (error.message?.includes('already exists')) {
      return res.status(409).json({ success: false, message: error.message });
    }
    if (error.message?.includes('not found')) {
      return res.status(404).json({ success: false, message: error.message });
    }

    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to create teacher',
      error: process.env.NODE_ENV === 'production' ? undefined : (error.stack || error.toString()),
    });
  }
};

export const getTeachers = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const teachers = await teacherService.getAllTeachers();
    return res.status(200).json({ success: true, data: teachers });
  } catch (error) {
    next(error);
  }
};

export const getTeacher = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const teacher = await teacherService.getTeacherById(req.params.id);
    return res.status(200).json({ success: true, data: teacher });
  } catch (error: any) {
    if (error.message === 'Teacher not found') {
      return res.status(404).json({ success: false, message: error.message });
    }
    next(error);
  }
};

export const updateTeacher = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const teacher = await teacherService.updateTeacher(req.params.id, req.body);
    await logActivity(req.user?.id, 'Update', 'Teacher', teacher.id, `Updated teacher ${teacher.profile?.username || teacher.id}`);
    return res.status(200).json({ success: true, data: teacher });
  } catch (error: any) {
    if (error.message === 'Teacher not found') {
      return res.status(404).json({ success: false, message: error.message });
    }
    next(error);
  }
};

export const deleteTeacher = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await teacherService.deleteTeacher(req.params.id);
    await logActivity(req.user?.id, 'Delete', 'Teacher', req.params.id, 'Deleted teacher');
    return res.status(200).json({ success: true, message: 'Teacher deleted successfully' });
  } catch (error: any) {
    if (error.message === 'Teacher not found') {
      return res.status(404).json({ success: false, message: error.message });
    }
    next(error);
  }
};

export const changeTeacherPasswordHandler = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const profileIdOrId = req.params.profileId || req.user?.id || req.user?.userId || '';
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Current password and new password are required.',
      });
    }

    const result = await teacherService.changeTeacherPassword(profileIdOrId, currentPassword, newPassword);
    await logActivity(req.user?.id, 'Change Password', 'Teacher', profileIdOrId, 'Teacher changed authentication password');
    return res.status(200).json(result);
  } catch (error: any) {
    console.error('[CHANGE TEACHER PASSWORD ERROR]:', error);
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to update password',
    });
  }
};
