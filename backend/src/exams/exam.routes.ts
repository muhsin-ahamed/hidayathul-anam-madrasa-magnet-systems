import { Router } from 'express';
import {
  getExams,
  getExam,
  createExam,
  updateExam,
  deleteExam,
  setResultsPublishedHandler,
  setHallTicketsLockedHandler,
  getExamSubjectsHandler,
  saveExamSubjectsHandler,
} from './exam.controller';
import { validate } from '../middleware/validateMiddleware';
import { createExamSchema, updateExamSchema, examIdSchema } from './exam.validation';
import { authenticate } from '../middleware/authMiddleware';
import { authorize } from '../middleware/roleMiddleware';

const router = Router();

router.use(authenticate);

// Sub-routes before /:id
router.post('/:id/results/publish', authorize(['super_admin', 'class_teacher']), setResultsPublishedHandler);
router.post('/:id/hall-tickets/lock', authorize(['super_admin', 'class_teacher']), setHallTicketsLockedHandler);
router.get('/:id/subjects', authorize(['super_admin', 'class_teacher', 'student']), getExamSubjectsHandler);
router.post('/:id/subjects', authorize(['super_admin', 'class_teacher']), saveExamSubjectsHandler);

// Mutate routes
router.post('/', authorize(['super_admin', 'class_teacher']), validate(createExamSchema), createExam);
router.put('/:id', authorize(['super_admin', 'class_teacher']), validate(updateExamSchema), updateExam);
router.delete('/:id', authorize(['super_admin', 'class_teacher']), validate(examIdSchema), deleteExam);

// Read routes
router.get('/', authorize(['super_admin', 'class_teacher', 'student']), getExams);
router.get('/:id', authorize(['super_admin', 'class_teacher', 'student']), validate(examIdSchema), getExam);

export default router;
