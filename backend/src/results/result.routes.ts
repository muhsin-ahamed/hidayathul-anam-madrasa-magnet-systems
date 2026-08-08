import { Router } from 'express';
import multer from 'multer';
import { createResult, uploadResultsBulk, importResults, getResults, getResult, updateResult, deleteResult } from './result.controller';
import { validate } from '../middleware/validateMiddleware';
import { createResultSchema, updateResultSchema, resultIdSchema } from './result.validation';
import { authenticate } from '../middleware/authMiddleware';
import { authorize } from '../middleware/roleMiddleware';

const upload = multer({ storage: multer.memoryStorage() });
const router = Router();

router.use(authenticate);

// Sub-routes for explicit student/teacher queries & bulk upload/import (must be before /:id)
router.get('/student', authorize(['super_admin', 'class_teacher', 'student']), getResults);
router.get('/teacher', authorize(['super_admin', 'class_teacher']), getResults);
router.post('/bulk', authorize(['super_admin', 'class_teacher']), uploadResultsBulk);
router.post('/import', authorize(['super_admin', 'class_teacher']), upload.single('file'), importResults);

// Super admin and class teacher can mutate results
router.post('/', authorize(['super_admin', 'class_teacher']), validate(createResultSchema), createResult);
router.put('/:id', authorize(['super_admin', 'class_teacher']), validate(updateResultSchema), updateResult);
router.delete('/:id', authorize(['super_admin', 'class_teacher']), validate(resultIdSchema), deleteResult);

// All roles can read results
router.get('/', authorize(['super_admin', 'class_teacher', 'student']), getResults);
router.get('/:id', authorize(['super_admin', 'class_teacher', 'student']), validate(resultIdSchema), getResult);

export default router;
