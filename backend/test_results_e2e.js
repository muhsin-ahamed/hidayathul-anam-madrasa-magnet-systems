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

async function testResultsE2E() {
  console.log('=== RESULTS MODULE E2E BACKEND TEST ===');

  const token = await login('teacher_math', 'Ham@cls1');
  const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

  console.log('\n1. GET /api/teacher/dashboard (to get teacher classId)');
  const dashRes = await fetch(`${URL}/teacher/dashboard`, { headers });
  const dashData = await dashRes.json();
  const classId = dashData.data?.teacher?.assignedClassId;
  console.log('Assigned Class ID:', classId);

  console.log('\n2. GET /api/students?classId=' + classId);
  const studRes = await fetch(`${URL}/students?classId=${classId}`, { headers });
  const studData = await studRes.json();
  const student = studData.data?.[0];
  console.log('Sample Student:', student?.full_name, student?.id);

  console.log('\n3. GET /api/subjects?classId=' + classId);
  const subRes = await fetch(`${URL}/subjects?classId=${classId}`, { headers });
  const subData = await subRes.json();
  const subject = subData.data?.[0];
  console.log('Sample Subject:', subject?.subject_name, subject?.id);

  console.log('\n4. GET /api/exams?classId=' + classId);
  const examRes = await fetch(`${URL}/exams?classId=${classId}`, { headers });
  const examData = await examRes.json();
  const exam = examData.data?.[0];
  console.log('Sample Exam:', exam?.exam_name, exam?.id);

  if (!student || !subject || !exam) {
    throw new Error('Prerequisites missing: student, subject, or exam');
  }

  console.log('\n5. POST /api/results (Create Result)');
  const createPayload = {
    exam_id: exam.id,
    student_id: student.id,
    subject_id: subject.id,
    marks_obtained: 85,
    maximum_marks: 100,
    grade: 'A',
    result_status: 'Pass',
    remarks: 'E2E Test Result',
    is_published: true,
  };
  const createRes = await fetch(`${URL}/results`, {
    method: 'POST',
    headers,
    body: JSON.stringify(createPayload),
  });
  const createResultData = await createRes.json();
  console.log('POST /api/results status:', createRes.status, createResultData);
  const createdResultId = createResultData.data?.id;

  console.log('\n6. GET /api/results?classId=' + classId);
  const getRes = await fetch(`${URL}/results?classId=${classId}`, { headers });
  const getData = await getRes.json();
  console.log('GET /api/results count:', getData.data?.length);

  if (createdResultId) {
    console.log('\n7. PUT /api/results/' + createdResultId);
    const updateRes = await fetch(`${URL}/results/${createdResultId}`, {
      method: 'PUT',
      headers,
      body: JSON.stringify({ ...createPayload, marks_obtained: 95, grade: 'A+' }),
    });
    console.log('PUT status:', updateRes.status, await updateRes.json());

    console.log('\n8. DELETE /api/results/' + createdResultId);
    const delRes = await fetch(`${URL}/results/${createdResultId}`, {
      method: 'DELETE',
      headers,
    });
    console.log('DELETE status:', delRes.status, await delRes.json());
  }

  console.log('\n=== RESULTS E2E BACKEND TEST COMPLETE ===');
}

testResultsE2E().catch(console.error);
