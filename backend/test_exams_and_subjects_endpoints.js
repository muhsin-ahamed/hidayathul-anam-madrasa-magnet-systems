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

async function runTests() {
  console.log('================================================================');
  console.log('=== VERIFYING EXAMS & SUBJECTS ENDPOINTS FOR ALL ROLES ===');
  console.log('================================================================\n');

  console.log('Logging in as Super Admin (sadar)...');
  const adminToken = await login('sadar', 'Ham@9345');

  console.log('Logging in as Teacher (teacher_math)...');
  const teacherToken = await login('teacher_math', 'Ham@cls1');

  console.log('Logging in as Student (ADM2026)...');
  const studentToken = await login('ADM2026', 'ADM2026');

  const adminHeader = { Authorization: `Bearer ${adminToken}` };
  const teacherHeader = { Authorization: `Bearer ${teacherToken}` };
  const studentHeader = { Authorization: `Bearer ${studentToken}` };

  // Fetch a valid classId
  const classesRes = await fetch(`${URL}/classes`, { headers: adminHeader });
  const classes = (await classesRes.json()).data;
  const testClass = classes[0];
  const classId = testClass.id;

  console.log(`Using classId: ${classId} (${testClass.class_name})\n`);

  // 1. GET /api/exams?classId=...
  console.log('--- Step 1: GET /api/exams?classId=... ---');
  for (const [role, header] of Object.entries({ 'Super Admin': adminHeader, Teacher: teacherHeader, Student: studentHeader })) {
    const res = await fetch(`${URL}/exams?classId=${classId}`, { headers: header });
    const body = await res.json();
    console.log(`[${role}] GET /exams?classId -> Status: ${res.status}, Success: ${body.success}, Data isArray: ${Array.isArray(body.data)}`);
    if (res.status !== 200 || !Array.isArray(body.data)) {
      console.error(`❌ FAIL: [${role}] GET /exams?classId returned invalid response`);
      process.exit(1);
    }
  }
  console.log('🎉 ✅ PASS: GET /api/exams?classId=... returned HTTP 200 array for all roles!\n');

  // 2. GET /api/subjects?classId=...
  console.log('--- Step 2: GET /api/subjects?classId=... ---');
  for (const [role, header] of Object.entries({ 'Super Admin': adminHeader, Teacher: teacherHeader, Student: studentHeader })) {
    const res = await fetch(`${URL}/subjects?classId=${classId}`, { headers: header });
    const body = await res.json();
    console.log(`[${role}] GET /subjects?classId -> Status: ${res.status}, Success: ${body.success}, Data isArray: ${Array.isArray(body.data)}`);
    if (res.status !== 200 || !Array.isArray(body.data)) {
      console.error(`❌ FAIL: [${role}] GET /subjects?classId returned invalid response`);
      process.exit(1);
    }
  }
  console.log('🎉 ✅ PASS: GET /api/subjects?classId=... returned HTTP 200 array for all roles!\n');

  // 3. Create & Fetch Exam & Subject as Teacher
  console.log('--- Step 3: Create & Fetch Exam & Subject ---');
  const createSubRes = await fetch(`${URL}/subjects`, {
    method: 'POST',
    headers: { ...teacherHeader, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      subject_name: `Mathematics Test ${Date.now()}`,
      subject_code: 'MATH101',
      class_id: classId,
    }),
  });
  const createdSub = (await createSubRes.json()).data;
  console.log('Created Subject:', createdSub.id, createdSub.subject_name);

  const getSubRes = await fetch(`${URL}/subjects/${createdSub.id}`, { headers: studentHeader });
  const getSubData = await getSubRes.json();
  console.log('GET /subjects/:id Status:', getSubRes.status, 'Subject Name:', getSubData.data?.subjectName);
  if (getSubRes.status !== 200 || !getSubData.data) {
    console.error('❌ FAIL: GET /subjects/:id failed');
    process.exit(1);
  }

  const createExamRes = await fetch(`${URL}/exams`, {
    method: 'POST',
    headers: { ...teacherHeader, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      exam_name: `Midterm Exam ${Date.now()}`,
      term: 'Term 1',
      class_id: classId,
    }),
  });
  const createdExam = (await createExamRes.json()).data;
  console.log('Created Exam:', createdExam.id, createdExam.exam_name);

  const getExamRes = await fetch(`${URL}/exams/${createdExam.id}`, { headers: studentHeader });
  const getExamData = await getExamRes.json();
  console.log('GET /exams/:id Status:', getExamRes.status, 'Exam Name:', getExamData.data?.examName);
  if (getExamRes.status !== 200 || !getExamData.data) {
    console.error('❌ FAIL: GET /exams/:id failed');
    process.exit(1);
  }

  // Clean up created test exam & subject
  await fetch(`${URL}/exams/${createdExam.id}`, { method: 'DELETE', headers: teacherHeader });
  await fetch(`${URL}/subjects/${createdSub.id}`, { method: 'DELETE', headers: teacherHeader });
  console.log('✅ Cleaned up test exam & subject.');

  console.log('================================================================');
  console.log('🎉 ALL EXAMS & SUBJECTS ENDPOINTS VERIFIED WITH HTTP 200!');
  console.log('================================================================\n');
}

runTests().catch((err) => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
