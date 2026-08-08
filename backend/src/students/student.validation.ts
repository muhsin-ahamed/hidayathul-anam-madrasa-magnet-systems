import { z } from 'zod';

const optionalNullableString = z.preprocess(
  (val) => (val === '' || val === undefined ? null : val),
  z.string().nullable().optional()
);

export const createStudentSchema = z.object({
  body: z
    .object({
      id: optionalNullableString,
      profile_id: optionalNullableString,
      profileId: optionalNullableString,
      admission_number: z.string().optional(),
      admissionNumber: z.string().optional(),
      roll_number: z.string().optional(),
      rollNumber: z.string().optional(),
      full_name: z.string().optional(),
      fullName: z.string().optional(),
      class_id: optionalNullableString,
      classId: optionalNullableString,
      date_of_birth: optionalNullableString,
      dateOfBirth: optionalNullableString,
      gender: optionalNullableString,
      guardian_name: optionalNullableString,
      guardianName: optionalNullableString,
      guardian_phone: optionalNullableString,
      guardianPhone: optionalNullableString,
      address: optionalNullableString,
      photo_path: optionalNullableString,
      photoPath: optionalNullableString,
      is_active: z.preprocess((val) => (val === undefined ? null : val), z.boolean().nullable().optional()),
      isActive: z.preprocess((val) => (val === undefined ? null : val), z.boolean().nullable().optional()),
      email: optionalNullableString,
      password: optionalNullableString,
    })
    .passthrough()
    .superRefine((val: any, ctx) => {
      const admNum = val.admission_number || val.admissionNumber;
      if (!admNum || typeof admNum !== 'string' || admNum.trim() === '') {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Admission number is required',
          path: ['admission_number'],
        });
      }

      const rollNum = val.roll_number || val.rollNumber;
      if (!rollNum || typeof rollNum !== 'string' || rollNum.trim() === '') {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Roll number is required',
          path: ['roll_number'],
        });
      }

      const name = val.full_name || val.fullName;
      if (!name || typeof name !== 'string' || name.trim() === '') {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Full name is required',
          path: ['full_name'],
        });
      }

      const clsId = val.class_id || val.classId;
      if (!clsId || typeof clsId !== 'string' || clsId.trim() === '') {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Student must be assigned to a class.',
          path: ['class_id'],
        });
      } else {
        const uuidRegex = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
        if (!uuidRegex.test(clsId.trim())) {
          ctx.addIssue({
            code: z.ZodIssueCode.custom,
            message: 'Class ID must be a valid UUID',
            path: ['class_id'],
          });
        }
      }
    }),
});

export const updateStudentSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid student ID'),
  }),
  body: z
    .object({
      roll_number: optionalNullableString,
      rollNumber: optionalNullableString,
      full_name: optionalNullableString,
      fullName: optionalNullableString,
      class_id: optionalNullableString,
      classId: optionalNullableString,
      date_of_birth: optionalNullableString,
      dateOfBirth: optionalNullableString,
      gender: optionalNullableString,
      guardian_name: optionalNullableString,
      guardianName: optionalNullableString,
      guardian_phone: optionalNullableString,
      guardianPhone: optionalNullableString,
      address: optionalNullableString,
      photo_path: optionalNullableString,
      photoPath: optionalNullableString,
      is_active: z.preprocess((val) => (val === undefined ? null : val), z.boolean().nullable().optional()),
      isActive: z.preprocess((val) => (val === undefined ? null : val), z.boolean().nullable().optional()),
    })
    .passthrough(),
});

export const studentIdSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid student ID'),
  }),
});
