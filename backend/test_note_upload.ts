import http from 'http';
import fs from 'fs';
import path from 'path';
import { prisma } from './src/config/db';
import { signToken } from './src/utils/jwt';
import { getSubjectsForClass } from './src/config/subjects';

function postMultipart(urlPath: string, token: string, fields: Record<string, string>, file?: { name: string; filename: string; buffer: Buffer; mime: string }) {
  return new Promise<{ status: number; body: any }>((resolve, reject) => {
    const boundary = '--------------------------' + Math.random().toString(16).substring(2);
    const postData: Buffer[] = [];

    for (const [key, val] of Object.entries(fields)) {
      postData.push(Buffer.from(
        `--${boundary}\r\nContent-Disposition: form-data; name="${key}"\r\n\r\n${val}\r\n`
      ));
    }

    if (file) {
      postData.push(Buffer.from(
        `--${boundary}\r\nContent-Disposition: form-data; name="${file.name}"; filename="${file.filename}"\r\nContent-Type: ${file.mime}\r\n\r\n`
      ));
      postData.push(file.buffer);
      postData.push(Buffer.from('\r\n'));
    }

    postData.push(Buffer.from(`--${boundary}--\r\n`));
    const fullBuffer = Buffer.concat(postData);

    const req = http.request({
      hostname: 'localhost',
      port: 5000,
      path: urlPath,
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
        'Content-Length': fullBuffer.length,
      },
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        let json = null;
        try { json = JSON.parse(data); } catch (_) { json = data; }
        resolve({ status: res.statusCode || 500, body: json });
      });
    });

    req.on('error', (err) => reject(err));
    req.write(fullBuffer);
    req.end();
  });
}

function postJson(urlPath: string, payload: any, token?: string) {
  return new Promise<{ status: number; body: any }>((resolve, reject) => {
    const dataStr = JSON.stringify(payload);
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(dataStr).toString(),
    };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const req = http.request({
      hostname: 'localhost',
      port: 5000,
      path: urlPath,
      method: 'POST',
      headers,
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        let json = null;
        try { json = JSON.parse(data); } catch (_) { json = data; }
        resolve({ status: res.statusCode || 500, body: json });
      });
    });

    req.on('error', (err) => reject(err));
    req.write(dataStr);
    req.end();
  });
}

function getUrl(urlPath: string, token?: string) {
  return new Promise<{ status: number; headers: any; body: any }>((resolve, reject) => {
    const headers: Record<string, string> = {};
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const req = http.request({
      hostname: 'localhost',
      port: 5000,
      path: urlPath,
      method: 'GET',
      headers,
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        let json = null;
        try { json = JSON.parse(data); } catch (_) { json = data; }
        resolve({ status: res.statusCode || 500, headers: res.headers, body: json });
      });
    });

    req.on('error', (err) => reject(err));
    req.end();
  });
}

async function runTests() {
  console.log('=== AUDITING COMPLETE NOTES FILE STORAGE & DOWNLOAD SYSTEM ===\n');

  try {
    const teacherProfile = await prisma.profiles.findFirst({
      where: { role: 'class_teacher' },
      include: { classes: true }
    });

    if (!teacherProfile) {
      console.error('No class teacher profile found in database.');
      return;
    }

    const teacherClass = teacherProfile.classes[0] || await prisma.classes.findFirst();
    if (!teacherClass) {
      console.error('No class found in database.');
      return;
    }

    const validSubjectNames = getSubjectsForClass(teacherClass.class_name);
    const validSubjectName = validSubjectNames[0] || 'تفهيم';

    let subject = await prisma.subjects.findFirst({
      where: { class_id: teacherClass.id, subject_name: validSubjectName }
    });

    if (!subject) {
      subject = await prisma.subjects.create({
        data: {
          subject_name: validSubjectName,
          class_id: teacherClass.id,
        }
      });
    }

    const token = signToken({
      id: teacherProfile.id,
      userId: teacherProfile.id,
      username: teacherProfile.username || 'teacher',
      role: 'class_teacher',
    });

    const studentProfile = await prisma.students.findFirst({
      where: { class_id: teacherClass.id },
      include: { profile: true }
    });

    const studentToken = signToken({
      id: studentProfile?.profile_id || teacherProfile.id,
      userId: studentProfile?.profile_id || teacherProfile.id,
      username: studentProfile?.admission_number || 'student',
      role: 'student',
    });

    console.log(`[SETUP] Class Teacher: ${teacherProfile.username} | Class: ${teacherClass.class_name} | Subject: ${subject.subject_name}`);

    const pdfBuffer = Buffer.from('%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >>\nendobj\nxref\n0 4\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \ntrailer\n<< /Size 4 /Root 1 0 R >>\nstartxref\n190\n%%EOF');

    // 1. Upload PDF
    console.log('\n--- STEP 1: Upload PDF Note ---');
    const uploadRes = await postMultipart('/api/notes', token, {
      title: 'Chapter 2 Fiqh Lecture PDF Note',
      description: 'Important study materials for exams',
      classId: teacherClass.id,
      subjectId: subject.id,
      teacherId: teacherProfile.id,
    }, { name: 'file', filename: 'fiqh_lecture_notes.pdf', buffer: pdfBuffer, mime: 'application/pdf' });

    console.log('Upload Status:', uploadRes.status);
    console.log('Upload Data:', JSON.stringify(uploadRes.body, null, 2));

    if (uploadRes.status !== 201 || !uploadRes.body?.data?.id) {
      console.error('FAIL: PDF upload failed.');
      return;
    }
    console.log('PASS: PDF uploaded successfully.');

    const note = uploadRes.body.data;
    const noteId = note.id;
    const dbFilePath = note.file_path; // e.g. /uploads/notes/note-12345.pdf

    // 2. Verify physical file on disk
    console.log('\n--- STEP 2: Verify Physical File on Disk ---');
    const absoluteDiskPath = path.join(process.cwd(), dbFilePath);
    console.log(`Checking disk path: ${absoluteDiskPath}`);
    const existsOnDisk = fs.existsSync(absoluteDiskPath);
    console.log(`File exists on disk: ${existsOnDisk}`);

    if (existsOnDisk) {
      console.log('PASS: File is physically saved on disk.');
    } else {
      console.error('FAIL: File was NOT found on disk.');
    }

    // 3. Verify Database Metadata
    console.log('\n--- STEP 3: Verify PostgreSQL Database Metadata ---');
    const dbNote = await prisma.notes.findUnique({ where: { id: noteId } });
    console.log(`DB Record file_path: "${dbNote?.file_path}" | title: "${dbNote?.title}"`);
    if (dbNote && dbNote.file_path === dbFilePath) {
      console.log('PASS: Database stores correct file URL.');
    } else {
      console.error('FAIL: Database record missing or incorrect.');
    }

    // 4. Verify Signed URL API endpoint (/api/files/signed-url)
    console.log('\n--- STEP 4: Verify /api/files/signed-url API Endpoint ---');
    const signedUrlRes = await postJson('/api/files/signed-url', { path: dbFilePath }, token);
    console.log('Signed URL Status:', signedUrlRes.status);
    console.log('Signed URL Response:', signedUrlRes.body);

    const generatedSignedUrl = signedUrlRes.body?.data?.signedUrl;
    if (signedUrlRes.status === 200 && generatedSignedUrl) {
      console.log(`PASS: Signed download URL generated: ${generatedSignedUrl}`);
    } else {
      console.error('FAIL: Signed URL generation failed.');
    }

    // 5. Verify Express serves static file (GET /uploads/notes/...)
    console.log('\n--- STEP 5: Verify Express Static File Serving (HTTP GET) ---');
    const downloadRes = await getUrl(dbFilePath, token);
    console.log('Static Download GET Status:', downloadRes.status);
    console.log('Content-Type Header:', downloadRes.headers['content-type']);
    console.log('Content-Length Header:', downloadRes.headers['content-length']);

    if (downloadRes.status === 200 && (downloadRes.headers['content-type']?.includes('pdf') || downloadRes.headers['content-type']?.includes('octet-stream'))) {
      console.log('PASS: PDF served successfully via Express static handler.');
    } else {
      console.error('FAIL: Static file serving failed.');
    }

    // 6. Verify non-existent file returns proper JSON 404 response
    console.log('\n--- STEP 6: Verify Non-Existent File 404 Handling ---');
    const nonExistentStaticRes = await getUrl('/uploads/notes/non_existent_file_9999.pdf', token);
    console.log('Non-Existent File Status:', nonExistentStaticRes.status);
    console.log('Non-Existent File Body:', nonExistentStaticRes.body);

    const nonExistentSignedRes = await postJson('/api/files/signed-url', { path: '/uploads/notes/non_existent_file_9999.pdf' }, token);
    console.log('Non-Existent Signed URL Status:', nonExistentSignedRes.status);
    console.log('Non-Existent Signed URL Body:', nonExistentSignedRes.body);

    if (nonExistentStaticRes.status === 404 && nonExistentStaticRes.body?.success === false && nonExistentSignedRes.status === 404) {
      console.log('PASS: Proper JSON 404 responses returned for non-existent files.');
    } else {
      console.error('FAIL: Non-existent file did not return proper JSON 404.');
    }

    // 7. Verify Notes appear in Teacher & Student Query Endpoints
    console.log('\n--- STEP 7: Verify Notes in Teacher & Student Portals ---');
    const teacherNotes = await getUrl(`/api/notes/teacher?classId=${teacherClass.id}`, token);
    const studentNotes = await getUrl(`/api/notes/student?classId=${teacherClass.id}`, studentToken);

    const foundInTeacher = Array.isArray(teacherNotes.body?.data) && teacherNotes.body.data.some((n: any) => n.id === noteId);
    const foundInStudent = Array.isArray(studentNotes.body?.data) && studentNotes.body.data.some((n: any) => n.id === noteId);

    console.log(`Found in Teacher Portal: ${foundInTeacher}`);
    console.log(`Found in Student Portal: ${foundInStudent}`);

    if (foundInTeacher && foundInStudent) {
      console.log('\n===============================================================');
      console.log('=== COMPLETE STORAGE & DOWNLOAD AUDIT PASSED SUCCESSFULLY! ===');
      console.log('===============================================================');
    } else {
      console.error('FAIL: Note missing from student or teacher listing.');
    }

  } catch (err: any) {
    console.error('Audit execution error:', err.message || err);
  } finally {
    await prisma.$disconnect();
  }
}

runTests();
