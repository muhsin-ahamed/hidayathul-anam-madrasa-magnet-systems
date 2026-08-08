import { prisma } from '../config/db';
import { hashPassword } from '../utils/hash';

export const formatTeacherResponse = async (t: any) => {
  if (!t) return t;
  const clsList = t.profile?.classes || [];
  const cls = clsList.length > 0 ? clsList[0] : null;
  const className = cls ? (cls.section ? `${cls.class_name} - ${cls.section}` : cls.class_name) : null;

  let avatarUrl = t.avatarUrl || t.avatar_url || t.profile?.avatar_url || t.photo_url || null;
  const profId = t.profile_id || t.profile?.id || t.id;
  if (!avatarUrl && profId) {
    const setting = await prisma.app_settings.findUnique({
      where: { setting_key: `teacher_avatar_${profId}` }
    }).catch(() => null);
    if (setting?.setting_value && typeof setting.setting_value === 'object') {
      avatarUrl = (setting.setting_value as any).avatarUrl || null;
    }
  }

  return {
    ...t,
    fullName: t.profile?.full_name || t.full_name || '',
    full_name: t.profile?.full_name || t.full_name || '',
    username: t.profile?.username || t.username || '',
    email: t.profile?.email || null,
    phone: t.profile?.phone || null,
    avatarUrl,
    avatar_url: avatarUrl,
    role: 'class_teacher',
    assignedClass: cls ? {
      id: cls.id,
      className: className,
      class_name: cls.class_name,
      section: cls.section,
    } : null,
    className: className,
    assignedClassId: cls?.id || null,
    assignedClassName: className,
  };
};

export const getOrEnsureTeacherProfile = async (profileIdOrId: string) => {
  let teacher = await prisma.teachers.findFirst({
    where: {
      OR: [
        { profile_id: profileIdOrId },
        { id: profileIdOrId }
      ]
    },
    include: {
      profile: {
        include: {
          classes: true
        }
      }
    }
  });

  if (!teacher) {
    const profile = await prisma.profiles.findUnique({
      where: { id: profileIdOrId },
      include: { classes: true }
    });

    if (profile) {
      teacher = await prisma.teachers.create({
        data: {
          profile_id: profile.id,
          is_active: true
        },
        include: {
          profile: {
            include: {
              classes: true
            }
          }
        }
      });
    }
  }

  if (!teacher) {
    throw new Error('Teacher profile not found');
  }

  // Enforce Requirement 4: Teacher MUST be linked to a class.
  // If classes.class_teacher_id is NULL, automatically fix the relationship.
  let clsList = teacher.profile?.classes || [];
  if (clsList.length === 0) {
    console.log(`[TEACHER AUTO-ASSIGN] Teacher profile ${teacher.profile_id} has no assigned class. Auto-fixing...`);
    let unassignedClass = await prisma.classes.findFirst({
      where: { class_teacher_id: null }
    });

    if (!unassignedClass) {
      unassignedClass = await prisma.classes.findFirst();
    }

    if (unassignedClass) {
      await prisma.classes.update({
        where: { id: unassignedClass.id },
        data: { class_teacher_id: teacher.profile_id }
      });

      const reFetched = await prisma.teachers.findUnique({
        where: { id: teacher.id },
        include: {
          profile: {
            include: {
              classes: true
            }
          }
        }
      });
      if (reFetched) {
        teacher = reFetched;
      }
    }
  }

  return formatTeacherResponse(teacher);
};

export const getTeacherDashboard = async (user: any) => {
  const teacherObj = await getOrEnsureTeacherProfile(user.id || user.userId);
  const classId = teacherObj.assignedClassId || teacherObj.assignedClass?.id;

  let studentCount = 0;
  let recentResults: any[] = [];
  let recentNotes: any[] = [];

  if (classId) {
    studentCount = await prisma.students.count({
      where: { class_id: classId }
    });

    const rawResults = await prisma.results.findMany({
      where: { student: { class_id: classId } },
      take: 10,
      orderBy: { created_at: 'desc' },
      include: {
        student: { select: { full_name: true, roll_number: true } },
        subject: { select: { subject_name: true } },
        exam: { select: { exam_name: true } }
      }
    });

    recentResults = rawResults.map(r => ({
      ...r,
      students: r.student ? { full_name: r.student.full_name, roll_number: r.student.roll_number } : null,
      subjects: r.subject ? { subject_name: r.subject.subject_name } : null,
      exams: r.exam ? { exam_name: r.exam.exam_name } : null,
    }));

    const rawNotes = await prisma.notes.findMany({
      where: { class_id: classId },
      take: 10,
      orderBy: { uploaded_at: 'desc' },
      include: {
        subject: { select: { subject_name: true } }
      }
    });

    recentNotes = rawNotes.map(n => ({
      ...n,
      subjects: n.subject ? { subject_name: n.subject.subject_name } : null,
    }));
  }

  const assignedClass = teacherObj.assignedClass || {
    id: classId || '',
    className: teacherObj.assignedClassName || 'Class 1',
    class_name: teacherObj.assignedClassName || 'Class 1',
    section: null
  };

  return {
    teacher: teacherObj,
    assignedClass,
    studentCount,
    recentResults,
    recentNotes,
  };
};

export const getTeacherStudents = async (user: any) => {
  const teacherObj = await getOrEnsureTeacherProfile(user.id || user.userId);
  const classId = teacherObj.assignedClassId || teacherObj.assignedClass?.id;

  if (!classId) return [];

  const students = await prisma.students.findMany({
    where: { class_id: classId },
    include: {
      profile: { select: { email: true, phone: true, is_active: true } },
      class: true
    },
    orderBy: { roll_number: 'asc' }
  });

  return students.map(s => ({
    ...s,
    fullName: s.full_name,
    admissionNumber: s.admission_number,
    rollNumber: s.roll_number,
    className: teacherObj.assignedClassName,
  }));
};

export const getTeacherResults = async (user: any) => {
  const teacherObj = await getOrEnsureTeacherProfile(user.id || user.userId);
  const classId = teacherObj.assignedClassId || teacherObj.assignedClass?.id;

  if (!classId) return [];

  const results = await prisma.results.findMany({
    where: { student: { class_id: classId } },
    include: {
      student: { select: { full_name: true, roll_number: true, admission_number: true } },
      subject: { select: { subject_name: true, subject_code: true } },
      exam: { select: { exam_name: true } }
    },
    orderBy: { created_at: 'desc' }
  });

  return results.map(r => ({
    ...r,
    students: r.student ? { full_name: r.student.full_name, roll_number: r.student.roll_number } : null,
    subjects: r.subject ? { subject_name: r.subject.subject_name, subject_code: r.subject.subject_code } : null,
    exams: r.exam ? { exam_name: r.exam.exam_name } : null,
  }));
};

export const getTeacherNotes = async (user: any) => {
  const teacherObj = await getOrEnsureTeacherProfile(user.id || user.userId);
  const classId = teacherObj.assignedClassId || teacherObj.assignedClass?.id;

  if (!classId) return [];

  const notes = await prisma.notes.findMany({
    where: { class_id: classId },
    include: {
      teacher: { select: { full_name: true } },
      subject: { select: { subject_name: true } },
      class: { select: { class_name: true, section: true } }
    },
    orderBy: { uploaded_at: 'desc' }
  });

  return notes.map(n => ({
    ...n,
    profiles: n.teacher ? { full_name: n.teacher.full_name } : null,
    subjects: n.subject ? { subject_name: n.subject.subject_name } : null,
    classes: n.class ? { class_name: n.class.class_name, section: n.class.section } : null,
  }));
};

export const getTeacherHallTickets = async (user: any) => {
  const teacherObj = await getOrEnsureTeacherProfile(user.id || user.userId);
  const classId = teacherObj.assignedClassId || teacherObj.assignedClass?.id;

  if (!classId) return [];

  const tickets = await prisma.hall_tickets.findMany({
    where: { student: { class_id: classId } },
    include: {
      exam: { select: { exam_name: true, exam_center: true, reporting_time: true } },
      student: { select: { full_name: true, roll_number: true, admission_number: true } }
    },
    orderBy: { generated_at: 'desc' }
  });

  return tickets.map(t => ({
    ...t,
    exams: t.exam ? { exam_name: t.exam.exam_name, exam_center: t.exam.exam_center, reporting_time: t.exam.reporting_time } : null,
    students: t.student ? { full_name: t.student.full_name, roll_number: t.student.roll_number, admission_number: t.student.admission_number } : null,
  }));
};

export const createTeacher = async (rawData: any) => {
  console.log('[CREATE TEACHER SERVICE] Raw request body:', JSON.stringify(rawData, null, 2));

  const fullName = (rawData.fullName || rawData.full_name || '').trim();
  const classId = (rawData.classId || rawData.class_id || '').trim();

  let email: string | null = null;
  if (rawData.email && typeof rawData.email === 'string' && rawData.email.trim() !== '') {
    email = rawData.email.trim();
  }

  let phone: string | null = null;
  if (rawData.phone && typeof rawData.phone === 'string' && rawData.phone.trim() !== '') {
    phone = rawData.phone.trim();
  }

  let username = (rawData.username || '').trim();
  if (!username) {
    if (email && email.includes('@')) {
      username = email.split('@')[0].toLowerCase().trim();
    } else {
      username = fullName.toLowerCase().replace(/[^a-z0-9_]/g, '_').trim();
    }
  }

  const employeeNumber = rawData.employeeNumber || rawData.employee_number || null;
  const qualification = rawData.qualification || null;

  let joinedDate: Date | null = null;
  const rawJoined = rawData.joinedDate || rawData.joined_date;
  if (rawJoined && typeof rawJoined === 'string' && rawJoined.trim() !== '') {
    const d = new Date(rawJoined.trim());
    if (!isNaN(d.getTime())) joinedDate = d;
  } else if (rawJoined instanceof Date && !isNaN(rawJoined.getTime())) {
    joinedDate = rawJoined;
  }

  if (!fullName) {
    throw new Error('Full name is required');
  }

  if (!classId) {
    throw new Error('Class is required.');
  }

  const targetClass = await prisma.classes.findUnique({
    where: { id: classId },
  });
  if (!targetClass) {
    throw new Error(`Class with ID "${classId}" not found`);
  }

  if (targetClass.class_teacher_id) {
    throw new Error('This class already has a class teacher.');
  }

  const classMatch = targetClass.class_name.match(/\d+/);
  const classNumber = classMatch ? classMatch[0] : '1';
  const generatedPassword = rawData.password || `Ham@cls${classNumber}`;

  const existingProfile = await prisma.profiles.findUnique({
    where: { username },
  });
  if (existingProfile) {
    throw new Error(`Username "${username}" already exists`);
  }

  const existingUser = await prisma.users.findUnique({
    where: { username },
  });
  if (existingUser) {
    throw new Error(`User with username "${username}" already exists`);
  }

  const passwordHash = await hashPassword(generatedPassword);

  const newTeacher = await prisma.$transaction(async (tx) => {
    const profile = await tx.profiles.create({
      data: {
        username,
        full_name: fullName,
        email,
        phone,
        role: 'class_teacher',
        is_active: true,
      },
    });

    await tx.users.create({
      data: {
        username,
        password_hash: passwordHash,
        role: 'class_teacher',
        profile_id: profile.id,
      },
    });

    const teacher = await tx.teachers.create({
      data: {
        profile_id: profile.id,
        employee_number: employeeNumber,
        qualification: qualification,
        joined_date: joinedDate,
      },
      include: {
        profile: {
          include: {
            classes: true,
          },
        },
      },
    });

    await tx.classes.update({
      where: { id: classId },
      data: {
        class_teacher_id: profile.id,
      },
    });

    return teacher;
  });

  const refreshedTeacher = await prisma.teachers.findUnique({
    where: { id: newTeacher.id },
    include: {
      profile: {
        include: {
          classes: true,
        },
      },
    },
  });

  return formatTeacherResponse(refreshedTeacher || newTeacher);
};

export const getAllTeachers = async () => {
  const teachers = await prisma.teachers.findMany({
    include: {
      profile: {
        select: {
          id: true,
          username: true,
          full_name: true,
          email: true,
          phone: true,
          is_active: true,
          classes: {
            select: {
              id: true,
              class_name: true,
              section: true,
            },
          },
        },
      },
    },
    orderBy: {
      created_at: 'desc',
    },
  });

  return await Promise.all(teachers.map((t: any) => formatTeacherResponse(t)));
};

export const getTeacherById = async (id: string) => {
  const teacher = await prisma.teachers.findUnique({
    where: { id },
    include: {
      profile: {
        select: {
          id: true,
          username: true,
          full_name: true,
          email: true,
          phone: true,
          is_active: true,
          classes: {
            select: {
              id: true,
              class_name: true,
              section: true,
            },
          },
        },
      },
    },
  });

  if (!teacher) {
    throw new Error('Teacher not found');
  }

  return await formatTeacherResponse(teacher);
};

export const updateTeacher = async (id: string, rawData: any) => {
  const teacher = await prisma.teachers.findUnique({
    where: { id },
    include: { profile: true },
  });

  if (!teacher) {
    throw new Error('Teacher not found');
  }

  const fullName = rawData.fullName || rawData.full_name || teacher.profile.full_name;
  let email = rawData.email;
  if (email !== undefined) {
    email = email && typeof email === 'string' && email.trim() !== '' ? email.trim() : null;
  }
  let phone = rawData.phone;
  if (phone !== undefined) {
    phone = phone && typeof phone === 'string' && phone.trim() !== '' ? phone.trim() : null;
  }

  const newClassId = (rawData.classId || rawData.class_id || '').trim();

  const updatedTeacher = await prisma.$transaction(async (tx) => {
    await tx.profiles.update({
      where: { id: teacher.profile_id },
      data: {
        full_name: fullName,
        email: email !== undefined ? email : undefined,
        phone: phone !== undefined ? phone : undefined,
        is_active: rawData.is_active ?? rawData.isActive,
      },
    });

    if (newClassId) {
      await tx.classes.updateMany({
        where: { class_teacher_id: teacher.profile_id },
        data: { class_teacher_id: null },
      });
      await tx.classes.update({
        where: { id: newClassId },
        data: { class_teacher_id: teacher.profile_id },
      });
    }

    const updated = await tx.teachers.update({
      where: { id },
      data: {
        employee_number: rawData.employeeNumber ?? rawData.employee_number,
        qualification: rawData.qualification,
      },
      include: {
        profile: {
          include: {
            classes: true,
          },
        },
      },
    });

    return updated;
  });

  const refreshedTeacher = await prisma.teachers.findUnique({
    where: { id: updatedTeacher.id },
    include: {
      profile: {
        include: {
          classes: true,
        },
      },
    },
  });

  return await formatTeacherResponse(refreshedTeacher || updatedTeacher);
};

export const deleteTeacher = async (id: string) => {
  const teacher = await prisma.teachers.findUnique({
    where: { id },
  });

  if (!teacher) {
    throw new Error('Teacher not found');
  }

  await prisma.profiles.delete({
    where: { id: teacher.profile_id },
  });

  return { success: true };
};

export const updateTeacherAvatar = async (profileIdOrId: string, avatarUrl: string) => {
  const teacher = await prisma.teachers.findFirst({
    where: {
      OR: [
        { profile_id: profileIdOrId },
        { id: profileIdOrId }
      ]
    }
  });

  const pId = teacher?.profile_id || profileIdOrId;

  const settingKey = `teacher_avatar_${pId}`;
  await prisma.app_settings.upsert({
    where: { setting_key: settingKey },
    update: { setting_value: { avatarUrl }, updated_at: new Date() },
    create: { setting_key: settingKey, setting_value: { avatarUrl }, updated_by: pId }
  });

  return await getOrEnsureTeacherProfile(pId);
};

export const updateTeacherProfileDetails = async (
  profileIdOrId: string,
  data: { fullName?: string; email?: string; phone?: string }
) => {
  const teacher = await prisma.teachers.findFirst({
    where: {
      OR: [
        { profile_id: profileIdOrId },
        { id: profileIdOrId }
      ]
    }
  });

  const pId = teacher?.profile_id || profileIdOrId;

  await prisma.profiles.update({
    where: { id: pId },
    data: {
      ...(data.fullName ? { full_name: data.fullName } : {}),
      ...(data.email !== undefined ? { email: data.email } : {}),
      ...(data.phone !== undefined ? { phone: data.phone } : {}),
      updated_at: new Date(),
    }
  });

  return await getOrEnsureTeacherProfile(pId);
};

export const changeTeacherPassword = async (
  profileIdOrId: string,
  currentPass: string,
  newPass: string
) => {
  if (!currentPass || !currentPass.trim()) {
    throw new Error('Current password is required.');
  }

  if (!newPass || !newPass.trim()) {
    throw new Error('New password is required.');
  }

  if (newPass.length < 8) {
    throw new Error('New password must be at least 8 characters long.');
  }
  if (!/[A-Z]/.test(newPass)) {
    throw new Error('New password must contain at least one uppercase letter.');
  }
  if (!/[a-z]/.test(newPass)) {
    throw new Error('New password must contain at least one lowercase letter.');
  }
  if (!/[0-9]/.test(newPass)) {
    throw new Error('New password must contain at least one number.');
  }
  if (!/[!@#$%^&*(),.?":{}|<>]/.test(newPass)) {
    throw new Error('New password must contain at least one special character.');
  }

  const teacher = await prisma.teachers.findFirst({
    where: {
      OR: [
        { profile_id: profileIdOrId },
        { id: profileIdOrId }
      ]
    },
    include: {
      profile: {
        include: {
          users: true,
          classes: true
        }
      }
    }
  });

  const pId = teacher?.profile_id || profileIdOrId;
  const profile = teacher?.profile || await prisma.profiles.findUnique({
    where: { id: pId },
    include: { users: true, classes: true }
  });

  if (!profile) {
    throw new Error('Teacher profile not found.');
  }

  let userRecord = profile.users || await prisma.users.findUnique({
    where: { profile_id: pId }
  });

  const { comparePassword } = await import('../utils/hash');

  let isMatch = false;
  if (userRecord && userRecord.password_hash) {
    isMatch = await comparePassword(currentPass, userRecord.password_hash);
  } else {
    const cls = profile.classes?.[0] || await prisma.classes.findFirst({ where: { class_teacher_id: pId } });
    if (cls) {
      const matchNum = cls.class_name.match(/\d+/);
      const clsNum = matchNum ? matchNum[0] : '1';
      if (currentPass === `Ham@cls${clsNum}`) {
        isMatch = true;
      }
    }
  }

  if (!isMatch) {
    throw new Error('Current password is incorrect.');
  }

  const newHash = await hashPassword(newPass);
  const username = profile.username || `teacher_${pId.substring(0, 8)}`;

  await prisma.users.upsert({
    where: { profile_id: pId },
    update: {
      password_hash: newHash,
      updated_at: new Date()
    },
    create: {
      profile_id: pId,
      username: username,
      password_hash: newHash,
      role: profile.role || 'class_teacher',
    }
  });

  return {
    success: true,
    message: 'Password updated successfully.'
  };
};
