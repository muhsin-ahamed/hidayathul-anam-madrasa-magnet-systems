import { prisma } from '../config/db';

export const createClass = async (data: any) => {
  if (data.class_teacher_id) {
    const existing = await prisma.classes.findFirst({
      where: { class_teacher_id: data.class_teacher_id },
    });
    if (existing) {
      throw new Error('Teacher is already assigned to another class');
    }
  }

  return await prisma.classes.create({
    data: {
      class_name: data.class_name,
      section: data.section || null,
      academic_year: data.academic_year,
      class_teacher_id: data.class_teacher_id || null,
    },
    include: {
      profile: { select: { full_name: true } }
    }
  });
};

export const getAllClasses = async () => {
  return await prisma.classes.findMany({
    include: {
      profile: { select: { full_name: true } },
      _count: {
        select: { students: true }
      }
    },
    orderBy: { created_at: 'desc' },
  });
};

export const getClassById = async (id: string) => {
  const classData = await prisma.classes.findUnique({
    where: { id },
    include: {
      profile: { select: { full_name: true } },
      students: {
        include: { profile: { select: { full_name: true } } }
      }
    },
  });

  if (!classData) throw new Error('Class not found');
  return classData;
};

export const updateClass = async (id: string, data: any) => {
  const existingClass = await prisma.classes.findUnique({ where: { id } });
  if (!existingClass) throw new Error('Class not found');

  if (data.class_teacher_id && data.class_teacher_id !== existingClass.class_teacher_id) {
    const teacherAssigned = await prisma.classes.findFirst({
      where: { class_teacher_id: data.class_teacher_id },
    });
    if (teacherAssigned) {
      throw new Error('Teacher is already assigned to another class');
    }
  }

  return await prisma.classes.update({
    where: { id },
    data: {
      class_name: data.class_name,
      section: data.section,
      academic_year: data.academic_year,
      class_teacher_id: data.class_teacher_id,
      is_active: data.is_active,
    },
    include: {
      profile: { select: { full_name: true } }
    }
  });
};

export const deleteClass = async (id: string) => {
  const classData = await prisma.classes.findUnique({ where: { id } });
  if (!classData) throw new Error('Class not found');

  await prisma.classes.delete({ where: { id } });
  return { success: true };
};
