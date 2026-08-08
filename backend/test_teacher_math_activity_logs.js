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

async function testTeacherMathActivityLogs() {
  console.log('================================================================');
  console.log('=== VERIFYING TEACHER_MATH ACTIVITY LOGS & ALL ENDPOINTS ===');
  console.log('================================================================\n');

  // Step 1: Login with teacher_math
  console.log('--- Step 1: Login with teacher_math (password: Ham@cls1) ---');
  const loginRes = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: 'teacher_math',
      password: 'Ham@cls1',
    }),
  });

  const loginData = await loginRes.json();
  console.log('Login Status:', loginRes.status);
  console.log('Login Response:', JSON.stringify(loginData, null, 2));

  const token = loginData.token || loginData.data?.token;
  const jwt = parseJwt(token);
  console.log('Decoded JWT:', jwt);

  if (loginRes.status !== 200 || !token || jwt.role !== 'class_teacher') {
    console.error('❌ FAIL: Login failed for teacher_math!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: teacher_math logged in successfully!\n');

  const authHeader = { Authorization: `Bearer ${token}` };

  // Step 2: Get Profile & Assigned Class ID
  console.log('--- Step 2: Fetch Teacher Profile & Assigned Class ID ---');
  const profileRes = await fetch(`${URL}/teacher/profile`, { headers: authHeader });
  const profileData = await profileRes.json();
  console.log('Profile Status:', profileRes.status);
  const assignedClassId = profileData.assignedClassId || profileData.assignedClass?.id;
  console.log('Assigned Class ID:', assignedClassId, 'Class Name:', profileData.assignedClassName);

  if (profileRes.status !== 200 || !assignedClassId) {
    console.error('❌ FAIL: Profile or assignedClassId missing!');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Profile & assigned class ID retrieved successfully!\n');

  // Step 3: GET /api/activity-logs?classId={assignedClassId}
  console.log(`--- Step 3: GET /api/activity-logs?classId=${assignedClassId} ---`);
  const logsRes = await fetch(`${URL}/activity-logs?classId=${assignedClassId}`, { headers: authHeader });
  const logsData = await logsRes.json();
  console.log('Activity Logs Status:', logsRes.status);
  console.log('Activity Logs Response:', JSON.stringify(logsData, null, 2));

  if (logsRes.status !== 200 || !Array.isArray(logsData.data)) {
    console.error('❌ FAIL: Activity logs failed with status ' + logsRes.status);
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Activity logs returned HTTP 200 successfully!\n');

  // Step 4: GET /api/dashboard
  console.log('--- Step 4: GET /api/dashboard ---');
  const dashRes = await fetch(`${URL}/dashboard`, { headers: authHeader });
  const dashData = await dashRes.json();
  console.log('Dashboard Status:', dashRes.status);

  if (dashRes.status !== 200) {
    console.error('❌ FAIL: Dashboard failed with status ' + dashRes.status);
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Dashboard returned HTTP 200!\n');

  // Step 5: GET /api/results
  console.log('--- Step 5: GET /api/results ---');
  const resultsRes = await fetch(`${URL}/results`, { headers: authHeader });
  console.log('Results Status:', resultsRes.status);

  if (resultsRes.status !== 200) {
    console.error('❌ FAIL: Results failed with status ' + resultsRes.status);
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Results returned HTTP 200!\n');

  // Step 6: GET /api/notes
  console.log('--- Step 6: GET /api/notes ---');
  const notesRes = await fetch(`${URL}/notes`, { headers: authHeader });
  console.log('Notes Status:', notesRes.status);

  if (notesRes.status !== 200) {
    console.error('❌ FAIL: Notes failed with status ' + notesRes.status);
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Notes returned HTTP 200!\n');

  // Step 7: GET /api/hall-tickets
  console.log('--- Step 7: GET /api/hall-tickets ---');
  const ticketsRes = await fetch(`${URL}/hall-tickets`, { headers: authHeader });
  console.log('Hall Tickets Status:', ticketsRes.status);

  if (ticketsRes.status !== 200) {
    console.error('❌ FAIL: Hall tickets failed with status ' + ticketsRes.status);
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Hall tickets returned HTTP 200!\n');

  console.log('================================================================');
  console.log('🎉 ALL ENDPOINTS RETURNED HTTP 200 FOR TEACHER_MATH PERFECTLY!');
  console.log('================================================================\n');
}

testTeacherMathActivityLogs().catch((err) => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
