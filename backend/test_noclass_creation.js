const http = require('http');

const PORT = 5000;
const URL = `http://localhost:${PORT}/api`;

async function fetchJSON(path, method, body, token) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const options = { method, headers };
  if (body) options.body = JSON.stringify(body);

  try {
    const res = await fetch(`${URL}${path}`, options);
    const json = await res.json().catch((err) => ({ parseError: err.message }));
    return { status: res.status, data: json };
  } catch (e) {
    return { status: 500, error: e.message };
  }
}

async function runNoClassTests() {
  console.log('=== TESTING UNASSIGNED (NO CLASS) STUDENT & TEACHER CREATION ===');

  // Step 1: Admin Login
  const loginRes = await fetchJSON('/auth/login', 'POST', { username: 'sadar', password: 'Ham@9345' });
  const token = loginRes.data?.data?.token || loginRes.data?.token;

  if (!token) {
    console.error('❌ Failed admin login');
    process.exit(1);
  }

  // Step 2: Create Student without class (class_id: null)
  console.log('\n--- Step 2: Create Student without class (class_id: null) ---');
  const studentAdm = `ADM_NOCLASS_${Date.now()}`;
  const studentPayload = {
    admission_number: studentAdm,
    roll_number: '901',
    full_name: 'Student No Class',
    class_id: null,
  };

  const createStudentRes = await fetchJSON('/students', 'POST', studentPayload, token);
  console.log('Create student status:', createStudentRes.status);
  console.log('Create student data:', JSON.stringify(createStudentRes.data, null, 2));

  if (createStudentRes.status !== 201 || createStudentRes.data?.data?.class_id !== null) {
    console.error('❌ FAIL: Student creation without class failed or class_id not null!');
    process.exit(1);
  }
  console.log('🎉 ✅ SUCCESS: Student created with class_id = null!');
  const createdStudent = createStudentRes.data.data;

  // Step 3: Create Teacher without class (classId: null) & without email
  console.log('\n--- Step 3: Create Teacher without class (classId: null) & without email ---');
  const teacherUser = `t_noclass_${Date.now()}`;
  const teacherPayload = {
    fullName: 'Teacher No Class',
    username: teacherUser,
    email: null,
    phone: null,
    classId: null,
  };

  const createTeacherRes = await fetchJSON('/teachers', 'POST', teacherPayload, token);
  console.log('Create teacher status:', createTeacherRes.status);
  console.log('Create teacher data:', JSON.stringify(createTeacherRes.data, null, 2));

  if (createTeacherRes.status !== 201) {
    console.error('❌ FAIL: Teacher creation without class failed!');
    process.exit(1);
  }
  console.log('🎉 ✅ SUCCESS: Teacher created without assigned class!');
  const createdTeacher = createTeacherRes.data.data;

  // Step 4: Verify Teacher Login Works
  console.log('\n--- Step 4: Verify Teacher Login for unassigned teacher ---');
  const loginTeacherRes = await fetchJSON('/auth/login', 'POST', { username: teacherUser, password: 'Ham@123' });
  console.log('Teacher login status:', loginTeacherRes.status);
  if (loginTeacherRes.status === 200) {
    console.log('🎉 ✅ SUCCESS: Unassigned Teacher can log in!');
  } else {
    console.error('❌ FAIL: Teacher login failed');
    process.exit(1);
  }

  // Step 5: Clean up created student & teacher
  console.log('\n--- Step 5: Clean up test records ---');
  await fetchJSON(`/students/${createdStudent.id}`, 'DELETE', null, token);
  await fetchJSON(`/teachers/${createdTeacher.id}`, 'DELETE', null, token);
  console.log('✅ Cleaned up test records.');

  console.log('\n🎉 ALL OPTIONAL CLASS CREATION TESTS PASSED PERFECTLY!');
}

runNoClassTests().catch(err => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
