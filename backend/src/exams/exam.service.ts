import { prisma } from '../config/db';

export const getAllExams = async (user: any, classIdQuery?: string) => {
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

  const exams = await prisma.exams.findMany({
    where: filter,
    include: {
      class: { select: { id: true, class_name: true, section: true } },
    },
    orderBy: { created_at: 'desc' },
  });

  return exams.map((e) => ({
    ...e,
    examName: e.exam_name,
    classId: e.class_id,
    examCenter: e.exam_center,
    reportingTime: e.reporting_time ? e.reporting_time.toISOString() : null,
    startDate: e.start_date,
    endDate: e.end_date,
    resultsPublished: e.results_published,
    hallTicketLocked: e.hall_ticket_locked,
    createdBy: e.created_by,
    classes: e.class,
  }));
};

export const getExamById = async (id: string) => {
  const exam = await prisma.exams.findUnique({
    where: { id },
    include: {
      class: { select: { id: true, class_name: true, section: true } },
    },
  });

  if (!exam) return null;

  return {
    ...exam,
    examName: exam.exam_name,
    classId: exam.class_id,
    examCenter: exam.exam_center,
    reportingTime: exam.reporting_time ? exam.reporting_time.toISOString() : null,
    startDate: exam.start_date,
    endDate: exam.end_date,
    resultsPublished: exam.results_published,
    hallTicketLocked: exam.hall_ticket_locked,
    createdBy: exam.created_by,
    classes: exam.class,
  };
};

export const createExam = async (rawData: any, user: any) => {
  const examName = (rawData.exam_name || rawData.examName || '').trim();
  const classId = (rawData.class_id || rawData.classId || '').trim();

  if (!examName) throw new Error('Exam name is required');
  if (!classId) throw new Error('Class ID is required');

  const startDate = rawData.start_date || rawData.startDate ? new Date(rawData.start_date || rawData.startDate) : null;
  const endDate = rawData.end_date || rawData.endDate ? new Date(rawData.end_date || rawData.endDate) : null;

  const created = await prisma.exams.create({
    data: {
      exam_name: examName,
      term: rawData.term || null,
      class_id: classId,
      exam_center: rawData.exam_center || rawData.examCenter || null,
      start_date: startDate,
      end_date: endDate,
      results_published: rawData.results_published ?? rawData.resultsPublished ?? false,
      hall_ticket_locked: rawData.hall_ticket_locked ?? rawData.hallTicketLocked ?? false,
      created_by: user.id,
    },
    include: {
      class: { select: { id: true, class_name: true, section: true } },
    },
  });

  return {
    ...created,
    examName: created.exam_name,
    classId: created.class_id,
    examCenter: created.exam_center,
    startDate: created.start_date,
    endDate: created.end_date,
    resultsPublished: created.results_published,
    hallTicketLocked: created.hall_ticket_locked,
    classes: created.class,
  };
};

export const updateExam = async (id: string, rawData: any, user: any) => {
  const examName = rawData.exam_name || rawData.examName;
  const classId = rawData.class_id || rawData.classId;

  const updated = await prisma.exams.update({
    where: { id },
    data: {
      exam_name: examName ? examName.trim() : undefined,
      term: rawData.term !== undefined ? rawData.term : undefined,
      class_id: classId ? classId.trim() : undefined,
      exam_center: rawData.exam_center !== undefined ? rawData.exam_center : rawData.examCenter,
      start_date: rawData.start_date || rawData.startDate ? new Date(rawData.start_date || rawData.startDate) : undefined,
      end_date: rawData.end_date || rawData.endDate ? new Date(rawData.end_date || rawData.endDate) : undefined,
      results_published: rawData.results_published ?? rawData.resultsPublished,
      hall_ticket_locked: rawData.hall_ticket_locked ?? rawData.hallTicketLocked,
    },
    include: {
      class: { select: { id: true, class_name: true, section: true } },
    },
  });

  return {
    ...updated,
    examName: updated.exam_name,
    classId: updated.class_id,
    examCenter: updated.exam_center,
    startDate: updated.start_date,
    endDate: updated.end_date,
    resultsPublished: updated.results_published,
    hallTicketLocked: updated.hall_ticket_locked,
    classes: updated.class,
  };
};

export const deleteExam = async (id: string) => {
  await prisma.exams.delete({
    where: { id },
  });
  return { success: true };
};

export const setResultsPublished = async (examId: string, published: boolean) => {
  const updated = await prisma.exams.update({
    where: { id: examId },
    data: { results_published: published },
  });
  return updated;
};

export const setHallTicketsLocked = async (examId: string, locked: boolean) => {
  const updated = await prisma.exams.update({
    where: { id: examId },
    data: { hall_ticket_locked: locked },
  });
  return updated;
};

export const getExamSubjects = async (examId: string) => {
  const subjects = await prisma.exam_subjects.findMany({
    where: { exam_id: examId },
    include: {
      subject: { select: { subject_name: true, subject_code: true } },
    },
  });

  return subjects.map((es) => ({
    ...es,
    examId: es.exam_id,
    subjectId: es.subject_id,
    examDate: es.exam_date,
    maximumMarks: Number(es.maximum_marks),
    passMarks: Number(es.pass_marks),
    subjectName: es.subject?.subject_name,
    subjectCode: es.subject?.subject_code,
  }));
};

export const saveExamSubjects = async (examId: string, rawSubjects: any[]) => {
  await prisma.exam_subjects.deleteMany({
    where: { exam_id: examId },
  });

  if (Array.isArray(rawSubjects) && rawSubjects.length > 0) {
    await prisma.exam_subjects.createMany({
      data: rawSubjects.map((s) => ({
        exam_id: examId,
        subject_id: s.subject_id || s.subjectId,
        exam_date: s.exam_date || s.examDate ? new Date(s.exam_date || s.examDate) : null,
        maximum_marks: s.maximum_marks ?? s.maximumMarks ?? 100,
        pass_marks: s.pass_marks ?? s.passMarks ?? 35,
      })),
    });
  }

  return await getExamSubjects(examId);
};
