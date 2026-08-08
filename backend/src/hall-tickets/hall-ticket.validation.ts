import { z } from 'zod';

export const createHallTicketSchema = z.object({
  body: z.object({
    exam_id: z.string().uuid('Invalid exam ID'),
    student_id: z.string().uuid('Invalid student ID'),
    issue_date: z.string().optional().or(z.literal('')),
    is_published: z.boolean().default(true),
  }),
});

export const updateHallTicketSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid hall ticket ID'),
  }),
  body: z.object({
    is_published: z.boolean().optional(),
    issue_date: z.string().optional().or(z.literal('')),
  }),
});

export const hallTicketIdSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid hall ticket ID'),
  }),
});
