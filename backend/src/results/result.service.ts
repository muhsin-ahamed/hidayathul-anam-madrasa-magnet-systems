import { prisma } from '../config/db';
import * as XLSX from 'xlsx';
import { isValidSubjectForClass } from '../config/subjects';

export const createResult = async (data: any, user: any) => {
  const examId = data.exam_id || data.examId;
  const studentId = data.student_id || data.studentId;
  const subjectId = data.subject_id || data.subjectId;
  const marksObtained = data.marks_obtained ?? data.marksObtained;
  const maxMarks = data.maximum_marks ?? data.maximumMarks ?? 100;
  const isPublished = data.is_published ?? data.isPublished ?? false;

  if (!studentId) throw new Error('Student ID is required');
  if (!examId) throw new Error('Exam ID is required');
  if (!subjectId) throw new Error('Subject ID is required');

  if (marksObtained !== null && marksObtained !== undefined) {
    if (Number(marksObtained) < 0 || Number(marksObtained) > Number(maxMarks)) {
      throw new Error(`Marks obtained cannot exceed maximum marks (${maxMarks})`);
    }
  }

  const student = await prisma.students.findUnique({
    where: { id: studentId },
    include: { class: true }
  });
  if (!student) throw new Error('Student not found');

  const subject = await prisma.subjects.findUnique({ where: { id: subjectId } });
  if (!subject) throw new Error('Subject not found');

  if (student.class && !isValidSubjectForClass(student.class.class_name, subject.subject_name)) {
    throw new Error(`Subject '${subject.subject_name}' is not allowed for ${student.class.class_name}`);
  }

  // Authorization check for Class Teacher
  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== student.class_id) {
      throw new Error('Not authorized to upload result for this student');
    }
  }

  const existing = await prisma.results.findUnique({
    where: {
      exam_id_student_id_subject_id: {
        exam_id: examId,
        student_id: studentId,
        subject_id: subjectId,
      }
    }
  });

  if (existing) {
    // If result already exists, update it instead of throwing error
    return await prisma.results.update({
      where: { id: existing.id },
      data: {
        marks_obtained: marksObtained,
        maximum_marks: maxMarks,
        grade: data.grade || existing.grade,
        result_status: data.result_status || data.resultStatus || existing.result_status,
        remarks: data.remarks !== undefined ? data.remarks : existing.remarks,
        is_published: isPublished,
        published_at: isPublished ? new Date() : existing.published_at,
      },
      include: {
        student: { select: { admission_number: true, full_name: true, roll_number: true } },
        subject: { select: { subject_name: true } },
        exam: { select: { exam_name: true } }
      }
    });
  }

  return await prisma.results.create({
    data: {
      exam_id: examId,
      student_id: studentId,
      subject_id: subjectId,
      marks_obtained: marksObtained,
      maximum_marks: maxMarks,
      grade: data.grade,
      result_status: data.result_status || data.resultStatus,
      remarks: data.remarks,
      is_published: isPublished,
      created_by: user.id,
      published_at: isPublished ? new Date() : null,
    },
    include: {
      student: { select: { admission_number: true, full_name: true, roll_number: true } },
      subject: { select: { subject_name: true } },
      exam: { select: { exam_name: true } }
    }
  });
};

export const uploadResultsBulk = async (data: any, user: any) => {
  const examId = data.examId || data.exam_id;
  const resultsList = data.results || [];
  const createdOrUpdated = [];

  for (const item of resultsList) {
    const res = await createResult({ ...item, exam_id: examId }, user);
    createdOrUpdated.push(res);
  }

  return createdOrUpdated;
};

export const importResults = async (fileBuffer: Buffer | undefined, body: any, user: any) => {
  let rows: any[] = [];
  if (fileBuffer) {
    const workbook = XLSX.read(fileBuffer, { type: 'buffer' });
    const sheetName = workbook.SheetNames[0];
    if (sheetName) {
      rows = XLSX.utils.sheet_to_json(workbook.Sheets[sheetName]);
    }
  } else if (body.results && Array.isArray(body.results)) {
    rows = body.results;
  } else if (Array.isArray(body)) {
    rows = body;
  }

  if (!rows || rows.length === 0) {
    throw new Error('No data found in uploaded Excel file or request body');
  }

  let teacherClassId: string | null = null;
  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass) {
      throw new Error('You are not currently assigned to any class');
    }
    teacherClassId = teacherClass.id;
  }

  const errors: string[] = [];
  const validItems: any[] = [];

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    const rowNum = i + 1;

    const admissionNum = String(
      row['Admission Number'] ?? row['admission_number'] ?? row['AdmissionNo'] ?? row['Admission Number*'] ?? ''
    ).trim();

    const subjectInput = String(
      row['Subject'] ?? row['subject'] ?? row['SubjectName'] ?? row['subject_name'] ?? row['subject_code'] ?? ''
    ).trim();

    const examInput = String(
      row['Exam'] ?? row['exam'] ?? row['ExamName'] ?? row['exam_name'] ?? ''
    ).trim();

    const rawMarks = row['Marks'] ?? row['marks_obtained'] ?? row['MarksObtained'] ?? row['Marks Obtained'];
    const rawTotal = row['Total Marks'] ?? row['maximum_marks'] ?? row['TotalMarks'] ?? row['Maximum Marks'] ?? 100;
    const gradeInput = row['Grade'] ?? row['grade'];
    const remarksInput = row['Remarks'] ?? row['remarks'];

    if (!admissionNum) {
      errors.push(`Row ${rowNum}: Missing Admission Number`);
      continue;
    }
    if (!subjectInput) {
      errors.push(`Row ${rowNum}: Missing Subject`);
      continue;
    }
    if (!examInput) {
      errors.push(`Row ${rowNum}: Missing Exam`);
      continue;
    }

    const student = await prisma.students.findUnique({
      where: { admission_number: admissionNum },
    });
    if (!student) {
      errors.push(`Row ${rowNum}: Student with admission number '${admissionNum}' not found`);
      continue;
    }

    if (user.role === 'class_teacher' && student.class_id !== teacherClassId) {
      errors.push(`Row ${rowNum}: Student '${student.full_name}' (${admissionNum}) does not belong to your assigned class`);
      continue;
    }

    const isUuid = (str: string) => /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(str);

    const subject = await prisma.subjects.findFirst({
      where: {
        OR: [
          ...(isUuid(subjectInput) ? [{ id: subjectInput }] : []),
          { subject_name: { equals: subjectInput, mode: 'insensitive' } },
          { subject_code: { equals: subjectInput, mode: 'insensitive' } },
        ]
      }
    });
    if (!subject) {
      errors.push(`Row ${rowNum}: Subject '${subjectInput}' not found`);
      continue;
    }

    if (student.class_id) {
      const studentClass = await prisma.classes.findUnique({ where: { id: student.class_id } });
      if (studentClass && !isValidSubjectForClass(studentClass.class_name, subject.subject_name)) {
        errors.push(`Row ${rowNum}: Subject '${subject.subject_name}' is not allowed for ${studentClass.class_name}`);
        continue;
      }
    }

    const exam = await prisma.exams.findFirst({
      where: {
        OR: [
          ...(isUuid(examInput) ? [{ id: examInput }] : []),
          { exam_name: { equals: examInput, mode: 'insensitive' } },
        ]
      }
    });
    if (!exam) {
      errors.push(`Row ${rowNum}: Exam '${examInput}' not found`);
      continue;
    }

    const marksObtained = Number(rawMarks);
    const maximumMarks = Number(rawTotal) || 100;

    if (isNaN(marksObtained)) {
      errors.push(`Row ${rowNum}: Invalid marks '${rawMarks}'`);
      continue;
    }

    if (marksObtained < 0 || marksObtained > maximumMarks) {
      errors.push(`Row ${rowNum}: Marks obtained (${marksObtained}) cannot exceed maximum marks (${maximumMarks})`);
      continue;
    }

    let grade = gradeInput ? String(gradeInput).trim() : null;
    if (!grade) {
      const pct = (marksObtained / maximumMarks) * 100;
      if (pct >= 90) grade = 'A+';
      else if (pct >= 80) grade = 'A';
      else if (pct >= 70) grade = 'B+';
      else if (pct >= 60) grade = 'B';
      else if (pct >= 50) grade = 'C';
      else if (pct >= 40) grade = 'D';
      else grade = 'F';
    }

    validItems.push({
      exam_id: exam.id,
      student_id: student.id,
      subject_id: subject.id,
      marks_obtained: marksObtained,
      maximum_marks: maximumMarks,
      grade,
      remarks: remarksInput ? String(remarksInput).trim() : null,
      created_by: user.id,
    });
  }

  const importedCount = validItems.length;
  const skippedCount = errors.length;
  const data: any[] = [];

  if (validItems.length > 0) {
    await prisma.$transaction(async (tx) => {
      for (const item of validItems) {
        const existing = await tx.results.findUnique({
          where: {
            exam_id_student_id_subject_id: {
              exam_id: item.exam_id,
              student_id: item.student_id,
              subject_id: item.subject_id,
            }
          }
        });

        let saved;
        if (existing) {
          saved = await tx.results.update({
            where: { id: existing.id },
            data: {
              marks_obtained: item.marks_obtained,
              maximum_marks: item.maximum_marks,
              grade: item.grade,
              remarks: item.remarks,
            },
            include: {
              student: { select: { admission_number: true, full_name: true, roll_number: true } },
              subject: { select: { subject_name: true } },
              exam: { select: { exam_name: true } }
            }
          });
        } else {
          saved = await tx.results.create({
            data: item,
            include: {
              student: { select: { admission_number: true, full_name: true, roll_number: true } },
              subject: { select: { subject_name: true } },
              exam: { select: { exam_name: true } }
            }
          });
        }
        data.push({
          ...saved,
          students: saved.student ? { full_name: saved.student.full_name, roll_number: saved.student.roll_number, admission_number: saved.student.admission_number } : null,
          subjects: saved.subject ? { subject_name: saved.subject.subject_name } : null,
          exams: saved.exam ? { exam_name: saved.exam.exam_name } : null,
        });
      }
    });
  }

  return {
    importedCount,
    skippedCount,
    errors,
    data,
  };
};

export const getAllResults = async (user: any, classIdQuery?: string) => {
  let filter: any = {};
  let resolvedClassId: string | null = classIdQuery || null;

  console.log(`[RESULTS BACKEND] Request received. Authenticated User: ${user.username || user.id || user.userId}, JWT Role: ${user.role}, Requested classId: ${classIdQuery || 'none'}`);

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (teacherClass) {
      resolvedClassId = teacherClass.id;
      filter = { student: { class_id: teacherClass.id } };
    } else {
      console.log(`[RESULTS BACKEND] Authenticated User: ${user.id}, JWT Role: ${user.role}, Requested classId: ${classIdQuery || 'none'}, SQL Query: SELECT * FROM results WHERE student.class_id = NULL, Number of results returned: 0`);
      return [];
    }
  } else if (user.role === 'student') {
    const studentProfile = await prisma.students.findUnique({
      where: { profile_id: user.id }
    });
    if (studentProfile) {
      filter = { student_id: studentProfile.id, is_published: true };
    } else {
      console.log(`[RESULTS BACKEND] Authenticated User: ${user.id}, JWT Role: ${user.role}, Requested classId: ${classIdQuery || 'none'}, SQL Query: SELECT * FROM results WHERE student_id = NULL, Number of results returned: 0`);
      return [];
    }
  } else if (classIdQuery && classIdQuery.trim() !== '') {
    filter = { student: { class_id: classIdQuery.trim() } };
  }

  console.log(`[RESULTS BACKEND] Executing SQL Query: SELECT * FROM results WHERE ${JSON.stringify(filter)}`);

  const rawResults = await prisma.results.findMany({
    where: filter,
    include: {
      student: { select: { admission_number: true, full_name: true, roll_number: true, class: { select: { class_name: true } } } },
      subject: { select: { subject_name: true, subject_code: true } },
      exam: { select: { exam_name: true } }
    },
    orderBy: { created_at: 'desc' },
  });

  console.log(`[RESULTS BACKEND] Authenticated User: ${user.id}, JWT Role: ${user.role}, Requested classId: ${classIdQuery || resolvedClassId || 'all'}, SQL Query: SELECT * FROM results WHERE ${JSON.stringify(filter)}, Number of results returned: ${rawResults.length}`);

  return rawResults.map(r => ({
    ...r,
    students: r.student ? { full_name: r.student.full_name, roll_number: r.student.roll_number, admission_number: r.student.admission_number } : null,
    subjects: r.subject ? { subject_name: r.subject.subject_name, subject_code: r.subject.subject_code } : null,
    exams: r.exam ? { exam_name: r.exam.exam_name } : null,
  }));
};

export const getResultById = async (id: string, user: any) => {
  const result = await prisma.results.findUnique({
    where: { id },
    include: {
      student: { select: { class_id: true, profile_id: true, full_name: true, admission_number: true, roll_number: true } },
      subject: { select: { subject_name: true, subject_code: true } },
      exam: { select: { exam_name: true } }
    },
  });

  if (!result) return null;

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== result.student.class_id) {
      throw new Error('Not authorized to access this result');
    }
  } else if (user.role === 'student') {
    if (result.student.profile_id !== user.id || !result.is_published) {
      throw new Error('Not authorized to access this result');
    }
  }

  return {
    ...result,
    students: result.student ? { full_name: result.student.full_name, roll_number: result.student.roll_number, admission_number: result.student.admission_number } : null,
    subjects: result.subject ? { subject_name: result.subject.subject_name, subject_code: result.subject.subject_code } : null,
    exams: result.exam ? { exam_name: result.exam.exam_name } : null,
  };
};

export const updateResult = async (id: string, data: any, user: any) => {
  const result = await prisma.results.findUnique({
    where: { id },
    include: { student: true }
  });

  if (!result) throw new Error('Result not found');

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== result.student.class_id) {
      throw new Error('Not authorized to update this result');
    }
  }

  const targetSubjectId = data.subject_id || data.subjectId || result.subject_id;
  if (result.student && result.student.class_id) {
    const studentClass = await prisma.classes.findUnique({ where: { id: result.student.class_id } });
    const targetSubject = await prisma.subjects.findUnique({ where: { id: targetSubjectId } });
    if (studentClass && targetSubject && !isValidSubjectForClass(studentClass.class_name, targetSubject.subject_name)) {
      throw new Error(`Subject '${targetSubject.subject_name}' is not allowed for ${studentClass.class_name}`);
    }
  }

  const marksObtained = data.marks_obtained ?? data.marksObtained ?? result.marks_obtained;
  const maxMarks = data.maximum_marks ?? data.maximumMarks ?? result.maximum_marks;
  const isPublished = data.is_published ?? data.isPublished ?? result.is_published;

  if (marksObtained !== null && marksObtained !== undefined) {
    if (Number(marksObtained) < 0 || Number(marksObtained) > Number(maxMarks)) {
      throw new Error(`Marks obtained cannot exceed maximum marks (${maxMarks})`);
    }
  }

  const publishedAt = isPublished && !result.is_published ? new Date() : result.published_at;

  const updated = await prisma.results.update({
    where: { id },
    data: {
      marks_obtained: marksObtained,
      maximum_marks: maxMarks,
      grade: data.grade || result.grade,
      result_status: data.result_status || data.resultStatus || result.result_status,
      remarks: data.remarks !== undefined ? data.remarks : result.remarks,
      is_published: isPublished,
      published_at: publishedAt,
    },
    include: {
      student: { select: { admission_number: true, full_name: true, roll_number: true } },
      subject: { select: { subject_name: true } },
      exam: { select: { exam_name: true } }
    }
  });

  return {
    ...updated,
    students: updated.student ? { full_name: updated.student.full_name, roll_number: updated.student.roll_number, admission_number: updated.student.admission_number } : null,
    subjects: updated.subject ? { subject_name: updated.subject.subject_name } : null,
    exams: updated.exam ? { exam_name: updated.exam.exam_name } : null,
  };
};

export const deleteResult = async (id: string, user: any) => {
  const result = await prisma.results.findUnique({
    where: { id },
    include: { student: true }
  });

  if (!result) throw new Error('Result not found');

  if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (!teacherClass || teacherClass.id !== result.student.class_id) {
      throw new Error('Not authorized to delete this result');
    }
  }

  await prisma.results.delete({ where: { id } });
  return { success: true };
};
