import express from 'express';
import cors from 'cors';
import path from 'path';
import fs from 'fs';
import { errorHandler } from './middleware/errorMiddleware';
import { authenticate } from './middleware/authMiddleware';

import authRoutes from './auth/auth.routes';
import teacherRoutes from './teachers/teacher.routes';
import studentRoutes from './students/student.routes';
import classRoutes from './classes/class.routes';
import dashboardRoutes from './dashboard/dashboard.routes';
import resultRoutes from './results/result.routes';
import noteRoutes from './notes/note.routes';
import hallTicketRoutes from './hall-tickets/hall-ticket.routes';
import activityLogRoutes from './activity-logs/activity-log.routes';
import examRoutes from './exams/exam.routes';
import subjectRoutes from './subjects/subject.routes';

(BigInt.prototype as any).toJSON = function () {
  return Number(this);
};

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploaded static files
const uploadsPath = path.join(process.cwd(), 'uploads');
if (!fs.existsSync(uploadsPath)) {
  fs.mkdirSync(uploadsPath, { recursive: true });
}
app.use('/uploads', express.static(uploadsPath));

app.get('/', (req, res) => {
  res.json({ success: true, message: 'Backend API is running' });
});

// Signed URL generator endpoint for files
app.post('/api/files/signed-url', authenticate, (req, res) => {
  const filePath = req.body?.path || req.body?.filePath || '';
  if (!filePath) {
    return res.status(400).json({ success: false, message: 'File path is required' });
  }

  if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
    return res.status(200).json({ success: true, data: { signedUrl: filePath } });
  }

  const cleanPath = filePath.startsWith('/') ? filePath : `/${filePath}`;
  const diskPath = path.join(process.cwd(), cleanPath);

  if (!fs.existsSync(diskPath)) {
    return res.status(404).json({ success: false, message: 'File not found on server' });
  }

  const protocol = req.protocol || 'http';
  const host = req.get('host') || 'localhost:5000';
  const signedUrl = `${protocol}://${host}${cleanPath}`;

  return res.status(200).json({
    success: true,
    data: { signedUrl },
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/teachers', teacherRoutes);
app.use('/api/teacher', teacherRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/student', studentRoutes);
app.use('/api/classes', classRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/results', resultRoutes);
app.use('/api/notes', noteRoutes);
app.use('/api/hall-tickets', hallTicketRoutes);
app.use('/api/activity-logs', activityLogRoutes);
app.use('/api/exams', examRoutes);
app.use('/api/subjects', subjectRoutes);

// Catch-all 404 for missing static uploads
app.use('/uploads/*', (req, res) => {
  return res.status(404).json({
    success: false,
    message: 'File not found on server',
  });
});

// Catch-all 404 for missing routes
app.use('*', (req, res) => {
  return res.status(404).json({
    success: false,
    message: 'Resource not found',
  });
});

app.use(errorHandler);

export default app;
