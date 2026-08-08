import { z } from 'zod';

export const createResultSchema = z.object({
  body: z.object({
    exam_id: z.string().uuid('Invalid exam ID').optional(),
    examId: z.string().uuid('Invalid exam ID').optional(),
    student_id: z.string().uuid('Invalid student ID').optional(),
    studentId: z.string().uuid('Invalid student ID').optional(),
    subject_id: z.string().uuid('Invalid subject ID').optional(),
    subjectId: z.string().uuid('Invalid subject ID').optional(),
    marks_obtained: z.number().or(z.string()).optional().nullable(),
    marksObtained: z.number().or(z.string()).optional().nullable(),
    maximum_marks: z.number().or(z.string()).optional(),
    maximumMarks: z.number().or(z.string()).optional(),
    grade: z.string().optional().nullable(),
    result_status: z.string().optional().nullable(),
    resultStatus: z.string().optional().nullable(),
    remarks: z.string().optional().nullable(),
    is_published: z.boolean().optional(),
    isPublished: z.boolean().optional(),
  }),
});

export const updateResultSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid result ID'),
  }),
  body: z.object({
    marks_obtained: z.number().or(z.string()).optional().nullable(),
    marksObtained: z.number().or(z.string()).optional().nullable(),
    maximum_marks: z.number().or(z.string()).optional(),
    maximumMarks: z.number().or(z.string()).optional(),
    grade: z.string().optional().nullable(),
    result_status: z.string().optional().nullable(),
    resultStatus: z.string().optional().nullable(),
    remarks: z.string().optional().nullable(),
    is_published: z.boolean().optional(),
    isPublished: z.boolean().optional(),
  }),
});

export const resultIdSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid result ID'),
  }),
});
