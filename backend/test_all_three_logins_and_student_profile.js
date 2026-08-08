const URL = `http://localhost:5000/api`;

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

async function runAuthenticationAndProfileTests() {
  console.log('================================================================');
  console.log('=== VERIFYING SUPER ADMIN, TEACHER & STUDENT LOGINS & PROFILE ===');
  console.log('================================================================\n');

  // Test 1: Super Admin Login
  console.log('--- Test 1: Super Admin Login ---');
  const adminLoginRes = await fetchJSON('/auth/login', 'POST', { username: 'sadar', password: 'Ham@9345' });
  const adminToken = adminLoginRes.data?.data?.token || adminLoginRes.data?.token;
  const adminJwt = parseJwt(adminToken);

  console.log('Admin login status:', adminLoginRes.status, 'JWT:', adminJwt);
  if (adminLoginRes.status !== 200 || !adminJwt || adminJwt.role !== 'super_admin') {
    console.error('❌ FAIL: Super Admin login failed or role invalid');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Super Admin login successful (role = super_admin)!');

  // Create temporary teacher for testing
  const classesRes = await fetchJSON('/classes', 'GET', null, adminToken);
  const classes = classesRes.data?.data || [];
  const testClass = classes[0];

  const tUsername = `teacher_test_${Date.now()}`;
  const createTeacherRes = await fetchJSON('/teachers', 'POST', {
    fullName: 'Test Teacher Login',
    username: tUsername,
    classId: testClass.id,
  }, adminToken);
  const createdTeacher = createTeacherRes.data.data;

  // Test 2: Teacher Login
  console.log('\n--- Test 2: Teacher Login ---');
  const teacherLoginRes = await fetchJSON('/auth/login', 'POST', {
    username: tUsername,
    password: `Ham@cls${testClass.class_name.match(/\d+/)?.[0] || '1'}`,
  });
  const teacherToken = teacherLoginRes.data?.data?.token || teacherLoginRes.data?.token;
  const teacherJwt = parseJwt(teacherToken);

  console.log('Teacher login status:', teacherLoginRes.status, 'JWT:', teacherJwt);
  if (teacherLoginRes.status !== 200 || !teacherJwt || teacherJwt.role !== 'class_teacher') {
    console.error('❌ FAIL: Teacher login failed or role invalid');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Teacher login successful (role = class_teacher)!');

  // Create temporary student for testing
  const sAdm = `ADM_ST_${Date.now()}`;
  const createStudentRes = await fetchJSON('/students', 'POST', {
    admission_number: sAdm,
    roll_number: '707',
    full_name: 'Student Profile Tester',
    class_id: testClass.id,
    guardian_name: 'Parent Name',
    guardian_phone: '+91 98765 00000',
    address: '123 Test Street',
  }, adminToken);
  const createdStudent = createStudentRes.data.data;

  // Test 3: Student Login
  console.log('\n--- Test 3: Student Login ---');
  const studentLoginRes = await fetchJSON('/auth/login', 'POST', {
    username: sAdm,
    password: sAdm,
  });
  const studentToken = studentLoginRes.data?.data?.token || studentLoginRes.data?.token;
  const studentJwt = parseJwt(studentToken);

  console.log('Student login status:', studentLoginRes.status, 'JWT:', studentJwt);
  if (studentLoginRes.status !== 200 || !studentJwt || studentJwt.role !== 'student') {
    console.error('❌ FAIL: Student login failed or role is not "student"!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Student login successful (role = student)!');

  // Test 4: Student GET /students/profile (own profile)
  console.log('\n--- Test 4: Student GET /students/profile ---');
  const studentProfileRes = await fetchJSON('/students/profile', 'GET', null, studentToken);
  console.log('Profile status:', studentProfileRes.status);
  console.log('Profile data:', JSON.stringify(studentProfileRes.data, null, 2));

  if (studentProfileRes.status !== 200 || !studentProfileRes.data?.data?.fullName) {
    console.error('❌ FAIL: Failed to load student profile for student role!');
    process.exit(1);
  }

  const pData = studentProfileRes.data.data;
  console.log(`Loaded Profile: Name="${pData.fullName}", Adm="${pData.admissionNumber}", Class="${pData.className}", Roll="${pData.rollNumber}"`);
  console.log('🎉 ✅ PASS: Student loaded profile without authorization errors!');

  // Test 5: Student GET /students/profile/:profileId
  console.log(`\n--- Test 5: Student GET /students/profile/${createdStudent.profile_id} ---`);
  const studentProfileIdRes = await fetchJSON(`/students/profile/${createdStudent.profile_id}`, 'GET', null, studentToken);
  console.log('Profile by ID status:', studentProfileIdRes.status);
  if (studentProfileIdRes.status !== 200) {
    console.error('❌ FAIL: Failed to load student profile by profileId!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Student loaded profile by profileId successfully!');

  // Cleanup test records
  console.log('\n--- Cleanup test records ---');
  await fetchJSON(`/students/${createdStudent.id}`, 'DELETE', null, adminToken);
  await fetchJSON(`/teachers/${createdTeacher.id}`, 'DELETE', null, adminToken);
  console.log('✅ Cleaned up test records.');

  console.log('\n================================================================');
  console.log('🎉 ALL LOGIN, ROLE JWT & STUDENT PROFILE TESTS PASSED PERFECTLY!');
  console.log('================================================================\n');
}

runAuthenticationAndProfileTests().catch(err => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
