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

async function testCompleteTeacherAuthorization() {
  console.log('================================================================');
  console.log('=== VERIFYING COMPLETE TEACHER AUTHORIZATION & DASHBOARD FLOW ===');
  console.log('================================================================\n');

  // Step 1: Teacher Login
  console.log('--- Step 1: Login ---');
  const loginRes = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: 'nizar',
      password: 'Ham@cls2',
    }),
  });

  const loginData = await loginRes.json();
  console.log('Login HTTP Status:', loginRes.status);
  console.log('Login Response:', JSON.stringify(loginData, null, 2));

  const token = loginData.token || loginData.data?.token;
  const jwt = parseJwt(token);

  console.log('\n--- Step 2: JWT Created ---');
  console.log('Decoded JWT:', jwt);

  if (loginRes.status !== 200 || !token || jwt.role !== 'class_teacher') {
    console.error('❌ FAIL: Teacher login failed or role mismatch in JWT!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Teacher logged in & JWT role is class_teacher!\n');

  const authHeader = { Authorization: `Bearer ${token}` };

  // Step 3: Dashboard opens (/api/teacher/dashboard and /api/dashboard)
  console.log('--- Step 3: Dashboard Opens ---');
  const teacherDashRes = await fetch(`${URL}/teacher/dashboard`, { headers: authHeader });
  const teacherDashData = await teacherDashRes.json();
  console.log('GET /api/teacher/dashboard Status:', teacherDashRes.status);

  const mainDashRes = await fetch(`${URL}/dashboard`, { headers: authHeader });
  const mainDashData = await mainDashRes.json();
  console.log('GET /api/dashboard Status:', mainDashRes.status);

  if (teacherDashRes.status !== 200 || mainDashRes.status !== 200) {
    console.error('❌ FAIL: Dashboard endpoint failed with authorization error!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Dashboard endpoints authorized & loaded successfully!\n');

  // Step 4: Students page opens (/api/teacher/students)
  console.log('--- Step 4: Students Page Opens ---');
  const studentsRes = await fetch(`${URL}/teacher/students`, { headers: authHeader });
  const studentsData = await studentsRes.json();
  console.log('GET /api/teacher/students Status:', studentsRes.status);

  if (studentsRes.status !== 200) {
    console.error('❌ FAIL: Students endpoint returned status ' + studentsRes.status);
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Students endpoint authorized & loaded successfully!\n');

  // Step 5: Results page opens (/api/results and /api/teacher/results)
  console.log('--- Step 5: Results Page Opens ---');
  const resultsRes = await fetch(`${URL}/results`, { headers: authHeader });
  const resultsData = await resultsRes.json();
  console.log('GET /api/results Status:', resultsRes.status);

  if (resultsRes.status !== 200) {
    console.error('❌ FAIL: Results endpoint returned status ' + resultsRes.status);
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Results endpoint authorized & loaded successfully!\n');

  // Step 6: Notes page opens (/api/notes and /api/teacher/notes)
  console.log('--- Step 6: Notes Page Opens ---');
  const notesRes = await fetch(`${URL}/notes`, { headers: authHeader });
  const notesData = await notesRes.json();
  console.log('GET /api/notes Status:', notesRes.status);

  if (notesRes.status !== 200) {
    console.error('❌ FAIL: Notes endpoint returned status ' + notesRes.status);
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Notes endpoint authorized & loaded successfully!\n');

  // Step 7: Hall Tickets page opens (/api/hall-tickets and /api/teacher/hall-tickets)
  console.log('--- Step 7: Hall Tickets Page Opens ---');
  const ticketsRes = await fetch(`${URL}/hall-tickets`, { headers: authHeader });
  const ticketsData = await ticketsRes.json();
  console.log('GET /api/hall-tickets Status:', ticketsRes.status);

  if (ticketsRes.status !== 200) {
    console.error('❌ FAIL: Hall Tickets endpoint returned status ' + ticketsRes.status);
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Hall Tickets endpoint authorized & loaded successfully!\n');

  console.log('================================================================');
  console.log('🎉 TEACHER FLOW VERIFIED: NO "User role not authorized" ERRORS!');
  console.log('================================================================\n');
}

testCompleteTeacherAuthorization().catch((err) => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
