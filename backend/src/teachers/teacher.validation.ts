import { z } from 'zod';

const optionalNullableString = z.preprocess(
  (val) => (val === '' || val === undefined ? null : val),
  z.string().nullable().optional()
);

const optionalNullableEmail = z.preprocess(
  (val) => (val === '' || val === undefined || val === null ? null : val),
  z.string().email('Invalid email').nullable().optional()
);

export const createTeacherSchema = z.object({
  body: z
    .object({
      fullName: z.string().optional(),
      full_name: z.string().optional(),
      username: optionalNullableString,
      email: optionalNullableEmail,
      phone: optionalNullableString,
      classId: optionalNullableString,
      class_id: optionalNullableString,
      password: optionalNullableString,
      joinedDate: optionalNullableString,
      joined_date: optionalNullableString,
      employeeNumber: optionalNullableString,
      employee_number: optionalNullableString,
      qualification: optionalNullableString,
      id: optionalNullableString,
      profileId: optionalNullableString,
      profile_id: optionalNullableString,
    })
    .passthrough()
    .superRefine((val: any, ctx) => {
      const name = val.fullName || val.full_name;
      if (!name || typeof name !== 'string' || name.trim() === '') {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Full name is required',
          path: ['fullName'],
        });
      }

      const clsId = val.classId || val.class_id;
      if (!clsId || typeof clsId !== 'string' || clsId.trim() === '') {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Class is required.',
          path: ['classId'],
        });
      } else {
        const uuidRegex = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
        if (!uuidRegex.test(clsId.trim())) {
          ctx.addIssue({
            code: z.ZodIssueCode.custom,
            message: 'Class ID must be a valid UUID',
            path: ['classId'],
          });
        }
      }
    }),
});

export const updateTeacherSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid teacher ID'),
  }),
  body: z
    .object({
      fullName: optionalNullableString,
      full_name: optionalNullableString,
      email: optionalNullableEmail,
      phone: optionalNullableString,
      classId: optionalNullableString,
      class_id: optionalNullableString,
      employeeNumber: optionalNullableString,
      employee_number: optionalNullableString,
      qualification: optionalNullableString,
      is_active: z.preprocess((val) => (val === undefined ? null : val), z.boolean().nullable().optional()),
      isActive: z.preprocess((val) => (val === undefined ? null : val), z.boolean().nullable().optional()),
    })
    .passthrough(),
});

export const teacherIdSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid teacher ID'),
  }),
});
