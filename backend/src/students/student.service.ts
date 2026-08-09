import { prisma } from '../config/db';
import { hashPassword } from '../utils/hash';

export const createStudent = async (rawData: any, user: any) => {
  const admissionNumber = (rawData.admission_number || rawData.admissionNumber || '').trim();
  const rollNumber = (rawData.roll_number || rawData.rollNumber || '').trim();
  const fullName = (rawData.full_name || rawData.fullName || '').trim();
  const classId = (rawData.class_id || rawData.classId || '').trim();
  const rawDob = rawData.date_of_birth ?? rawData.dateOfBirth ?? null;
  const gender = rawData.gender ? String(rawData.gender).trim() : null;
  const guardianName = rawData.guardian_name ?? rawData.guardianName ?? null;
  const guardianPhone = rawData.guardian_phone ?? rawData.guardianPhone ?? null;
  const address = rawData.address ? String(rawData.address).trim() : null;
  const email = rawData.email ? String(rawData.email).trim() : null;
  const rawPassword = rawData.password ? String(rawData.password).trim() : admissionNumber;

  if (!classId) {
    throw new Error('Student must be assigned to a class.');
  }

  const targetClass = await prisma.classes.findUnique({
    where: { id: classId },
  });
  if (!targetClass) {
    throw new Error(`Class with ID "${classId}" not found`);
  }

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== classId) {
      throw new Error('Teachers can only create students in their assigned class.');
    }
  }

  const existingAdm = await prisma.students.findUnique({
    where: { admission_number: admissionNumber },
  });
  if (existingAdm) {
    throw new Error('Admission number already exists');
  }

  const existingRoll = await prisma.students.findFirst({
    where: {
      class_id: classId,
      roll_number: rollNumber,
    },
  });
  if (existingRoll) {
    throw new Error('Roll number already exists');
  }

  const existingProfile = await prisma.profiles.findUnique({
    where: { username: admissionNumber },
  });
  if (existingProfile) {
    throw new Error(`Username/Admission number "${admissionNumber}" already exists in user profiles`);
  }

  let dob: Date | null = null;
  if (rawDob && typeof rawDob === 'string' && rawDob.trim() !== '') {
    const parsed = new Date(rawDob.trim());
    if (!isNaN(parsed.getTime())) {
      dob = parsed;
    }
  } else if (rawDob instanceof Date && !isNaN(rawDob.getTime())) {
    dob = rawDob;
  }

  const passwordHash = await hashPassword(rawPassword);

  const newStudent = await prisma.$transaction(async (tx) => {
    const profile = await tx.profiles.create({
      data: {
        username: admissionNumber,
        full_name: fullName,
        email: email || null,
        phone: guardianPhone || null,
        role: 'student',
        is_active: true,
      },
    });

    await tx.users.create({
      data: {
        username: admissionNumber,
        password_hash: passwordHash,
        role: 'student',
        profile_id: profile.id,
      },
    });

    const student = await tx.students.create({
      data: {
        profile_id: profile.id,
        admission_number: admissionNumber,
        roll_number: rollNumber,
        full_name: fullName,
        class_id: classId,
        date_of_birth: dob,
        gender: gender || null,
        guardian_name: guardianName || null,
        guardian_phone: guardianPhone || null,
        address: address || null,
        is_active: true,
      },
      include: { class: true, profile: true },
    });

    return student;
  });

  return newStudent;
};

export const getAllStudents = async (user: any) => {
  let classIdFilter = {};

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass) return [];
    classIdFilter = { class_id: teacherClass.id };
  }

  return await prisma.students.findMany({
    where: { ...classIdFilter },
    include: {
      profile: { select: { is_active: true, email: true, phone: true } },
      class: true,
    },
    orderBy: { created_at: 'desc' },
  });
};

export const getStudentById = async (id: string, user: any) => {
  const student = await prisma.students.findUnique({
    where: { id },
    include: { class: true, profile: true },
  });

  if (!student) throw new Error('Student not found');

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== student.class_id) {
      throw new Error('Not authorized to access this student');
    }
  }

  return student;
};

export const getStudentProfile = async (profileIdOrId: string, user: any) => {
  const student = await prisma.students.findFirst({
    where: {
      OR: [
        { profile_id: profileIdOrId },
        { profile_id: user?.id },
        { profile_id: user?.userId },
        { id: profileIdOrId },
        { id: user?.id }
      ]
    },
    include: {
      profile: true,
      class: true,
    }
  });

  if (!student) {
    throw new Error('Student profile not found');
  }

  if (user.role === 'student') {
    if (student.profile_id !== user.id && student.profile_id !== user.userId && student.id !== user.id) {
      throw new Error('Not authorized to access this profile');
    }
  }

  const cls = student.class;
  const className = cls ? (cls.section ? `${cls.class_name} - ${cls.section}` : cls.class_name) : 'Class';

  return {
    id: student.id,
    profileId: student.profile_id,
    profile_id: student.profile_id,
    fullName: student.full_name || student.profile?.full_name || '',
    full_name: student.full_name || student.profile?.full_name || '',
    admissionNumber: student.admission_number,
    admission_number: student.admission_number,
    className: className,
    class_name: className,
    rollNumber: student.roll_number,
    roll_number: student.roll_number,
    guardianName: student.guardian_name || '',
    guardian_name: student.guardian_name || '',
    guardianPhone: student.guardian_phone || '',
    guardian_phone: student.guardian_phone || '',
    address: student.address || '',
    dateOfBirth: student.date_of_birth,
    gender: student.gender,
    photoPath: student.photo_path,
    is_active: student.is_active,
    class_id: student.class_id,
  };
};

export const getStudentDashboard = async (user: any) => {
  const student = await prisma.students.findFirst({
    where: {
      OR: [
        { profile_id: user.id },
        { profile_id: user.userId },
        { id: user.id }
      ]
    },
    include: {
      profile: true,
      class: true,
    }
  });

  if (!student) {
    throw new Error('Student not found');
  }

  const cls = student.class;
  const className = cls ? (cls.section ? `${cls.class_name} - ${cls.section}` : cls.class_name) : 'Class';

  const results = await prisma.results.findMany({
    where: {
      student_id: student.id,
      is_published: true,
    },
    include: {
      subject: true,
      exam: true,
    }
  });

  let totalObtained = 0;
  let totalMax = 0;
  for (const r of results) {
    if (r.marks_obtained !== null && r.marks_obtained !== undefined) {
      totalObtained += Number(r.marks_obtained);
      totalMax += Number(r.maximum_marks || 100);
    }
  }
  const averagePercentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0;

  const notesCount = await prisma.notes.count({
    where: {
      class_id: student.class_id,
      is_published: true,
    }
  });

  const hallTicketsCount = await prisma.hall_tickets.count({
    where: {
      student_id: student.id,
    }
  });

  const upcomingExams = await prisma.exams.findMany({
    where: {
      class_id: student.class_id,
    },
    orderBy: { start_date: 'asc' },
  });

  const studentObj = {
    id: student.id,
    fullName: student.full_name || student.profile?.full_name || '',
    full_name: student.full_name || student.profile?.full_name || '',
    admissionNumber: student.admission_number,
    admission_number: student.admission_number,
    rollNumber: student.roll_number,
    roll_number: student.roll_number,
    className: className,
    class_name: className,
    class_id: student.class_id,
  };

  const summaryObj = {
    results: results.length,
    notes: notesCount,
    hallTickets: hallTicketsCount,
  };

  return {
    student: studentObj,
    summary: summaryObj,
    averagePercentage,
    upcomingExams,
  };
};

export const getStudentNotes = async (user: any, queryClassId?: string) => {
  let targetClassId = queryClassId;

  if (!targetClassId) {
    const student = await prisma.students.findFirst({
      where: {
        OR: [
          { profile_id: user.id },
          { profile_id: user.userId },
          { id: user.id }
        ]
      }
    });
    if (student) {
      targetClassId = student.class_id;
    }
  }

  if (!targetClassId) {
    return [];
  }

  const notes = await prisma.notes.findMany({
    where: {
      class_id: targetClassId,
      is_published: true,
    },
    include: {
      teacher: { select: { full_name: true } },
      subject: { select: { subject_name: true } },
      class: { select: { class_name: true, section: true } },
    },
    orderBy: { uploaded_at: 'desc' },
  });

  return notes.map(n => ({
    ...n,
    profiles: n.teacher ? { full_name: n.teacher.full_name } : null,
    subjects: n.subject ? { subject_name: n.subject.subject_name } : null,
    classes: n.class ? { class_name: n.class.class_name, section: n.class.section } : null,
  }));
};

export const getStudentResults = async (user: any, queryStudentId?: string) => {
  let targetStudentId = queryStudentId;

  if (!targetStudentId || user.role === 'student') {
    const student = await prisma.students.findFirst({
      where: {
        OR: [
          { profile_id: user.id },
          { profile_id: user.userId },
          { id: user.id }
        ]
      }
    });
    if (student) {
      targetStudentId = student.id;
    }
  }

  if (!targetStudentId) {
    return [];
  }

  const results = await prisma.results.findMany({
    where: {
      student_id: targetStudentId,
      is_published: true,
    },
    include: {
      student: { select: { full_name: true, roll_number: true } },
      subject: { select: { subject_name: true, subject_code: true } },
      exam: { select: { exam_name: true } }
    },
    orderBy: { created_at: 'desc' },
  });

  return results.map(r => ({
    ...r,
    students: r.student ? { full_name: r.student.full_name, roll_number: r.student.roll_number } : null,
    subjects: r.subject ? { subject_name: r.subject.subject_name, subject_code: r.subject.subject_code } : null,
    exams: r.exam ? { exam_name: r.exam.exam_name } : null,
  }));
};

export const getStudentHallTicket = async (user: any, queryStudentId?: string, queryExamId?: string) => {
  let targetStudentId = queryStudentId;

  if (!targetStudentId || user.role === 'student') {
    const student = await prisma.students.findFirst({
      where: {
        OR: [
          { profile_id: user.id },
          { profile_id: user.userId },
          { id: user.id }
        ]
      }
    });
    if (student) {
      targetStudentId = student.id;
    }
  }

  if (!targetStudentId) {
    return [];
  }

  const whereClause: any = { student_id: targetStudentId };
  if (queryExamId) {
    whereClause.exam_id = queryExamId;
  }

  const tickets = await prisma.hall_tickets.findMany({
    where: whereClause,
    include: {
      exam: { select: { exam_name: true, exam_center: true, reporting_time: true } },
      student: {
        select: {
          full_name: true,
          roll_number: true,
          admission_number: true,
          class: { select: { class_name: true, section: true } }
        }
      }
    },
    orderBy: { generated_at: 'desc' },
  });

  return tickets.map(t => ({
    ...t,
    exams: t.exam ? { exam_name: t.exam.exam_name, exam_center: t.exam.exam_center, reporting_time: t.exam.reporting_time } : null,
    students: t.student ? {
      full_name: t.student.full_name,
      roll_number: t.student.roll_number,
      admission_number: t.student.admission_number,
      classes: t.student.class ? { class_name: t.student.class.class_name, section: t.student.class.section } : null,
    } : null,
  }));
};

export const updateStudent = async (id: string, rawData: any, user: any) => {
  const student = await prisma.students.findUnique({
    where: { id },
  });

  if (!student) throw new Error('Student not found');

  const classId = (rawData.class_id || rawData.classId || student.class_id).trim();

  if (!classId) {
    throw new Error('Student must be assigned to a class.');
  }

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== student.class_id) {
      throw new Error('Not authorized to update this student');
    }
    if (classId !== student.class_id) {
      throw new Error("Teachers cannot change a student's class");
    }
  }

  const fullName = rawData.full_name || rawData.fullName;
  const rollNumber = (rawData.roll_number || rawData.rollNumber || student.roll_number).trim();
  const admissionNumber = (rawData.admission_number || rawData.admissionNumber || student.admission_number).trim();

  if (admissionNumber !== student.admission_number) {
    const existingAdm = await prisma.students.findFirst({
      where: {
        admission_number: admissionNumber,
        id: { not: id },
      },
    });
    if (existingAdm) {
      throw new Error('Admission number already exists');
    }
  }

  const existingRoll = await prisma.students.findFirst({
    where: {
      class_id: classId,
      roll_number: rollNumber,
      id: { not: id },
    },
  });
  if (existingRoll) {
    throw new Error('Roll number already exists');
  }

  const rawDob = rawData.date_of_birth ?? rawData.dateOfBirth;

  let dob: Date | null | undefined = undefined;
  if (rawDob !== undefined) {
    if (rawDob && typeof rawDob === 'string' && rawDob.trim() !== '') {
      const parsed = new Date(rawDob.trim());
      dob = !isNaN(parsed.getTime()) ? parsed : null;
    } else if (rawDob instanceof Date && !isNaN(rawDob.getTime())) {
      dob = rawDob;
    } else {
      dob = null;
    }
  }

  const updatedStudent = await prisma.$transaction(async (tx) => {
    if (fullName !== undefined || rawData.is_active !== undefined || rawData.isActive !== undefined) {
      await tx.profiles.update({
        where: { id: student.profile_id! },
        data: {
          full_name: fullName !== undefined ? fullName : undefined,
          is_active: rawData.is_active ?? rawData.isActive,
        },
      });
    }

    const updated = await tx.students.update({
      where: { id },
      data: {
        roll_number: rollNumber,
        full_name: fullName !== undefined ? fullName : undefined,
        class_id: classId,
        date_of_birth: dob,
        gender: rawData.gender !== undefined ? rawData.gender : undefined,
        guardian_name: rawData.guardian_name ?? rawData.guardianName ?? undefined,
        guardian_phone: rawData.guardian_phone ?? rawData.guardianPhone ?? undefined,
        address: rawData.address !== undefined ? rawData.address : undefined,
      },
      include: { class: true, profile: true },
    });

    return updated;
  });

  return updatedStudent;
};

export const deleteStudent = async (id: string, user: any) => {
  const student = await prisma.students.findUnique({
    where: { id },
  });

  if (!student) throw new Error('Student not found');

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== student.class_id) {
      throw new Error('Not authorized to delete this student');
    }
  }

  try {
    if (student.profile_id) {
      await prisma.profiles.delete({
        where: { id: student.profile_id },
      });
    } else {
      await prisma.students.delete({
        where: { id },
      });
    }
  } catch (err) {
    if (student.profile_id) {
      await prisma.profiles.update({
        where: { id: student.profile_id },
        data: { is_active: false },
      });
    }
  }

  return { success: true };
};

export const deactivateStudent = async (id: string, user: any) => {
  const student = await prisma.students.findUnique({
    where: { id },
  });

  if (!student) throw new Error('Student not found');

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== student.class_id) {
      throw new Error('Not authorized to modify this student');
    }
  }

  if (student.profile_id) {
    await prisma.profiles.update({
      where: { id: student.profile_id },
      data: { is_active: false },
    });
  }

  return { success: true, message: 'Student deactivated successfully' };
};

export const activateStudent = async (id: string, user: any) => {
  const student = await prisma.students.findUnique({
    where: { id },
  });

  if (!student) throw new Error('Student not found');

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== student.class_id) {
      throw new Error('Not authorized to modify this student');
    }
  }

  if (student.profile_id) {
    await prisma.profiles.update({
      where: { id: student.profile_id },
      data: { is_active: true },
    });
  }

  return { success: true, message: 'Student activated successfully' };
};
