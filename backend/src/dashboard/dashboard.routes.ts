import { Router } from 'express';
import { getDashboard } from './dashboard.controller';
import { authenticate } from '../middleware/authMiddleware';
import { authorize } from '../middleware/roleMiddleware';

const router = Router();

router.use(authenticate);
router.use(authorize(['super_admin', 'class_teacher', 'student']));
router.get('/', getDashboard);

export default router;
