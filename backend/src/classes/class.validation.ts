import { z } from 'zod';

export const createClassSchema = z.object({
  body: z.object({
    class_name: z.string().min(1, 'Class name is required'),
    section: z.string().optional().or(z.literal('')),
    academic_year: z.string().min(1, 'Academic year is required'),
    class_teacher_id: z.string().uuid('Invalid teacher ID').optional().or(z.literal('')),
  }),
});

export const updateClassSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid class ID'),
  }),
  body: z.object({
    class_name: z.string().min(1).optional(),
    section: z.string().optional().or(z.literal('')),
    academic_year: z.string().min(1).optional(),
    class_teacher_id: z.string().uuid('Invalid teacher ID').optional().nullable(),
    is_active: z.boolean().optional(),
  }),
});

export const classIdSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid class ID'),
  }),
});
