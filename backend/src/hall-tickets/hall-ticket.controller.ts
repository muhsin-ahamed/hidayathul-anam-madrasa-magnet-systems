import { Request, Response, NextFunction } from 'express';
import * as hallTicketService from './hall-ticket.service';
import { logActivity } from '../utils/logger';

export const createHallTicket = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const hallTicket = await hallTicketService.createHallTicket(req.body, req.user);
    await logActivity(req.user?.id, 'Issue', 'Hall Ticket', hallTicket.id, `Issued hall ticket for student ${hallTicket.student?.admission_number || hallTicket.student_id}`);
    return res.status(201).json({ success: true, data: hallTicket });
  } catch (error: any) {
    if (error.message === 'Student not found') return res.status(404).json({ success: false, message: error.message });
    if (error.message === 'Hall ticket already exists for this exam and student') return res.status(409).json({ success: false, message: error.message });
    if (error.message === 'Not authorized to issue hall ticket for this student') return res.status(403).json({ success: false, message: error.message });
    next(error);
  }
};

export const getHallTickets = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.query.classId as string | undefined;
    const hallTickets = await hallTicketService.getAllHallTickets(req.user, classId);
    return res.status(200).json({ success: true, data: hallTickets || [] });
  } catch (error) {
    console.error('[GET HALL TICKETS ERROR]:', error);
    return res.status(200).json({ success: true, data: [] });
  }
};

export const getHallTicket = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const hallTicket = await hallTicketService.getHallTicketById(req.params.id, req.user);
    return res.status(200).json({ success: true, data: hallTicket });
  } catch (error: any) {
    if (error.message === 'Not authorized to access this hall ticket') {
      return res.status(403).json({ success: false, message: error.message });
    }
    // Requirement 3 & 9: Return 200 with data: null when record is not found
    return res.status(200).json({ success: true, data: null });
  }
};

export const updateHallTicket = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const hallTicket = await hallTicketService.updateHallTicket(req.params.id, req.body, req.user);
    await logActivity(req.user?.id, 'Update', 'Hall Ticket', hallTicket.id, `Updated hall ticket ${hallTicket.id}`);
    return res.status(200).json({ success: true, data: hallTicket });
  } catch (error: any) {
    if (error.message === 'Hall ticket not found') return res.status(404).json({ success: false, message: error.message });
    if (error.message === 'Not authorized to update this hall ticket') return res.status(403).json({ success: false, message: error.message });
    next(error);
  }
};

export const deleteHallTicket = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await hallTicketService.deleteHallTicket(req.params.id, req.user);
    await logActivity(req.user?.id, 'Delete', 'Hall Ticket', req.params.id, 'Deleted hall ticket');
    return res.status(200).json({ success: true, message: 'Hall ticket deleted successfully' });
  } catch (error: any) {
    if (error.message === 'Hall ticket not found') return res.status(404).json({ success: false, message: error.message });
    if (error.message === 'Not authorized to delete this hall ticket') return res.status(403).json({ success: false, message: error.message });
    next(error);
  }
};
