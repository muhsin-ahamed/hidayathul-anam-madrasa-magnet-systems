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

async function testTeacherFlow() {
  console.log('=== TESTING COMPLETE TEACHER CREATION & LOGIN FLOW ===');

  // Step 1: Login as Super Admin
  console.log('\n--- Step 1: Login as Super Admin (sadar) ---');
  const loginAdminRes = await fetchJSON('/auth/login', 'POST', { username: 'sadar', password: 'Ham@9345' });
  console.log('Admin login status:', loginAdminRes.status);
  const token = loginAdminRes.data?.data?.token || loginAdminRes.data?.token;

  if (!token) {
    console.error('❌ Failed to get admin token:', loginAdminRes.data);
    process.exit(1);
  }
  console.log('✅ Obtained Admin Token');

  // Step 2: Get active classes
  console.log('\n--- Step 2: Get active classes ---');
  const classesRes = await fetchJSON('/classes', 'GET', null, token);
  const classList = classesRes.data?.data || classesRes.data;

  if (!Array.isArray(classList) || classList.length === 0) {
    console.error('❌ No classes found in database!');
    process.exit(1);
  }

  const targetClass = classList[0];
  console.log(`✅ Selected target class: "${targetClass.class_name}" (ID: ${targetClass.id})`);

  // Step 3: Test POST /teachers with Flutter payload format (email: null, phone: null)
  console.log('\n--- Step 3: Create Teacher via POST /teachers ---');
  const testUsername = `teacher_${Date.now()}`;
  const testPassword = 'Ham@cls123';
  const flutterPayload = {
    fullName: 'Nizar Test Teacher',
    username: testUsername,
    email: null,
    phone: null,
    classId: targetClass.id,
    password: testPassword,
  };

  const createRes = await fetchJSON('/teachers', 'POST', flutterPayload, token);
  console.log('Create teacher status:', createRes.status);
  console.log('Create teacher response:', JSON.stringify(createRes.data, null, 2));

  if (createRes.status !== 201 || !createRes.data?.success) {
    console.error('❌ FAIL: Teacher creation failed!');
    process.exit(1);
  }

  const createdTeacher = createRes.data.data;
  console.log(`🎉 ✅ SUCCESS: Created teacher ID: ${createdTeacher.id}, Profile ID: ${createdTeacher.profile_id}`);

  // Step 4: Verify Database Records (profiles, users, teachers, classes)
  console.log('\n--- Step 4: Verify assigned class updated ---');
  const verifyClassesRes = await fetchJSON('/classes', 'GET', null, token);
  const updatedClassList = verifyClassesRes.data?.data || verifyClassesRes.data;
  const updatedClass = updatedClassList.find((c) => c.id === targetClass.id);

  console.log(`Target class class_teacher_id: ${updatedClass?.class_teacher_id}`);
  if (updatedClass?.class_teacher_id === createdTeacher.profile_id) {
    console.log('✅ Class teacher_id in classes table matches teacher profile_id!');
  } else {
    console.error(`❌ FAIL: Expected class_teacher_id to be ${createdTeacher.profile_id}, but got ${updatedClass?.class_teacher_id}`);
    process.exit(1);
  }

  // Step 5: Test Teacher Login
  console.log('\n--- Step 5: Test Teacher Login ---');
  const loginTeacherRes = await fetchJSON('/auth/login', 'POST', { username: testUsername, password: testPassword });
  console.log('Teacher login status:', loginTeacherRes.status);
  console.log('Teacher login response:', JSON.stringify(loginTeacherRes.data, null, 2));

  if (loginTeacherRes.status === 200 && loginTeacherRes.data?.token) {
    console.log('🎉 ✅ SUCCESS: Teacher login verified!');
  } else {
    console.error('❌ FAIL: Teacher login failed!');
    process.exit(1);
  }

  // Cleanup
  console.log('\n--- Step 6: Clean up test teacher ---');
  const deleteRes = await fetchJSON(`/teachers/${createdTeacher.id}`, 'DELETE', null, token);
  console.log('Delete teacher status:', deleteRes.status);
  console.log('✅ Cleaned up test teacher.');

  console.log('\n🎉 ALL TEACHER CREATION & LOGIN TESTS PASSED PERFECTLY!');
}

testTeacherFlow().catch((err) => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
