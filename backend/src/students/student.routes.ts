import { Router } from 'express';
import {
  createStudent,
  getStudents,
  getStudent,
  updateStudent,
  deleteStudent,
  deactivateStudentHandler,
  activateStudentHandler,
  getStudentProfileHandler,
  getStudentDashboardHandler,
  getStudentNotesHandler,
  getStudentResultsHandler,
  getStudentHallTicketHandler,
} from './student.controller';
import { validate } from '../middleware/validateMiddleware';
import { createStudentSchema, updateStudentSchema, studentIdSchema } from './student.validation';
import { authenticate } from '../middleware/authMiddleware';
import { authorize } from '../middleware/roleMiddleware';

const router = Router();

router.use(authenticate);

// Student portal endpoints (accessible by student, super_admin, class_teacher)
router.get('/dashboard', getStudentDashboardHandler);
router.get('/profile', getStudentProfileHandler);
router.get('/profile/:profileId', getStudentProfileHandler);
router.get('/notes', getStudentNotesHandler);
router.get('/results', getStudentResultsHandler);
router.get('/hall-ticket', getStudentHallTicketHandler);
router.get('/hall-tickets', getStudentHallTicketHandler);

// Management endpoints (super_admin and class_teacher only)
router.use(authorize(['super_admin', 'class_teacher']));

router.post('/', validate(createStudentSchema), createStudent);
router.get('/', getStudents);
router.get('/:id', validate(studentIdSchema), getStudent);
router.put('/:id', validate(updateStudentSchema), updateStudent);
router.delete('/:id', validate(studentIdSchema), deleteStudent);
router.post('/:id/deactivate', deactivateStudentHandler);
router.post('/:id/activate', activateStudentHandler);

export default router;
