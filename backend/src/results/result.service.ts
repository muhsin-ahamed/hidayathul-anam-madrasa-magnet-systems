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
  const isUuid = (str: string) => /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(str);

  // Metadata keys to ignore when picking subject columns in matrix Excel
  const METADATA_KEYS = new Set([
    'ADMISSIONNO', 'ADMISSIONNUMBER', 'ADMNO', 'ADMISSION', 'STUDENTID',
    'STUDENTNAME', 'NAME', 'STUDENT',
    'TOTAL', 'TOTAL200', 'TOTALMARKS', 'MAXIMUMMARKS', 'TOTALMARKOBAINED',
    'GRADE', 'GRADENAME',
    'STATUS', 'RANK', 'STATUSRANK', 'STATURANK',
    'SLNO', 'SNO', 'SERIALNO',
    'EXAM', 'EXAMNAME', 'TERM',
    'REMARKS', 'REMARK'
  ]);

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    const rowNum = i + 1;

    let admissionNum = '';
    for (const k of Object.keys(row)) {
      const norm = k.trim().toUpperCase().replace(/[`'\s_]/g, '');
      if (['ADMISSIONNO', 'ADMISSIONNUMBER', 'ADMNO', 'ADMISSION', 'STUDENTID'].includes(norm)) {
        admissionNum = String(row[k]).trim();
        break;
      }
    }

    const studentNameInput = String(
      row['STUDENT NAME'] ?? row['Student Name'] ?? row['student_name'] ?? row['Name'] ?? row['name'] ?? ''
    ).trim();

    const cleanAdmissionNum = admissionNum.replace(/\.0$/, '').trim();

    let student = await prisma.students.findFirst({
      where: {
        OR: [
          ...(cleanAdmissionNum ? [
            { admission_number: { equals: cleanAdmissionNum, mode: 'insensitive' as const } },
            { admission_number: { equals: `ADM${cleanAdmissionNum}`, mode: 'insensitive' as const } },
            { admission_number: { contains: cleanAdmissionNum, mode: 'insensitive' as const } },
          ] : []),
          ...(studentNameInput ? [
            { full_name: { equals: studentNameInput, mode: 'insensitive' as const } },
            { full_name: { contains: studentNameInput, mode: 'insensitive' as const } },
          ] : [])
        ]
      }
    });

    if (!student) {
      const targetClassId = teacherClassId;
      if (targetClassId && (cleanAdmissionNum || studentNameInput)) {
        const finalAdmNo = cleanAdmissionNum || `ADM_${Date.now()}_${i}`;
        const finalName = studentNameInput || `Student ${finalAdmNo}`;

        let profile = await prisma.profiles.findFirst({
          where: { username: finalAdmNo }
        });

        if (!profile) {
          try {
            profile = await prisma.profiles.create({
              data: {
                full_name: finalName,
                username: finalAdmNo,
                role: 'student',
                is_active: true,
              }
            });
          } catch (e) {
            profile = await prisma.profiles.findFirst({
              where: { username: finalAdmNo }
            });
          }
        }

        if (profile) {
          student = await prisma.students.findFirst({
            where: {
              OR: [
                { profile_id: profile.id },
                { admission_number: finalAdmNo }
              ]
            }
          });

          if (!student) {
            student = await prisma.students.create({
              data: {
                profile_id: profile.id,
                admission_number: finalAdmNo,
                full_name: finalName,
                roll_number: String(rowNum),
                class_id: targetClassId,
              }
            });
          }
        }
      }

      if (!student) {
        errors.push(`Row ${rowNum}: Student '${studentNameInput || cleanAdmissionNum}' could not be created`);
        continue;
      }
    }

    if (user.role === 'class_teacher' && teacherClassId) {
      if (!student.class_id) {
        student = await prisma.students.update({
          where: { id: student.id },
          data: { class_id: teacherClassId },
        });
      } else if (student.class_id !== teacherClassId) {
        errors.push(`Row ${rowNum}: Student '${student.full_name}' (${admissionNum}) does not belong to your assigned class`);
        continue;
      }
    }

    let examInput = String(
      row['Exam'] ?? row['exam'] ?? row['ExamName'] ?? row['exam_name'] ?? body.examId ?? body.exam_id ?? body.exam ?? ''
    ).trim();

    let exam: any = null;
    if (examInput) {
      exam = await prisma.exams.findFirst({
        where: {
          OR: [
            ...(isUuid(examInput) ? [{ id: examInput }] : []),
            { exam_name: { equals: examInput, mode: 'insensitive' as const } },
          ]
        }
      });
    }

    if (!exam && student.class_id) {
      exam = await prisma.exams.findFirst({
        where: { class_id: student.class_id },
        orderBy: { created_at: 'desc' }
      });
    }

    if (!exam && student.class_id) {
      const examName = examInput || 'Term Exam';
      exam = await prisma.exams.create({
        data: {
          class_id: student.class_id,
          exam_name: examName,
          term: 'Term 1',
          start_date: new Date(),
          end_date: new Date(),
          results_published: true,
        }
      });
    }

    if (!exam) {
      errors.push(`Row ${rowNum}: Could not find or create exam for student '${admissionNum}'`);
      continue;
    }

    const singleSubjectInput = String(
      row['Subject'] ?? row['subject'] ?? row['SubjectName'] ?? row['subject_name'] ?? row['subject_code'] ?? ''
    ).trim();

    const subjectEntries: { name: string; marks: any }[] = [];

    if (singleSubjectInput) {
      subjectEntries.push({
        name: singleSubjectInput,
        marks: row['Marks'] ?? row['marks_obtained'] ?? row['MarksObtained'] ?? row['Marks Obtained']
      });
    } else {
      for (const k of Object.keys(row)) {
        const norm = k.trim().toUpperCase().replace(/[`'\s_()0-9]/g, '');
        const valStr = String(row[k]).trim();
        if (!METADATA_KEYS.has(norm) && row[k] !== undefined && row[k] !== null && valStr !== '' && !valStr.startsWith('=') && !valStr.startsWith('SUM(') && !valStr.startsWith('RANK(')) {
          subjectEntries.push({ name: k.trim(), marks: row[k] });
        }
      }
    }

    if (subjectEntries.length === 0) {
      errors.push(`Row ${rowNum}: No subjects or marks found for student '${admissionNum}'`);
      continue;
    }

    for (const subEntry of subjectEntries) {
      const subjectInput = subEntry.name;
      let subject = await prisma.subjects.findFirst({
        where: {
          OR: [
            ...(isUuid(subjectInput) ? [{ id: subjectInput }] : []),
            { subject_name: { equals: subjectInput, mode: 'insensitive' } },
            { subject_code: { equals: subjectInput, mode: 'insensitive' } },
          ]
        }
      });

      if (!subject && student.class_id) {
        subject = await prisma.subjects.create({
          data: {
            class_id: student.class_id,
            subject_name: subjectInput,
            subject_code: subjectInput.substring(0, 10).toUpperCase(),
          }
        });
      }

      if (!subject) {
        errors.push(`Row ${rowNum}: Subject '${subjectInput}' not found`);
        continue;
      }

      const marksObtained = Number(subEntry.marks);
      const maximumMarks = Number(row['Total Marks'] ?? row['maximum_marks'] ?? row['TotalMarks'] ?? 100) || 100;

      if (isNaN(marksObtained)) {
        errors.push(`Row ${rowNum}: Invalid marks '${subEntry.marks}' for subject '${subjectInput}'`);
        continue;
      }

      let grade = row['Grade'] ?? row['grade'];
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
        grade: String(grade).trim(),
        remarks: row['Remarks'] ?? row['remarks'] ?? null,
        created_by: user.id,
      });
    }
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
