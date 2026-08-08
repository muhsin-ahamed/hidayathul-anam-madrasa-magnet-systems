import { prisma } from '../config/db';
import { getSubjectsForClass, isValidSubjectForClass } from '../config/subjects';

export const ensureClassSubjectsInDb = async (classId: string) => {
  const cls = await prisma.classes.findUnique({ where: { id: classId } });
  if (!cls) return;

  const allowedSubjects = getSubjectsForClass(cls.class_name);
  const existingSubjects = await prisma.subjects.findMany({
    where: { class_id: classId },
  });

  for (const name of allowedSubjects) {
    const exists = existingSubjects.some(
      (s) => s.subject_name.trim().toLowerCase() === name.trim().toLowerCase()
    );
    if (!exists) {
      await prisma.subjects.create({
        data: {
          subject_name: name,
          subject_code: name,
          class_id: classId,
          maximum_marks: 100,
          pass_marks: 35,
          is_active: true,
        },
      });
    }
  }
};

export const getAllSubjects = async (user: any, classIdQuery?: string) => {
  let filter: any = {};

  if (classIdQuery && classIdQuery.trim() !== '') {
    filter.class_id = classIdQuery.trim();
  } else if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (teacherClass) {
      filter.class_id = teacherClass.id;
    }
  } else if (user.role === 'student') {
    const student = await prisma.students.findUnique({
      where: { profile_id: user.id },
    });
    if (student) {
      filter.class_id = student.class_id;
    }
  }

  if (filter.class_id) {
    await ensureClassSubjectsInDb(filter.class_id);
  }

  const subjects = await prisma.subjects.findMany({
    where: filter,
    include: {
      class: { select: { id: true, class_name: true, section: true } },
    },
    orderBy: { created_at: 'asc' },
  });

  const validSubjects = subjects.filter((s) => {
    if (!s.class) return true;
    return isValidSubjectForClass(s.class.class_name, s.subject_name);
  });

  return validSubjects.map((s) => ({
    ...s,
    subjectName: s.subject_name,
    subjectCode: s.subject_code,
    classId: s.class_id,
    maximumMarks: Number(s.maximum_marks),
    passMarks: Number(s.pass_marks),
    isActive: s.is_active,
  }));
};

export const getSubjectById = async (id: string) => {
  const subject = await prisma.subjects.findUnique({
    where: { id },
    include: {
      class: { select: { id: true, class_name: true, section: true } },
    },
  });

  if (!subject) return null;

  return {
    ...subject,
    subjectName: subject.subject_name,
    subjectCode: subject.subject_code,
    classId: subject.class_id,
    maximumMarks: Number(subject.maximum_marks),
    passMarks: Number(subject.pass_marks),
    isActive: subject.is_active,
  };
};

export const createSubject = async (rawData: any, user: any) => {
  const subjectName = (rawData.subject_name || rawData.subjectName || '').trim();
  const classId = (rawData.class_id || rawData.classId || '').trim();
  const subjectCode = rawData.subject_code || rawData.subjectCode || null;
  const maxMarks = rawData.maximum_marks ?? rawData.maximumMarks ?? 100;
  const passMarks = rawData.pass_marks ?? rawData.passMarks ?? 35;

  if (!subjectName) throw new Error('Subject name is required');
  if (!classId) throw new Error('Class ID is required');

  const created = await prisma.subjects.create({
    data: {
      subject_name: subjectName,
      subject_code: subjectCode,
      class_id: classId,
      maximum_marks: maxMarks,
      pass_marks: passMarks,
      is_active: rawData.is_active ?? rawData.isActive ?? true,
    },
    include: {
      class: { select: { id: true, class_name: true, section: true } },
    },
  });

  return {
    ...created,
    subjectName: created.subject_name,
    subjectCode: created.subject_code,
    classId: created.class_id,
    maximumMarks: Number(created.maximum_marks),
    passMarks: Number(created.pass_marks),
    isActive: created.is_active,
  };
};

export const updateSubject = async (id: string, rawData: any, user: any) => {
  const subjectName = rawData.subject_name || rawData.subjectName;
  const classId = rawData.class_id || rawData.classId;

  const updated = await prisma.subjects.update({
    where: { id },
    data: {
      subject_name: subjectName ? subjectName.trim() : undefined,
      subject_code: rawData.subject_code !== undefined ? rawData.subject_code : rawData.subjectCode,
      class_id: classId ? classId.trim() : undefined,
      maximum_marks: rawData.maximum_marks ?? rawData.maximumMarks,
      pass_marks: rawData.pass_marks ?? rawData.passMarks,
      is_active: rawData.is_active ?? rawData.isActive,
    },
    include: {
      class: { select: { id: true, class_name: true, section: true } },
    },
  });

  return {
    ...updated,
    subjectName: updated.subject_name,
    subjectCode: updated.subject_code,
    classId: updated.class_id,
    maximumMarks: Number(updated.maximum_marks),
    passMarks: Number(updated.pass_marks),
    isActive: updated.is_active,
  };
};

export const deactivateSubject = async (id: string) => {
  const updated = await prisma.subjects.update({
    where: { id },
    data: { is_active: false },
  });
  return updated;
};
