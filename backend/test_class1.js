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

async function testTeacherClass1() {
  console.log('1. Logging in as Class Teacher teacher_math...');
  const token = await login('teacher_math', 'Ham@cls1');
  const headers = { Authorization: `Bearer ${token}` };

  console.log('2. Fetching dashboard profile...');
  const dashRes = await fetch(`${URL}/teacher/dashboard`, { headers });
  const dashData = await dashRes.json();
  console.log('Teacher Dashboard:', JSON.stringify(dashData));

  const classId = dashData.data?.teacher?.assignedClassId;
  console.log('Assigned Class ID:', classId);

  console.log('\n3. Fetching Students...');
  const studRes = await fetch(`${URL}/students?classId=${classId}`, { headers });
  console.log('Students status:', studRes.status, await studRes.json());

  console.log('\n4. Fetching Subjects...');
  const subRes = await fetch(`${URL}/subjects?classId=${classId}`, { headers });
  console.log('Subjects status:', subRes.status, await subRes.json());

  console.log('\n5. Fetching Exams...');
  const examRes = await fetch(`${URL}/exams?classId=${classId}`, { headers });
  console.log('Exams status:', examRes.status, await examRes.json());

  console.log('\n6. Fetching Results...');
  const resRes = await fetch(`${URL}/results?classId=${classId}`, { headers });
  console.log('Results status:', resRes.status, await resRes.json());
}

testTeacherClass1().catch(console.error);
