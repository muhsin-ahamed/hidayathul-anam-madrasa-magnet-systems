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

async function testTeacherAuthFlow() {
  console.log('====================================================');
  console.log('=== VERIFYING COMPLETE TEACHER AUTHENTICATION FLOW ===');
  console.log('====================================================\n');

  // Step 1: Admin Login
  const adminLoginRes = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'sadar', password: 'Ham@9345' }),
  });
  const adminData = await adminLoginRes.json();
  const adminToken = adminData.data?.token || adminData.token;

  if (!adminToken) {
    console.error('❌ Super Admin login failed');
    process.exit(1);
  }

  // Step 2: Get Available Class
  const classesRes = await fetch(`${URL}/classes`, {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  const classesData = await classesRes.json();
  const availableClass = (classesData.data || []).find((c) => !c.class_teacher_id) || classesData.data[0];

  const classNum = availableClass.class_name.match(/\d+/)?.[0] || '1';
  const expectedPassword = `Ham@cls${classNum}`;
  const tUsername = `t_auth_${Date.now()}`;

  console.log(`Target class for new teacher: "${availableClass.class_name}" (Expected password: "${expectedPassword}")`);
  console.log(`Teacher Username to create: "${tUsername}"`);

  // Step 3: Create Teacher as Super Admin
  console.log('\n--- Step 3: Create Teacher ---');
  const createRes = await fetch(`${URL}/teachers`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      fullName: 'Teacher Auth Tester',
      username: tUsername,
      classId: availableClass.id,
    }),
  });

  const createData = await createRes.json();
  console.log('Create teacher status:', createRes.status);
  console.log('Create teacher response:', JSON.stringify(createData, null, 2));

  if (createRes.status !== 201 || !createData.data?.id) {
    console.error('❌ FAIL: Teacher creation failed');
    process.exit(1);
  }
  const createdTeacher = createData.data;

  // Step 4: Teacher Login
  console.log('\n--- Step 4: Teacher Login (POST /api/auth/login) ---');
  const loginRes = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: tUsername,
      password: expectedPassword,
    }),
  });

  const loginData = await loginRes.json();
  console.log('Login status:', loginRes.status);
  console.log('Login response:', JSON.stringify(loginData, null, 2));

  const teacherToken = loginData.token || loginData.data?.token;
  const teacherJwt = parseJwt(teacherToken);

  console.log('Decoded JWT payload:', teacherJwt);

  if (
    loginRes.status !== 200 ||
    !teacherToken ||
    !teacherJwt ||
    (teacherJwt.role !== 'teacher' && teacherJwt.role !== 'class_teacher') ||
    loginData.user?.role !== 'teacher'
  ) {
    console.error('❌ FAIL: Teacher login failed or role invalid!');
    process.exit(1);
  }

  console.log('🎉 ✅ PASS: Teacher login succeeded with HTTP 200 & role="teacher"!');

  // Step 5: Test Existing DB Teacher "nizar" Login
  console.log('\n--- Step 5: Test Existing Teacher "nizar" Login ---');
  const nizarLoginRes = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: 'nizar',
      password: 'Ham@cls2', // Assigned to Class 2
    }),
  });
  const nizarData = await nizarLoginRes.json();
  console.log('Nizar login status:', nizarLoginRes.status);
  console.log('Nizar login response:', JSON.stringify(nizarData, null, 2));

  if (nizarLoginRes.status !== 200 || !nizarData.token) {
    console.error('❌ FAIL: Login failed for existing teacher "nizar"');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Teacher "nizar" logged in successfully with password "Ham@cls2"!');

  // Step 6: Cleanup
  console.log('\n--- Step 6: Cleanup ---');
  await fetch(`${URL}/teachers/${createdTeacher.id}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  console.log('✅ Cleaned up test teacher.');

  console.log('\n====================================================');
  console.log('🎉 ALL TEACHER AUTHENTICATION FLOW TESTS PASSED!');
  console.log('====================================================\n');
}

testTeacherAuthFlow().catch((err) => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
