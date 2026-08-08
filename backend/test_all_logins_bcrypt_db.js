const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const URL = `http://localhost:5000/api`;

function parseJwt(token) {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = Buffer.from(base64, 'base64').toString('utf8');
    return JSON.parse(jsonPayload);
  } catch (e) {
    return null;
  }
}

async function testAllLoginsBcryptDb() {
  console.log('================================================================');
  console.log('=== VERIFYING BCRYPT PASSWORD_HASH AUTHENTICATION FOR ALL ROLES ===');
  console.log('================================================================\n');

  // 1. Super Admin Login
  console.log('--- Step 1: Super Admin Login (sadar / Ham@9345) ---');
  const adminLoginRes = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'sadar', password: 'Ham@9345' }),
  });

  const adminData = await adminLoginRes.json();
  console.log('Admin login status:', adminLoginRes.status);
  console.log('Admin login response:', JSON.stringify(adminData, null, 2));

  const adminToken = adminData.token || adminData.data?.token;
  const adminJwt = parseJwt(adminToken);

  if (adminLoginRes.status !== 200 || !adminJwt || adminJwt.role !== 'super_admin') {
    console.error('❌ FAIL: Super Admin login failed!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Super Admin logged in using bcrypt password_hash in users table!\n');

  // Verify DB record for sadar
  const sadarUser = await prisma.users.findFirst({ where: { username: 'sadar' } });
  console.log('DB users record for "sadar":', sadarUser);
  if (!sadarUser || !sadarUser.password_hash || !sadarUser.password_hash.startsWith('$2b$')) {
    console.error('❌ FAIL: Super Admin password_hash is missing or not a valid bcrypt hash!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Super Admin password_hash verified in users table as bcrypt hash!\n');

  // 2. Teacher Creation & Login
  console.log('--- Step 2: Teacher Creation & Login ---');
  const classesRes = await fetch(`${URL}/classes`, {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  const classes = (await classesRes.json()).data;
  const testClass = classes[0];

  const tUsername = `t_bcrypt_${Date.now()}`;
  const createTeacherRes = await fetch(`${URL}/teachers`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      fullName: 'Teacher Bcrypt Tester',
      username: tUsername,
      classId: testClass.id,
    }),
  });

  const createdTeacher = (await createTeacherRes.json()).data;

  // Verify bcrypt hash in users table for created teacher
  const teacherUser = await prisma.users.findFirst({ where: { username: tUsername } });
  console.log(`DB users record for teacher "${tUsername}":`, teacherUser);
  if (!teacherUser || !teacherUser.password_hash || !teacherUser.password_hash.startsWith('$2b$')) {
    console.error('❌ FAIL: Teacher password_hash is missing or not a valid bcrypt hash!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Teacher password_hash verified in users table as bcrypt hash!\n');

  const classNum = testClass.class_name.match(/\d+/)?.[0] || '1';
  const expectedTeacherPassword = `Ham@cls${classNum}`;

  const teacherLoginRes = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: tUsername, password: expectedTeacherPassword }),
  });
  const teacherData = await teacherLoginRes.json();
  const teacherToken = teacherData.token || teacherData.data?.token;
  const teacherJwt = parseJwt(teacherToken);

  console.log('Teacher login status:', teacherLoginRes.status, 'User Role:', teacherData.user?.role, 'JWT:', teacherJwt);
  if (teacherLoginRes.status !== 200 || !teacherToken || (teacherJwt.role !== 'teacher' && teacherJwt.role !== 'class_teacher')) {
    console.error('❌ FAIL: Teacher login failed!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Teacher logged in using bcrypt password_hash in users table!\n');

  // 3. Student Creation & Login
  console.log('--- Step 3: Student Creation & Login ---');
  const sAdm = `ADM_BCRYPT_${Date.now()}`;
  const createStudentRes = await fetch(`${URL}/students`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      admission_number: sAdm,
      roll_number: '999',
      full_name: 'Student Bcrypt Tester',
      class_id: testClass.id,
    }),
  });

  const createdStudent = (await createStudentRes.json()).data;

  // Verify bcrypt hash in users table for created student
  const studentUser = await prisma.users.findFirst({ where: { username: sAdm } });
  console.log(`DB users record for student "${sAdm}":`, studentUser);
  if (!studentUser || !studentUser.password_hash || !studentUser.password_hash.startsWith('$2b$')) {
    console.error('❌ FAIL: Student password_hash is missing or not a valid bcrypt hash!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Student password_hash verified in users table as bcrypt hash!\n');

  const studentLoginRes = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: sAdm, password: sAdm }),
  });

  const studentData = await studentLoginRes.json();
  const studentToken = studentData.token || studentData.data?.token;
  const studentJwt = parseJwt(studentToken);

  console.log('Student login status:', studentLoginRes.status, 'User Role:', studentData.user?.role, 'JWT:', studentJwt);
  if (studentLoginRes.status !== 200 || !studentToken || studentJwt.role !== 'student') {
    console.error('❌ FAIL: Student login failed!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Student logged in using bcrypt password_hash in users table!\n');

  // Cleanup test records
  await fetch(`${URL}/students/${createdStudent.id}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  await fetch(`${URL}/teachers/${createdTeacher.id}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  console.log('✅ Cleaned up test records.');

  console.log('\n================================================================');
  console.log('🎉 ALL BCRYPT PASSWORD_HASH AUTHENTICATION TESTS PASSED PERFECTLY!');
  console.log('================================================================\n');
}

testAllLoginsBcryptDb()
  .catch((err) => {
    console.error('Test execution failed:', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
