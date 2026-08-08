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
  console.log('=== VERIFYING COMPLETE RESULT MANAGEMENT MODULE & VALIDATIONS ===');
  console.log('================================================================\n');

  const adminToken = await login('sadar', 'Ham@9345');
  const teacherToken = await login('teacher_math', 'Ham@cls1');
  const studentToken = await login('ADM2026', 'ADM2026');

  const adminHeader = { Authorization: `Bearer ${adminToken}`, 'Content-Type': 'application/json' };
  const teacherHeader = { Authorization: `Bearer ${teacherToken}`, 'Content-Type': 'application/json' };
  const studentHeader = { Authorization: `Bearer ${studentToken}` };

  // Get Teacher Profile to find assigned class
  const teacherProfileRes = await fetch(`${URL}/teacher/profile`, { headers: teacherHeader });
  const teacherData = (await teacherProfileRes.json()).data;
  const teacherClassId = teacherData.assignedClass?.id || teacherData.assignedClassId;

  // Fetch Classes & Students
  const classesRes = await fetch(`${URL}/classes`, { headers: adminHeader });
  const classes = (await classesRes.json()).data;
  const assignedClass = classes.find(c => c.id === teacherClassId) || classes[0];
  const otherClass = classes.find(c => c.id !== assignedClass.id) || classes[1];

  const studentsRes = await fetch(`${URL}/students`, { headers: adminHeader });
  const allStudents = (await studentsRes.json()).data;
  const studentInAssignedClass = allStudents.find(s => s.class_id === assignedClass.id) || allStudents[0];
  const studentInOtherClass = allStudents.find(s => s.class_id === otherClass.id);

  // Fetch/Create Exam & Subject for Assigned Class
  let examRes = await fetch(`${URL}/exams?classId=${assignedClass.id}`, { headers: adminHeader });
  let exams = (await examRes.json()).data;
  let testExam = exams[0];
  if (!testExam) {
    const createExam = await fetch(`${URL}/exams`, {
      method: 'POST',
      headers: adminHeader,
      body: JSON.stringify({ exam_name: 'Midterm 2026', class_id: assignedClass.id }),
    });
    testExam = (await createExam.json()).data;
  }

  let subRes = await fetch(`${URL}/subjects?classId=${assignedClass.id}`, { headers: adminHeader });
  let subjects = (await subRes.json()).data;
  let testSub = subjects[0];
  if (!testSub) {
    const createSub = await fetch(`${URL}/subjects`, {
      method: 'POST',
      headers: adminHeader,
      body: JSON.stringify({ subject_name: 'Mathematics', class_id: assignedClass.id, maximum_marks: 100 }),
    });
    testSub = (await createSub.json()).data;
  }

  console.log(`Teacher Assigned Class: ${assignedClass.class_name} (${assignedClass.id})`);
  console.log(`Student in Assigned Class: ${studentInAssignedClass.full_name} (${studentInAssignedClass.id})`);
  if (studentInOtherClass) console.log(`Student in Other Class: ${studentInOtherClass.full_name} (${studentInOtherClass.id})`);
  console.log(`Exam: ${testExam.exam_name} (${testExam.id})`);
  console.log(`Subject: ${testSub.subject_name} (${testSub.id})\n`);

  // Test 1: Marks > Maximum Marks Validation
  console.log('--- Test 1: Invalid Marks Validation (Marks > Total) ---');
  const invalidMarksRes = await fetch(`${URL}/results`, {
    method: 'POST',
    headers: teacherHeader,
    body: JSON.stringify({
      student_id: studentInAssignedClass.id,
      exam_id: testExam.id,
      subject_id: testSub.id,
      marks_obtained: 150,
      maximum_marks: 100,
    }),
  });
  console.log(`Status: ${invalidMarksRes.status}`);
  if (invalidMarksRes.status !== 400) {
    console.error('❌ FAIL: Expected HTTP 400 for marks > maximum_marks');
    process.exit(1);
  }
  console.log('🎉 ✅ PASS: Server correctly rejected invalid marks (150 > 100) with HTTP 400!\n');

  // Test 2: Teacher upload result for student in another class
  if (studentInOtherClass) {
    console.log('--- Test 2: Teacher Authorization (Uploading for another class) ---');
    const unauthorizedRes = await fetch(`${URL}/results`, {
      method: 'POST',
      headers: teacherHeader,
      body: JSON.stringify({
        student_id: studentInOtherClass.id,
        exam_id: testExam.id,
        subject_id: testSub.id,
        marks_obtained: 85,
        maximum_marks: 100,
      }),
    });
    console.log(`Status: ${unauthorizedRes.status}`);
    if (unauthorizedRes.status !== 403) {
      console.error('❌ FAIL: Expected HTTP 403 when teacher uploads result for another class');
      process.exit(1);
    }
    console.log('🎉 ✅ PASS: Server correctly denied teacher upload for another class with HTTP 403!\n');
  }

  // Test 3: Teacher uploads result for student in assigned class
  console.log('--- Test 3: Teacher Upload Result for Assigned Class ---');
  const teacherUploadRes = await fetch(`${URL}/results`, {
    method: 'POST',
    headers: teacherHeader,
    body: JSON.stringify({
      student_id: studentInAssignedClass.id,
      exam_id: testExam.id,
      subject_id: testSub.id,
      marks_obtained: 92,
      maximum_marks: 100,
      grade: 'A+',
      remarks: 'Excellent work',
      is_published: true,
    }),
  });
  const uploadedBody = await teacherUploadRes.json();
  console.log(`Status: ${teacherUploadRes.status}, Uploaded Result ID: ${uploadedBody.data?.id}`);
  if (teacherUploadRes.status !== 201 && teacherUploadRes.status !== 200) {
    console.error(`❌ FAIL: Teacher result upload failed: ${JSON.stringify(uploadedBody)}`);
    process.exit(1);
  }
  const uploadedResult = uploadedBody.data;
  console.log('🎉 ✅ PASS: Teacher successfully uploaded result for assigned class!\n');

  // Test 4: Super Admin Edit & View Results
  console.log('--- Test 4: Super Admin Edit & View Results ---');
  const editRes = await fetch(`${URL}/results/${uploadedResult.id}`, {
    method: 'PUT',
    headers: adminHeader,
    body: JSON.stringify({
      marks_obtained: 95,
      grade: 'A+',
      remarks: 'Top score',
      is_published: true,
    }),
  });
  console.log(`Edit Status: ${editRes.status}`);
  if (editRes.status !== 200) {
    console.error('❌ FAIL: Super Admin edit result failed');
    process.exit(1);
  }

  const allResultsRes = await fetch(`${URL}/results`, { headers: adminHeader });
  const allResults = (await allResultsRes.json()).data;
  console.log(`Super Admin GET /results count: ${allResults.length}`);

  // Test 5: Student view results
  console.log('--- Test 5: Student View Results ---');
  const studentResultsRes = await fetch(`${URL}/results`, { headers: studentHeader });
  const studentResultsData = await studentResultsRes.json();
  console.log(`Student GET /results status: ${studentResultsRes.status}, Data isArray: ${Array.isArray(studentResultsData.data)}`);
  if (studentResultsRes.status !== 200) {
    console.error('❌ FAIL: Student view results failed');
    process.exit(1);
  }

  // Cleanup created result
  await fetch(`${URL}/results/${uploadedResult.id}`, { method: 'DELETE', headers: adminHeader });
  console.log('✅ Cleaned up test result.');

  console.log('================================================================');
  console.log('🎉 ALL RESULT MANAGEMENT ENDPOINTS & VALIDATIONS PASSED!');
  console.log('================================================================\n');
}

runTests().catch((err) => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
