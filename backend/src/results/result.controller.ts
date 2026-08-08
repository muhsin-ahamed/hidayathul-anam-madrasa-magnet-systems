import { Request, Response, NextFunction } from 'express';
import * as resultService from './result.service';
import { logActivity } from '../utils/logger';

export const createResult = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await resultService.createResult(req.body, req.user);
    await logActivity(req.user?.id, 'Upload Result', 'Result', result.id, `Uploaded result for student ${result.student?.admission_number || result.student_id}`);
    return res.status(201).json({ success: true, data: result });
  } catch (error: any) {
    if (error.message === 'Student not found') return res.status(404).json({ success: false, message: error.message });
    if (error.message === 'Not authorized to upload result for this student') return res.status(403).json({ success: false, message: error.message });
    if (error.message?.includes('cannot exceed maximum marks')) return res.status(400).json({ success: false, message: error.message });
    return res.status(400).json({ success: false, message: error.message || 'Failed to create result' });
  }
};

export const uploadResultsBulk = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const results = await resultService.uploadResultsBulk(req.body, req.user);
    await logActivity(req.user?.id, 'Bulk Upload Results', 'Result', req.body.examId || '', 'Uploaded bulk results');
    return res.status(200).json({ success: true, data: results });
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message || 'Failed to upload bulk results' });
  }
};

export const importResults = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const fileBuffer = req.file ? req.file.buffer : undefined;
    const summary = await resultService.importResults(fileBuffer, req.body, req.user);
    await logActivity(req.user?.id, 'Import Results', 'Result', '', `Imported ${summary.importedCount} results from Excel/JSON (${summary.skippedCount} skipped)`);
    return res.status(200).json({
      success: true,
      message: `Successfully imported ${summary.importedCount} results (${summary.skippedCount} skipped)`,
      importedCount: summary.importedCount,
      skippedCount: summary.skippedCount,
      errors: summary.errors,
      data: summary.data,
    });
  } catch (error: any) {
    return res.status(400).json({ success: false, message: error.message || 'Failed to import results' });
  }
};

export const getResults = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.query.classId as string | undefined;
    const results = await resultService.getAllResults(req.user, classId);
    return res.status(200).json({ success: true, data: results || [] });
  } catch (error) {
    console.error('[GET RESULTS ERROR]:', error);
    return res.status(200).json({ success: true, data: [] });
  }
};

export const getResult = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await resultService.getResultById(req.params.id, req.user);
    return res.status(200).json({ success: true, data: result });
  } catch (error: any) {
    if (error.message === 'Not authorized to access this result') {
      return res.status(403).json({ success: false, message: error.message });
    }
    return res.status(200).json({ success: true, data: null });
  }
};

export const updateResult = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await resultService.updateResult(req.params.id, req.body, req.user);
    await logActivity(req.user?.id, 'Update', 'Result', result.id, `Updated result ${result.id}`);
    return res.status(200).json({ success: true, data: result });
  } catch (error: any) {
    if (error.message === 'Result not found') return res.status(404).json({ success: false, message: error.message });
    if (error.message === 'Not authorized to update this result') return res.status(403).json({ success: false, message: error.message });
    if (error.message?.includes('cannot exceed maximum marks')) return res.status(400).json({ success: false, message: error.message });
    return res.status(400).json({ success: false, message: error.message || 'Failed to update result' });
  }
};

export const deleteResult = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await resultService.deleteResult(req.params.id, req.user);
    await logActivity(req.user?.id, 'Delete', 'Result', req.params.id, 'Deleted result');
    return res.status(200).json({ success: true, message: 'Result deleted successfully' });
  } catch (error: any) {
    if (error.message === 'Result not found') return res.status(404).json({ success: false, message: error.message });
    if (error.message === 'Not authorized to delete this result') return res.status(403).json({ success: false, message: error.message });
    return res.status(400).json({ success: false, message: error.message || 'Failed to delete result' });
  }
};
