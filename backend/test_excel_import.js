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

async function runTest() {
  console.log('================================================================');
  console.log('=== TEST EXCEL / BULK RESULTS IMPORT & AUTHORIZATION ===');
  console.log('================================================================\n');

  console.log('1. Logging in as Class Teacher (teacher_math)...');
  const teacherToken = await login('teacher_math', 'Ham@cls1');
  const teacherHeader = {
    Authorization: `Bearer ${teacherToken}`,
    'Content-Type': 'application/json',
  };

  console.log('2. Fetching Class Teacher assigned students, exams, and subjects...');
  const studentsRes = await fetch(`${URL}/teacher/students`, { headers: teacherHeader });
  const studentsData = await studentsRes.json();
  const student = studentsData.data?.[0];

  const examsRes = await fetch(`${URL}/exams`, { headers: teacherHeader });
  const examsData = await examsRes.json();
  const exam = examsData.data?.[0];

  const subjectsRes = await fetch(`${URL}/subjects`, { headers: teacherHeader });
  const subjectsData = await subjectsRes.json();
  const subject = subjectsData.data?.[0];

  if (!student || !exam || !subject) {
    console.error('❌ Cannot run import test: Missing student, exam, or subject data');
    console.log(`Student: ${!!student}, Exam: ${!!exam}, Subject: ${!!subject}`);
    process.exit(1);
  }

  console.log(`Testing with Student: ${student.full_name} (${student.admission_number}), Exam: ${exam.exam_name}, Subject: ${subject.subject_name}`);

  console.log('\n3. Testing POST /api/results/import with valid & invalid JSON rows...');
  const payload = {
    results: [
      {
        'Admission Number': student.admission_number,
        'Student Name': student.full_name,
        'Subject': subject.subject_name,
        'Exam': exam.exam_name,
        'Marks': 88,
        'Total Marks': 100,
        'Remarks': 'Excellent performance in Excel import test',
      },
      {
        'Admission Number': student.admission_number,
        'Student Name': student.full_name,
        'Subject': subject.subject_name,
        'Exam': exam.exam_name,
        'Marks': 150,
        'Total Marks': 100, // Invalid marks > total
        'Remarks': 'Should fail validation',
      },
      {
        'Admission Number': 'INVALID_ADM_9999',
        'Student Name': 'Fake Student',
        'Subject': subject.subject_name,
        'Exam': exam.exam_name,
        'Marks': 75,
        'Total Marks': 100, // Invalid student
      }
    ]
  };

  const importRes = await fetch(`${URL}/results/import`, {
    method: 'POST',
    headers: teacherHeader,
    body: JSON.stringify(payload),
  });

  const importData = await importRes.json();
  console.log(`Status Code: ${importRes.status}`);
  console.log(`Message: ${importData.message}`);
  console.log(`Imported Count: ${importData.importedCount}`);
  console.log(`Skipped Count: ${importData.skippedCount}`);
  console.log(`Errors: ${JSON.stringify(importData.errors)}`);

  if (importRes.status === 200 && importData.importedCount === 1 && importData.skippedCount === 2) {
    console.log('✔ POST /api/results/import passed row-level validation & import!');
  } else {
    console.error('❌ POST /api/results/import failed expected validation outcome!');
    process.exit(1);
  }

  console.log('\n4. Verifying imported result via GET /api/results...');
  const resultsRes = await fetch(`${URL}/results`, { headers: teacherHeader });
  const resultsData = await resultsRes.json();
  console.log(`Results Returned: ${resultsData.data?.length}`);

  const importedItem = resultsData.data?.find(r => r.student_id === student.id && r.subject_id === subject.id && r.exam_id === exam.id);
  if (importedItem) {
    console.log(`✔ Verified imported result: ID=${importedItem.id}, Marks=${importedItem.marks_obtained}/${importedItem.maximum_marks}, Grade=${importedItem.grade}`);
  } else {
    console.error('❌ Imported result not found in GET /api/results');
    process.exit(1);
  }

  console.log('\n================================================================');
  console.log('ALL IMPORT & RESULT MODULE TESTS PASSED SUCCESSFULLY!');
  console.log('================================================================\n');
}

runTest().catch(err => {
  console.error('Test execution error:', err);
  process.exit(1);
});
