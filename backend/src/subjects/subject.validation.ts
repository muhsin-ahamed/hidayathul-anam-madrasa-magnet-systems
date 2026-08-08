import { z } from 'zod';

export const createSubjectSchema = z.object({
  subject_name: z.string().optional(),
  subjectName: z.string().optional(),
  subject_code: z.string().optional().nullable(),
  subjectCode: z.string().optional().nullable(),
  class_id: z.string().optional(),
  classId: z.string().optional(),
  maximum_marks: z.number().or(z.string()).optional(),
  maximumMarks: z.number().or(z.string()).optional(),
  pass_marks: z.number().or(z.string()).optional(),
  passMarks: z.number().or(z.string()).optional(),
  is_active: z.boolean().optional(),
  isActive: z.boolean().optional(),
});

export const updateSubjectSchema = createSubjectSchema.partial();

export const subjectIdSchema = z.object({
  params: z.object({
    id: z.string().uuid({ message: 'Invalid Subject ID format' }),
  }),
});
