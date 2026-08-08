import { Router, Request, Response, NextFunction } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { createNote, getNotes, getNote, updateNote, deleteNote } from './note.controller';
import { validate } from '../middleware/validateMiddleware';
import { createNoteSchema, updateNoteSchema, noteIdSchema } from './note.validation';
import { authenticate } from '../middleware/authMiddleware';
import { authorize } from '../middleware/roleMiddleware';
import { prisma } from '../config/db';

const uploadsDir = path.join(process.cwd(), 'uploads', 'notes');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname) || '.pdf';
    cb(null, `note-${uniqueSuffix}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 25 * 1024 * 1024 }, // 25MB
});

const multerSingleFile = (req: Request, res: Response, next: NextFunction) => {
  upload.single('file')(req, res, (err: any) => {
    if (err) {
      console.error('[MULTER NOTE UPLOAD ERROR]:', err);
      return res.status(400).json({ success: false, message: err.message || 'File upload failed' });
    }
    next();
  });
};

const noteUploadAuditAndValidation = async (req: Request, res: Response, next: NextFunction) => {
  const rawBody = req.body || {};
  const file = req.file;

  // Requirement 1: Add logging before validation
  console.log('--------------------------------------------------');
  console.log('[NOTE UPLOAD AUDIT] req.body:', JSON.stringify(rawBody, null, 2));
  console.log('[NOTE UPLOAD AUDIT] req.file:', file ? {
    fieldname: file.fieldname,
    originalname: file.originalname,
    mimetype: file.mimetype,
    size: file.size,
    path: file.path,
  } : undefined);

  const parsedFormData = {
    title: rawBody.title,
    classId: rawBody.classId || rawBody.class_id,
    subject: rawBody.subject || rawBody.subjectId || rawBody.subject_id,
    uploadedBy: rawBody.uploadedBy || rawBody.teacherId || rawBody.teacher_id,
    teacherId: rawBody.teacherId || rawBody.teacher_id || rawBody.uploadedBy,
    fileUrl: file ? `/uploads/notes/${file.filename}` : (rawBody.fileUrl || rawBody.file_path),
    fileName: file ? file.originalname : (rawBody.fileName || rawBody.file_name),
  };
  console.log('[NOTE UPLOAD AUDIT] Parsed FormData:', JSON.stringify(parsedFormData, null, 2));
  console.log('--------------------------------------------------');

  // Requirement 2 & 6: Identify missing/undefined required fields and return HTTP 400
  const title = (rawBody.title ?? '').toString().trim();
  const classId = (rawBody.classId || rawBody.class_id || '').toString().trim();
  const subjectVal = (rawBody.subject || rawBody.subjectId || rawBody.subject_id || '').toString().trim();

  if (!file && !rawBody.fileUrl && !rawBody.file_path) {
    return res.status(400).json({ success: false, message: 'file is required' });
  }

  // Requirement 5: Validate uploaded PDF
  if (file) {
    const isPdfExt = file.originalname.toLowerCase().endsWith('.pdf');
    const isPdfMime = file.mimetype === 'application/pdf' || file.mimetype === 'application/x-pdf' || file.mimetype === 'application/octet-stream';
    if (!isPdfExt && !isPdfMime) {
      try { fs.unlinkSync(file.path); } catch (_) {}
      return res.status(400).json({ success: false, message: 'Only PDF files are allowed' });
    }
  }

  if (!title) {
    return res.status(400).json({ success: false, message: 'title is required' });
  }

  if (!classId) {
    return res.status(400).json({ success: false, message: 'classId is required' });
  }

  if (!subjectVal) {
    return res.status(400).json({ success: false, message: 'subject is required' });
  }

  // Requirement 3 & 4: Normalize fields in req.body for createNoteSchema & createNote service
  req.body.title = title;
  req.body.description = rawBody.description || '';
  req.body.class_id = classId;
  req.body.file_path = file ? `/uploads/notes/${file.filename}` : (rawBody.file_path || rawBody.fileUrl);
  req.body.file_name = file ? file.originalname : (rawBody.file_name || rawBody.fileName || title);
  req.body.file_size = file ? file.size : (Number(rawBody.file_size) || undefined);
  req.body.is_published = rawBody.is_published === 'false' || rawBody.is_published === false ? false : true;

  // Resolve subject_id if UUID or subject_name
  if (subjectVal) {
    const isUuid = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(subjectVal);
    if (isUuid) {
      req.body.subject_id = subjectVal;
    } else {
      const sub = await prisma.subjects.findFirst({
        where: { class_id: classId, subject_name: subjectVal }
      });
      if (sub) {
        req.body.subject_id = sub.id;
      } else {
        const newSub = await prisma.subjects.create({
          data: {
            subject_name: subjectVal,
            class_id: classId,
          }
        }).catch(() => null);
        if (newSub) req.body.subject_id = newSub.id;
      }
    }
  }

  next();
};

const router = Router();

router.use(authenticate);

// Sub-routes for explicit student/teacher queries (must be before /:id)
router.get('/student', authorize(['super_admin', 'class_teacher', 'student']), getNotes);
router.get('/teacher', authorize(['super_admin', 'class_teacher']), getNotes);

// Super admin and class teacher can mutate notes
router.post('/', authorize(['super_admin', 'class_teacher']), multerSingleFile, noteUploadAuditAndValidation, validate(createNoteSchema), createNote);
router.put('/:id', authorize(['super_admin', 'class_teacher']), validate(updateNoteSchema), updateNote);
router.delete('/:id', authorize(['super_admin', 'class_teacher']), validate(noteIdSchema), deleteNote);

// All roles can read notes (service layer handles role-specific filtering)
router.get('/', authorize(['super_admin', 'class_teacher', 'student']), getNotes);
router.get('/:id', authorize(['super_admin', 'class_teacher', 'student']), validate(noteIdSchema), getNote);

export default router;
