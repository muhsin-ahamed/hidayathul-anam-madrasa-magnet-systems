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

async function runAudit() {
  console.log('================================================================');
  console.log('=== COMPLETE TEACHER PORTAL & ENDPOINTS AUDIT ===');
  console.log('================================================================\n');

  console.log('1. Logging in as Super Admin (sadar)...');
  const adminToken = await login('sadar', 'Ham@9345');

  console.log('2. Logging in as Class Teacher (teacher_math)...');
  const teacherToken = await login('teacher_math', 'Ham@cls1');

  console.log('3. Logging in as Student (ADM2026)...');
  const studentToken = await login('ADM2026', 'ADM2026');

  const adminHeader = { Authorization: `Bearer ${adminToken}` };
  const teacherHeader = { Authorization: `Bearer ${teacherToken}` };
  const studentHeader = { Authorization: `Bearer ${studentToken}` };

  const roles = {
    'Super Admin': adminHeader,
    'Class Teacher': teacherHeader,
    'Student': studentHeader,
  };

  const endpoints = [
    { name: 'GET /api/dashboard', path: '/dashboard' },
    { name: 'GET /api/teacher/dashboard', path: '/teacher/dashboard' },
    { name: 'GET /api/student/dashboard', path: '/student/dashboard' },
    { name: 'GET /api/activity-logs', path: '/activity-logs' },
    { name: 'GET /api/results', path: '/results' },
    { name: 'GET /api/notes', path: '/notes' },
    { name: 'GET /api/hall-tickets', path: '/hall-tickets' },
    { name: 'GET /api/exams', path: '/exams' },
    { name: 'GET /api/subjects', path: '/subjects' },
  ];

  let totalTests = 0;
  let passedTests = 0;

  for (const ep of endpoints) {
    console.log(`\n--- Testing ${ep.name} ---`);
    for (const [roleName, header] of Object.entries(roles)) {
      if (roleName === 'Student' && (ep.path === '/teacher/dashboard' || ep.path === '/activity-logs')) {
        continue;
      }
      if ((roleName === 'Super Admin' || roleName === 'Class Teacher') && ep.path === '/student/dashboard') {
        continue;
      }

      totalTests++;
      const res = await fetch(`${URL}${ep.path}`, { headers: header });
      const contentType = res.headers.get('content-type') || '';
      let body;
      try {
        body = await res.json();
      } catch (err) {
        console.error(`❌ FAIL: [${roleName}] ${ep.name} returned non-JSON content! Content-Type: ${contentType}`);
        continue;
      }

      console.log(`[${roleName}] Status: ${res.status}, Success: ${body.success}, Data type: ${Array.isArray(body.data) ? 'Array' : typeof body.data}`);

      if (res.status === 200 && body.success === true && contentType.includes('application/json')) {
        passedTests++;
      } else {
        console.error(`❌ FAIL: [${roleName}] ${ep.name} failed! Status: ${res.status}, Body: ${JSON.stringify(body)}`);
      }
    }
  }

  console.log('\n================================================================');
  console.log(`AUDIT SUMMARY: ${passedTests} / ${totalTests} ENDPOINTS PASSED (HTTP 200 & VALID JSON)`);
  console.log('================================================================\n');

  if (passedTests !== totalTests) {
    console.error('❌ Audit failed: Some endpoints did not return HTTP 200 OK or valid JSON!');
    process.exit(1);
  }
}

runAudit().catch(err => {
  console.error('Audit execution error:', err);
  process.exit(1);
});
