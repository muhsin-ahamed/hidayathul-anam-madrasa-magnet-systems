import { Router } from 'express';
import {
  createTeacher,
  getTeachers,
  getTeacher,
  updateTeacher,
  deleteTeacher,
  getTeacherProfileHandler,
  updateTeacherProfileHandler,
  uploadTeacherAvatarHandler,
  multerAvatarFile,
  getTeacherDashboardHandler,
  getTeacherStudentsHandler,
  getTeacherResultsHandler,
  getTeacherNotesHandler,
  getTeacherHallTicketsHandler,
  changeTeacherPasswordHandler,
} from './teacher.controller';
import { validate } from '../middleware/validateMiddleware';
import { createTeacherSchema, updateTeacherSchema, teacherIdSchema } from './teacher.validation';
import { authenticate } from '../middleware/authMiddleware';
import { authorize } from '../middleware/roleMiddleware';

const router = Router();

router.use(authenticate);

// 1. Workspace endpoints accessible by class_teacher and super_admin
router.put('/change-password', authorize(['class_teacher', 'super_admin']), changeTeacherPasswordHandler);
router.put('/profile/password', authorize(['class_teacher', 'super_admin']), changeTeacherPasswordHandler);
router.get('/profile', authorize(['class_teacher', 'super_admin']), getTeacherProfileHandler);
router.get('/profile/:profileId', authorize(['class_teacher', 'super_admin']), getTeacherProfileHandler);
router.put('/profile', authorize(['class_teacher', 'super_admin']), updateTeacherProfileHandler);
router.put('/profile/:profileId', authorize(['class_teacher', 'super_admin']), updateTeacherProfileHandler);
router.post('/profile/avatar', authorize(['class_teacher', 'super_admin']), multerAvatarFile, uploadTeacherAvatarHandler);
router.post('/profile/:profileId/avatar', authorize(['class_teacher', 'super_admin']), multerAvatarFile, uploadTeacherAvatarHandler);
router.get('/dashboard', authorize(['class_teacher', 'super_admin']), getTeacherDashboardHandler);
router.get('/students', authorize(['class_teacher', 'super_admin']), getTeacherStudentsHandler);
router.get('/results', authorize(['class_teacher', 'super_admin']), getTeacherResultsHandler);
router.get('/notes', authorize(['class_teacher', 'super_admin']), getTeacherNotesHandler);
router.get('/hall-tickets', authorize(['class_teacher', 'super_admin']), getTeacherHallTicketsHandler);
router.get('/hall-ticket', authorize(['class_teacher', 'super_admin']), getTeacherHallTicketsHandler);

// 2. Super admin management endpoints
router.post('/', authorize(['super_admin']), validate(createTeacherSchema), createTeacher);
router.get('/', authorize(['super_admin']), getTeachers);
router.get('/:id', authorize(['super_admin']), validate(teacherIdSchema), getTeacher);
router.put('/:id', authorize(['super_admin']), validate(updateTeacherSchema), updateTeacher);
router.delete('/:id', authorize(['super_admin']), validate(teacherIdSchema), deleteTeacher);

export default router;
