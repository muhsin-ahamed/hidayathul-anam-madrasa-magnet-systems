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

async function testAddStudent() {
  console.log('================================================================');
  console.log('=== TEST TEACHER ADD STUDENT MODULE & CLASS ASSIGNMENT ===');
  console.log('================================================================\n');

  console.log('1. Logging in as Class Teacher (teacher_math)...');
  const teacherToken = await login('teacher_math', 'Ham@cls1');
  const teacherHeader = {
    Authorization: `Bearer ${teacherToken}`,
    'Content-Type': 'application/json',
  };

  console.log('2. Fetching Class Teacher assigned class & existing students...');
  const studentsRes = await fetch(`${URL}/teacher/students`, { headers: teacherHeader });
  const studentsData = await studentsRes.json();
  console.log(`Initial Student Count: ${studentsData.data?.length}`);

  const existingStudent = studentsData.data?.[0];
  const classId = existingStudent?.class_id;

  if (!classId) {
    console.error('❌ Cannot run test: Teacher has no assigned class_id in students');
    process.exit(1);
  }

  console.log(`Teacher Assigned Class ID: ${classId}`);

  const uniqueSuffix = Date.now().toString().slice(-4);
  const testAdmissionNo = `TESTADM${uniqueSuffix}`;
  const testRollNo = `R-${uniqueSuffix}`;
  const testName = `Auto Test Student ${uniqueSuffix}`;

  console.log(`\n3. Calling POST /api/students as Class Teacher for class_id ${classId}...`);
  const createRes = await fetch(`${URL}/students`, {
    method: 'POST',
    headers: teacherHeader,
    body: JSON.stringify({
      admission_number: testAdmissionNo,
      roll_number: testRollNo,
      full_name: testName,
      class_id: classId,
      guardian_name: 'Test Parent',
      guardian_phone: '+91 9876543210',
      address: '123 Test Street',
    }),
  });

  const createData = await createRes.json();
  console.log(`Response Status: ${createRes.status}`);
  console.log(`Success: ${createData.success}`);
  console.log(`Message: ${createData.message || 'Created'}`);

  if (createRes.status !== 200 && createRes.status !== 201) {
    console.error(`❌ Student creation failed: ${JSON.stringify(createData)}`);
    process.exit(1);
  }

  console.log('✔ Student created successfully!');

  console.log('\n4. Verifying student appears in teacher student list...');
  const updatedStudentsRes = await fetch(`${URL}/teacher/students`, { headers: teacherHeader });
  const updatedStudentsData = await updatedStudentsRes.json();
  const createdStudent = updatedStudentsData.data?.find(s => s.admission_number === testAdmissionNo);

  if (createdStudent) {
    console.log(`✔ Verified student in class: ID=${createdStudent.id}, Name=${createdStudent.full_name}, ClassID=${createdStudent.class_id}`);
  } else {
    console.error('❌ Created student not found in teacher student list!');
    process.exit(1);
  }

  console.log('\n================================================================');
  console.log('ALL TEACHER ADD STUDENT VERIFICATION TESTS PASSED!');
  console.log('================================================================\n');
}

testAddStudent().catch(err => {
  console.error('Test execution error:', err);
  process.exit(1);
});
