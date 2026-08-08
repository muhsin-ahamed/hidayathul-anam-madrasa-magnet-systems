import { Router } from 'express';
import { login, logout, me } from './auth.controller';
import { validate } from '../middleware/validateMiddleware';
import { loginSchema } from './auth.validation';
import { authenticate } from '../middleware/authMiddleware';

const router = Router();

router.post('/login', validate(loginSchema), login);
router.post('/logout', authenticate, logout);
router.get('/me', authenticate, me);

export default router;
