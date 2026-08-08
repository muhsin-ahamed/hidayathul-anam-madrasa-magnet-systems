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

async function testTeacherWorkspaceEndpoints() {
  console.log('================================================================');
  console.log('=== VERIFYING TEACHER WORKSPACE ENDPOINTS AND BUSINESS RULES ===');
  console.log('================================================================\n');

  // Step 1: Teacher Login
  console.log('--- Step 1: Teacher Login (nizar / Ham@cls2) ---');
  const loginRes = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: 'nizar',
      password: 'Ham@cls2',
    }),
  });

  const loginData = await loginRes.json();
  console.log('Login Status:', loginRes.status);
  console.log('Login Response:', JSON.stringify(loginData, null, 2));

  const token = loginData.token || loginData.data?.token;
  const jwt = parseJwt(token);

  console.log('Decoded JWT:', jwt);

  if (loginRes.status !== 200 || !token || jwt.role !== 'class_teacher') {
    console.error('❌ FAIL: Teacher login failed or role mismatch');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Teacher logged in & JWT role is class_teacher!\n');

  const authHeader = { Authorization: `Bearer ${token}` };

  // Step 2: GET /api/teacher/profile
  console.log('--- Step 2: GET /api/teacher/profile ---');
  const profileRes = await fetch(`${URL}/teacher/profile`, { headers: authHeader });
  const profileData = await profileRes.json();
  console.log('Profile Status:', profileRes.status);
  console.log('Profile Data:', JSON.stringify(profileData, null, 2));

  if (profileRes.status !== 200 || !profileData.assignedClass) {
    console.error('❌ FAIL: Profile API failed or missing assignedClass!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: GET /api/teacher/profile returned HTTP 200 with assigned class!\n');

  // Step 3: GET /api/teacher/dashboard
  console.log('--- Step 3: GET /api/teacher/dashboard ---');
  const dashboardRes = await fetch(`${URL}/teacher/dashboard`, { headers: authHeader });
  const dashboardData = await dashboardRes.json();
  console.log('Dashboard Status:', dashboardRes.status);
  console.log('Dashboard Data:', JSON.stringify(dashboardData, null, 2));

  if (dashboardRes.status !== 200 || dashboardData.studentCount === undefined || !Array.isArray(dashboardData.recentResults) || !Array.isArray(dashboardData.recentNotes)) {
    console.error('❌ FAIL: Dashboard API response invalid structure!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: GET /api/teacher/dashboard returned HTTP 200 with required structure!\n');

  // Step 4: GET /api/teacher/students
  console.log('--- Step 4: GET /api/teacher/students ---');
  const studentsRes = await fetch(`${URL}/teacher/students`, { headers: authHeader });
  const studentsData = await studentsRes.json();
  console.log('Students Status:', studentsRes.status);
  console.log('Students Count:', (studentsData.data || studentsData.students || []).length);

  if (studentsRes.status !== 200 || !Array.isArray(studentsData.data || studentsData.students)) {
    console.error('❌ FAIL: Students API returned invalid data!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: GET /api/teacher/students returned HTTP 200 array!\n');

  // Step 5: GET /api/teacher/results
  console.log('--- Step 5: GET /api/teacher/results ---');
  const resultsRes = await fetch(`${URL}/teacher/results`, { headers: authHeader });
  const resultsData = await resultsRes.json();
  console.log('Results Status:', resultsRes.status);
  console.log('Results Count:', (resultsData.data || resultsData.results || []).length);

  if (resultsRes.status !== 200 || !Array.isArray(resultsData.data || resultsData.results)) {
    console.error('❌ FAIL: Results API returned invalid data!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: GET /api/teacher/results returned HTTP 200 array!\n');

  // Step 6: GET /api/teacher/notes
  console.log('--- Step 6: GET /api/teacher/notes ---');
  const notesRes = await fetch(`${URL}/teacher/notes`, { headers: authHeader });
  const notesData = await notesRes.json();
  console.log('Notes Status:', notesRes.status);
  console.log('Notes Count:', (notesData.data || notesData.notes || []).length);

  if (notesRes.status !== 200 || !Array.isArray(notesData.data || notesData.notes)) {
    console.error('❌ FAIL: Notes API returned invalid data!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: GET /api/teacher/notes returned HTTP 200 array!\n');

  // Step 7: GET /api/teacher/hall-tickets
  console.log('--- Step 7: GET /api/teacher/hall-tickets ---');
  const ticketsRes = await fetch(`${URL}/teacher/hall-tickets`, { headers: authHeader });
  const ticketsData = await ticketsRes.json();
  console.log('Hall Tickets Status:', ticketsRes.status);
  console.log('Hall Tickets Count:', (ticketsData.data || ticketsData.hallTickets || []).length);

  if (ticketsRes.status !== 200 || !Array.isArray(ticketsData.data || ticketsData.hallTickets)) {
    console.error('❌ FAIL: Hall Tickets API returned invalid data!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: GET /api/teacher/hall-tickets returned HTTP 200 array!\n');

  console.log('================================================================');
  console.log('🎉 ALL TEACHER WORKSPACE ENDPOINTS RETURNED HTTP 200 PERFECTLY!');
  console.log('================================================================\n');
}

testTeacherWorkspaceEndpoints().catch((err) => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
