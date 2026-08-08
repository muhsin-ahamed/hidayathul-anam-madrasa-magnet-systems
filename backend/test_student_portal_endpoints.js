const URL = `http://localhost:5000/api`;

async function fetchJSON(path, token) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  try {
    const res = await fetch(`${URL}${path}`, { method: 'GET', headers });
    const json = await res.json().catch((err) => ({ parseError: err.message }));
    return { status: res.status, data: json };
  } catch (e) {
    return { status: 500, error: e.message };
  }
}

async function runStudentPortalEndpointTests() {
  console.log('================================================================');
  console.log('=== VERIFYING ALL STUDENT PORTAL API ENDPOINTS (/api/student/*) ===');
  console.log('================================================================\n');

  // 1. Log in as Super Admin to get a class and create a test student
  const adminLoginRes = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'sadar', password: 'Ham@9345' }),
  });
  const adminData = await adminLoginRes.json();
  const adminToken = adminData.data?.token || adminData.token;

  const classesRes = await fetch(`${URL}/classes`, {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  const classesData = await classesRes.json();
  const testClass = classesData.data[0];

  const sAdm = `ADM_PORTAL_${Date.now()}`;
  const createStudentRes = await fetch(`${URL}/students`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      admission_number: sAdm,
      roll_number: '888',
      full_name: 'Portal Test Student',
      class_id: testClass.id,
    }),
  });
  const createdStudent = (await createStudentRes.json()).data;

  // 2. Student Login
  const studentLoginRes = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: sAdm, password: sAdm }),
  });
  const studentData = await studentLoginRes.json();
  const studentToken = studentData.data?.token || studentData.token;

  console.log('Student Token acquired for student admission number:', sAdm, '\n');

  // 3. Test Endpoint 1: GET /api/student/dashboard
  console.log('--- Endpoint 1: GET /api/student/dashboard ---');
  const dashRes = await fetchJSON('/student/dashboard', studentToken);
  console.log('Dashboard status:', dashRes.status);
  console.log('Dashboard response:', JSON.stringify(dashRes.data, null, 2));

  if (dashRes.status !== 200 || !dashRes.data?.data?.student || !dashRes.data?.data?.summary) {
    console.error('❌ FAIL: /api/student/dashboard did not return 200 or valid dashboard schema');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: GET /api/student/dashboard returned HTTP 200 with valid schema!\n');

  // 4. Test Endpoint 2: GET /api/student/profile
  console.log('--- Endpoint 2: GET /api/student/profile ---');
  const profRes = await fetchJSON('/student/profile', studentToken);
  console.log('Profile status:', profRes.status);
  console.log('Profile response:', JSON.stringify(profRes.data, null, 2));

  if (profRes.status !== 200 || !profRes.data?.data?.fullName) {
    console.error('❌ FAIL: /api/student/profile did not return 200 or valid profile schema');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: GET /api/student/profile returned HTTP 200 with valid schema!\n');

  // 5. Test Endpoint 3: GET /api/student/results
  console.log('--- Endpoint 3: GET /api/student/results ---');
  const resRes = await fetchJSON('/student/results', studentToken);
  console.log('Results status:', resRes.status);
  console.log('Results response:', JSON.stringify(resRes.data, null, 2));

  if (resRes.status !== 200 || !Array.isArray(resRes.data?.results ?? resRes.data?.data)) {
    console.error('❌ FAIL: /api/student/results did not return 200 or valid results array');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: GET /api/student/results returned HTTP 200 with empty array (no 404)!\n');

  // 6. Test Endpoint 4: GET /api/student/notes
  console.log('--- Endpoint 4: GET /api/student/notes ---');
  const notesRes = await fetchJSON('/student/notes', studentToken);
  console.log('Notes status:', notesRes.status);
  console.log('Notes response:', JSON.stringify(notesRes.data, null, 2));

  if (notesRes.status !== 200 || !Array.isArray(notesRes.data?.notes ?? notesRes.data?.data)) {
    console.error('❌ FAIL: /api/student/notes did not return 200 or valid notes array');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: GET /api/student/notes returned HTTP 200 with empty array (no 404)!\n');

  // 7. Test Endpoint 5: GET /api/student/hall-ticket
  console.log('--- Endpoint 5: GET /api/student/hall-ticket ---');
  const htRes = await fetchJSON('/student/hall-ticket', studentToken);
  console.log('Hall Ticket status:', htRes.status);
  console.log('Hall Ticket response:', JSON.stringify(htRes.data, null, 2));

  if (htRes.status !== 200) {
    console.error('❌ FAIL: /api/student/hall-ticket did not return HTTP 200');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: GET /api/student/hall-ticket returned HTTP 200 with null/empty state (no 404)!\n');

  // 8. Cleanup test student
  await fetch(`${URL}/students/${createdStudent.id}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  console.log('✅ Cleaned up test student record.');

  console.log('\n================================================================');
  console.log('🎉 ALL 5 STUDENT PORTAL ENDPOINTS VERIFIED & PASSED WITH HTTP 200!');
  console.log('================================================================\n');
}

runStudentPortalEndpointTests().catch(err => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
