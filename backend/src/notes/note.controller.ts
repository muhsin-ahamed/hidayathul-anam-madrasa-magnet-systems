import { Request, Response, NextFunction } from 'express';
import * as noteService from './note.service';
import { logActivity } from '../utils/logger';

export const createNote = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const note = await noteService.createNote(req.body, req.user);
    await logActivity(req.user?.id, 'Upload Note', 'Note', note.id, `Uploaded note ${note.title}`);
    return res.status(201).json({ success: true, data: note });
  } catch (error: any) {
    if (error.message === 'Not authorized to upload notes for this class') return res.status(403).json({ success: false, message: error.message });
    if (error.message?.includes('Invalid subject') || error.message?.includes('is not allowed for')) return res.status(400).json({ success: false, message: error.message });
    next(error);
  }
};

export const getNotes = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.query.classId as string | undefined;
    const notes = await noteService.getAllNotes(req.user, classId);
    return res.status(200).json({ success: true, data: notes || [] });
  } catch (error) {
    console.error('[GET NOTES ERROR]:', error);
    return res.status(200).json({ success: true, data: [] });
  }
};

export const getNote = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const note = await noteService.getNoteById(req.params.id, req.user);
    return res.status(200).json({ success: true, data: note });
  } catch (error: any) {
    if (error.message === 'Not authorized to access this note') {
      return res.status(403).json({ success: false, message: error.message });
    }
    // Requirement 3 & 9: Return 200 with data: null when record is not found
    return res.status(200).json({ success: true, data: null });
  }
};

export const updateNote = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const note = await noteService.updateNote(req.params.id, req.body, req.user);
    await logActivity(req.user?.id, 'Update', 'Note', note.id, `Updated note ${note.title}`);
    return res.status(200).json({ success: true, data: note });
  } catch (error: any) {
    if (error.message === 'Note not found') return res.status(404).json({ success: false, message: error.message });
    if (error.message === 'Not authorized to update this note') return res.status(403).json({ success: false, message: error.message });
    if (error.message?.includes('Invalid subject') || error.message?.includes('is not allowed for')) return res.status(400).json({ success: false, message: error.message });
    next(error);
  }
};

export const deleteNote = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await noteService.deleteNote(req.params.id, req.user);
    await logActivity(req.user?.id, 'Delete', 'Note', req.params.id, 'Deleted note');
    return res.status(200).json({ success: true, message: 'Note deleted successfully' });
  } catch (error: any) {
    if (error.message === 'Note not found') return res.status(404).json({ success: false, message: error.message });
    if (error.message === 'Not authorized to delete this note') return res.status(403).json({ success: false, message: error.message });
    next(error);
  }
};
