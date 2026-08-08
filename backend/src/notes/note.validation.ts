import { z } from 'zod';

export const createNoteSchema = z.object({
  body: z.object({
    title: z.string().min(1, 'title is required'),
    description: z.string().optional().or(z.literal('')),
    class_id: z.string().min(1, 'classId is required'),
    subject_id: z.string().optional().or(z.literal('')),
    file_path: z.string().min(1, 'file is required'),
    file_name: z.string().optional().or(z.literal('')),
    file_size: z.number().optional(),
    is_published: z.boolean().default(true),
  }),
});

export const updateNoteSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid note ID'),
  }),
  body: z.object({
    title: z.string().min(1).optional(),
    description: z.string().optional().or(z.literal('')),
    subject_id: z.string().uuid('Invalid subject ID').optional().or(z.literal('')),
    is_published: z.boolean().optional(),
  }),
});

export const noteIdSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid note ID'),
  }),
});
