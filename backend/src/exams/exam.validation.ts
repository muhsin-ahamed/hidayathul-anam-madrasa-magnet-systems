import { z } from 'zod';

export const createExamSchema = z.object({
  exam_name: z.string().optional(),
  examName: z.string().optional(),
  term: z.string().optional().nullable(),
  class_id: z.string().optional(),
  classId: z.string().optional(),
  exam_center: z.string().optional().nullable(),
  examCenter: z.string().optional().nullable(),
  reporting_time: z.string().optional().nullable(),
  reportingTime: z.string().optional().nullable(),
  start_date: z.string().optional().nullable(),
  startDate: z.string().optional().nullable(),
  end_date: z.string().optional().nullable(),
  endDate: z.string().optional().nullable(),
  results_published: z.boolean().optional(),
  resultsPublished: z.boolean().optional(),
  hall_ticket_locked: z.boolean().optional(),
  hallTicketLocked: z.boolean().optional(),
});

export const updateExamSchema = createExamSchema.partial();

export const examIdSchema = z.object({
  params: z.object({
    id: z.string().uuid({ message: 'Invalid Exam ID format' }),
  }),
});
