import { Router } from 'express';
import { createClass, getClasses, getClass, updateClass, deleteClass } from './class.controller';
import { validate } from '../middleware/validateMiddleware';
import { createClassSchema, updateClassSchema, classIdSchema } from './class.validation';
import { authenticate } from '../middleware/authMiddleware';
import { authorize } from '../middleware/roleMiddleware';

const router = Router();

router.use(authenticate);

// Super admin only for mutating classes
router.post('/', authorize(['super_admin']), validate(createClassSchema), createClass);
router.put('/:id', authorize(['super_admin']), validate(updateClassSchema), updateClass);
router.delete('/:id', authorize(['super_admin']), validate(classIdSchema), deleteClass);

// Super admin and class teacher can read classes
router.get('/', authorize(['super_admin', 'class_teacher']), getClasses);
router.get('/:id', authorize(['super_admin', 'class_teacher']), validate(classIdSchema), getClass);

export default router;
