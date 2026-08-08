import { prisma } from '../config/db';
import { isValidSubjectForClass } from '../config/subjects';

const formatNote = (note: any) => {
  if (!note) return note;
  return {
    ...note,
    file_size: note.file_size !== null && note.file_size !== undefined ? Number(note.file_size) : null,
  };
};

export const createNote = async (data: any, user: any) => {
  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== data.class_id) {
      throw new Error('Not authorized to upload notes for this class');
    }
  }

  // Subject validation for class
  if (data.class_id && data.subject_id) {
    const targetClass = await prisma.classes.findUnique({ where: { id: data.class_id } });
    if (targetClass) {
      const sub = await prisma.subjects.findUnique({ where: { id: data.subject_id } });
      if (sub && !isValidSubjectForClass(targetClass.class_name, sub.subject_name)) {
        throw new Error(`Invalid subject '${sub.subject_name}' for ${targetClass.class_name}`);
      }
    }
  }

  const newNote = await prisma.notes.create({
    data: {
      title: data.title,
      description: data.description || null,
      class_id: data.class_id,
      subject_id: data.subject_id || null,
      teacher_id: user.role === 'class_teacher' ? user.id : null,
      file_path: data.file_path,
      file_name: data.file_name || null,
      file_size: data.file_size ? BigInt(data.file_size) : null,
      is_published: data.is_published ?? true,
    },
    include: {
      class: { select: { class_name: true } },
      subject: { select: { subject_name: true } },
      teacher: { select: { full_name: true } }
    }
  });

  return formatNote(newNote);
};

export const getAllNotes = async (user: any, classIdQuery?: string) => {
  let filter: any = {};

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (teacherClass) {
      filter = { class_id: teacherClass.id };
    } else {
      return [];
    }
  } else if (user.role === 'student') {
    const studentProfile = await prisma.students.findUnique({
      where: { profile_id: user.id }
    });
    if (studentProfile) {
      filter = { class_id: studentProfile.class_id, is_published: true };
    } else {
      return [];
    }
  } else if (classIdQuery && classIdQuery.trim() !== '') {
    filter = { class_id: classIdQuery.trim() };
  }

  const list = await prisma.notes.findMany({
    where: filter,
    include: {
      class: { select: { class_name: true } },
      subject: { select: { subject_name: true } },
      teacher: { select: { full_name: true } }
    },
    orderBy: { uploaded_at: 'desc' },
  });

  return list.map(formatNote);
};

export const getNoteById = async (id: string, user: any) => {
  const note = await prisma.notes.findUnique({
    where: { id },
    include: {
      class: { select: { class_name: true } },
      subject: { select: { subject_name: true } },
      teacher: { select: { full_name: true } }
    },
  });

  if (!note) throw new Error('Note not found');

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== note.class_id) {
      throw new Error('Not authorized to access this note');
    }
  } else if (user.role === 'student') {
    const studentProfile = await prisma.students.findUnique({
      where: { profile_id: user.id }
    });
    if (!studentProfile || studentProfile.class_id !== note.class_id || !note.is_published) {
      throw new Error('Not authorized to access this note');
    }
  }

  return formatNote(note);
};

export const updateNote = async (id: string, data: any, user: any) => {
  const note = await prisma.notes.findUnique({ where: { id } });
  if (!note) throw new Error('Note not found');

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== note.class_id) {
      throw new Error('Not authorized to update this note');
    }
  }

  const targetClassId = data.class_id || note.class_id;
  if (targetClassId) {
    const targetClass = await prisma.classes.findUnique({ where: { id: targetClassId } });
    if (targetClass) {
      let subjectName = data.subject_name || data.subjectName;
      const subId = data.subject_id || note.subject_id;
      if (subId) {
        const sub = await prisma.subjects.findUnique({ where: { id: subId } });
        if (sub) subjectName = sub.subject_name;
      }
      if (subjectName && !isValidSubjectForClass(targetClass.class_name, subjectName)) {
        throw new Error(`Invalid subject '${subjectName}' for ${targetClass.class_name}`);
      }
    }
  }

  const updatedNote = await prisma.notes.update({
    where: { id },
    data: {
      title: data.title,
      description: data.description,
      subject_id: data.subject_id,
      is_published: data.is_published,
    },
    include: {
      class: { select: { class_name: true } },
      subject: { select: { subject_name: true } },
      teacher: { select: { full_name: true } }
    }
  });

  return formatNote(updatedNote);
};

export const deleteNote = async (id: string, user: any) => {
  const note = await prisma.notes.findUnique({ where: { id } });
  if (!note) throw new Error('Note not found');

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== note.class_id) {
      throw new Error('Not authorized to delete this note');
    }
  }

  await prisma.notes.delete({ where: { id } });
  return { success: true };
};
