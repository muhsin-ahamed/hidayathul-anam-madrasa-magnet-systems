const URL = `http://localhost:5000/api`;

async function login(username, password) {
  const res = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  const data = await res.json();
  if (res.status !== 200 || !data.token) {
    throw new Error(`Login failed for ${username}: ${JSON.stringify(data)}`);
  }
  return data.token;
}

async function testEndpoint(roleName, token, endpoint) {
  const res = await fetch(`${URL}${endpoint}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const body = await res.json();
  console.log(`[${roleName}] GET ${endpoint} -> Status: ${res.status}, Success: ${body.success}, Data isArray: ${Array.isArray(body.data)} (length: ${Array.isArray(body.data) ? body.data.length : 'N/A'})`);
  
  if (res.status !== 200 || body.success !== true || !Array.isArray(body.data)) {
    console.error(`❌ FAIL: [${roleName}] GET ${endpoint} returned invalid response:`, body);
    process.exit(1);
  }
}

async function runTests() {
  console.log('================================================================');
  console.log('=== VERIFYING RESULTS, NOTES, HALL-TICKETS FOR ALL ROLES ===');
  console.log('================================================================\n');

  console.log('Logging in as Super Admin (sadar)...');
  const adminToken = await login('sadar', 'Ham@9345');

  console.log('Logging in as Teacher (teacher_math)...');
  const teacherToken = await login('teacher_math', 'Ham@cls1');

  console.log('Logging in as Student (ADM2026)...');
  const studentToken = await login('ADM2026', 'ADM2026');

  console.log('\n--- 1. Testing Super Admin Endpoints ---');
  await testEndpoint('Super Admin', adminToken, '/results');
  await testEndpoint('Super Admin', adminToken, '/results/student');
  await testEndpoint('Super Admin', adminToken, '/results/teacher');

  await testEndpoint('Super Admin', adminToken, '/notes');
  await testEndpoint('Super Admin', adminToken, '/notes/student');
  await testEndpoint('Super Admin', adminToken, '/notes/teacher');

  await testEndpoint('Super Admin', adminToken, '/hall-tickets');
  await testEndpoint('Super Admin', adminToken, '/hall-tickets/student');
  await testEndpoint('Super Admin', adminToken, '/hall-tickets/teacher');

  console.log('\n--- 2. Testing Teacher Endpoints ---');
  await testEndpoint('Teacher', teacherToken, '/results');
  await testEndpoint('Teacher', teacherToken, '/results/student');
  await testEndpoint('Teacher', teacherToken, '/results/teacher');

  await testEndpoint('Teacher', teacherToken, '/notes');
  await testEndpoint('Teacher', teacherToken, '/notes/student');
  await testEndpoint('Teacher', teacherToken, '/notes/teacher');

  await testEndpoint('Teacher', teacherToken, '/hall-tickets');
  await testEndpoint('Teacher', teacherToken, '/hall-tickets/student');
  await testEndpoint('Teacher', teacherToken, '/hall-tickets/teacher');

  console.log('\n--- 3. Testing Student Endpoints ---');
  await testEndpoint('Student', studentToken, '/results');
  await testEndpoint('Student', studentToken, '/results/student');

  await testEndpoint('Student', studentToken, '/notes');
  await testEndpoint('Student', studentToken, '/notes/student');

  await testEndpoint('Student', studentToken, '/hall-tickets');
  await testEndpoint('Student', studentToken, '/hall-tickets/student');

  console.log('\n================================================================');
  console.log('🎉 ALL ENDPOINTS RETURNED HTTP 200 OK WITH EMPTY ARRAYS / DATA!');
  console.log('================================================================\n');
}

runTests().catch((err) => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
