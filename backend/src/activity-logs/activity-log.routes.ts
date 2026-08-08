import { Router } from 'express';
import { getActivityLogs, createActivityLog } from './activity-log.controller';
import { authenticate } from '../middleware/authMiddleware';
import { authorize } from '../middleware/roleMiddleware';

const router = Router();

router.use(authenticate);

// Super admin, class teacher, and student can access activity logs
router.get('/', authorize(['super_admin', 'class_teacher', 'student']), getActivityLogs);
router.post('/', authorize(['super_admin', 'class_teacher', 'student']), createActivityLog);

export default router;
