import { Router } from 'express';
import { createHallTicket, getHallTickets, getHallTicket, updateHallTicket, deleteHallTicket } from './hall-ticket.controller';
import { validate } from '../middleware/validateMiddleware';
import { createHallTicketSchema, updateHallTicketSchema, hallTicketIdSchema } from './hall-ticket.validation';
import { authenticate } from '../middleware/authMiddleware';
import { authorize } from '../middleware/roleMiddleware';

const router = Router();

router.use(authenticate);

// Sub-routes for explicit student/teacher queries (must be before /:id)
router.get('/student', authorize(['super_admin', 'class_teacher', 'student']), getHallTickets);
router.get('/teacher', authorize(['super_admin', 'class_teacher']), getHallTickets);

// Super admin and class teacher can mutate hall tickets
router.post('/', authorize(['super_admin', 'class_teacher']), validate(createHallTicketSchema), createHallTicket);
router.put('/:id', authorize(['super_admin', 'class_teacher']), validate(updateHallTicketSchema), updateHallTicket);
router.delete('/:id', authorize(['super_admin', 'class_teacher']), validate(hallTicketIdSchema), deleteHallTicket);

// All roles can read hall tickets (service layer handles role-specific filtering)
router.get('/', authorize(['super_admin', 'class_teacher', 'student']), getHallTickets);
router.get('/:id', authorize(['super_admin', 'class_teacher', 'student']), validate(hallTicketIdSchema), getHallTicket);

export default router;
