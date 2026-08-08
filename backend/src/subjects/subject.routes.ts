import { Router } from 'express';
import { getSubjects, getSubject, createSubject, updateSubject, deactivateSubject } from './subject.controller';
import { validate } from '../middleware/validateMiddleware';
import { createSubjectSchema, updateSubjectSchema, subjectIdSchema } from './subject.validation';
import { authenticate } from '../middleware/authMiddleware';
import { authorize } from '../middleware/roleMiddleware';

const router = Router();

router.use(authenticate);

// Mutate routes (Super admin & class teacher)
router.post('/', authorize(['super_admin', 'class_teacher']), validate(createSubjectSchema), createSubject);
router.put('/:id', authorize(['super_admin', 'class_teacher']), validate(updateSubjectSchema), updateSubject);
router.post('/:id/deactivate', authorize(['super_admin', 'class_teacher']), validate(subjectIdSchema), deactivateSubject);
router.delete('/:id', authorize(['super_admin', 'class_teacher']), validate(subjectIdSchema), deactivateSubject);

// Read routes (Super admin, class teacher, student)
router.get('/', authorize(['super_admin', 'class_teacher', 'student']), getSubjects);
router.get('/:id', authorize(['super_admin', 'class_teacher', 'student']), validate(subjectIdSchema), getSubject);

export default router;
