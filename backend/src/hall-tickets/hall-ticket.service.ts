import { prisma } from '../config/db';

export const createHallTicket = async (data: any, user: any) => {
  const student = await prisma.students.findUnique({ where: { id: data.student_id } });
  if (!student) throw new Error('Student not found');

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== student.class_id) {
      throw new Error('Not authorized to issue hall ticket for this student');
    }
  }

  const existing = await prisma.hall_tickets.findUnique({
    where: {
      exam_id_student_id: {
        exam_id: data.exam_id,
        student_id: data.student_id,
      }
    }
  });

  if (existing) throw new Error('Hall ticket already exists for this exam and student');

  return await prisma.hall_tickets.create({
    data: {
      exam_id: data.exam_id,
      student_id: data.student_id,
      hall_ticket_number: data.hall_ticket_number || `HT-${Date.now()}`,
      status: data.status || 'generated',
      file_path: data.file_path,
    },
    include: {
      student: { select: { admission_number: true, full_name: true } },
      exam: { select: { exam_name: true } }
    }
  });
};

export const getAllHallTickets = async (user: any, classIdQuery?: string) => {
  let filter: any = {};

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (teacherClass) {
      filter = { student: { class_id: teacherClass.id } };
    } else {
      return [];
    }
  } else if (user.role === 'student') {
    const studentProfile = await prisma.students.findUnique({
      where: { profile_id: user.id }
    });
    if (studentProfile) {
      filter = { student_id: studentProfile.id };
    } else {
      return [];
    }
  } else if (classIdQuery && classIdQuery.trim() !== '') {
    filter = { student: { class_id: classIdQuery.trim() } };
  }

  return await prisma.hall_tickets.findMany({
    where: filter,
    include: {
      student: { select: { admission_number: true, full_name: true, class: { select: { class_name: true } } } },
      exam: { select: { exam_name: true, start_date: true, end_date: true } }
    },
    orderBy: { generated_at: 'desc' },
  });
};

export const getHallTicketById = async (id: string, user: any) => {
  const hallTicket = await prisma.hall_tickets.findUnique({
    where: { id },
    include: {
      student: { select: { class_id: true, profile_id: true, full_name: true, admission_number: true } },
      exam: { select: { exam_name: true, start_date: true, end_date: true } }
    },
  });

  if (!hallTicket) throw new Error('Hall ticket not found');

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== hallTicket.student.class_id) {
      throw new Error('Not authorized to access this hall ticket');
    }
  } else if (user.role === 'student') {
    if (hallTicket.student.profile_id !== user.id) {
      throw new Error('Not authorized to access this hall ticket');
    }
  }

  return hallTicket;
};

export const updateHallTicket = async (id: string, data: any, user: any) => {
  const hallTicket = await prisma.hall_tickets.findUnique({
    where: { id },
    include: { student: true }
  });

  if (!hallTicket) throw new Error('Hall ticket not found');

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== hallTicket.student.class_id) {
      throw new Error('Not authorized to update this hall ticket');
    }
  }

  return await prisma.hall_tickets.update({
    where: { id },
    data: {
      status: data.status,
      locked_at: data.locked_at ? new Date(data.locked_at) : undefined,
      file_path: data.file_path,
    },
  });
};

export const deleteHallTicket = async (id: string, user: any) => {
  const hallTicket = await prisma.hall_tickets.findUnique({
    where: { id },
    include: { student: true }
  });

  if (!hallTicket) throw new Error('Hall ticket not found');

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== hallTicket.student.class_id) {
      throw new Error('Not authorized to delete this hall ticket');
    }
  }

  await prisma.hall_tickets.delete({ where: { id } });
  return { success: true };
};
