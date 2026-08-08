const URL = `http://localhost:5000/api`;

async function testCompleteTeacherFlow() {
  console.log('======================================================');
  console.log('=== VERIFYING COMPLETE TEACHER FLOW & DTO MAPPING ===');
  console.log('======================================================\n');

  // Step 1: Admin Login
  const loginRes = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'sadar', password: 'Ham@9345' }),
  });
  const loginData = await loginRes.json();
  const adminToken = loginData.data?.token || loginData.token;

  if (!adminToken) {
    console.error('❌ Failed admin login');
    process.exit(1);
  }

  // Step 2: GET /api/teachers
  console.log('--- Step 2: GET /api/teachers ---');
  const teachersRes = await fetch(`${URL}/teachers`, {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  const teachersData = await teachersRes.json();
  const teachers = teachersData.data || [];

  console.log(`Fetched ${teachers.length} teachers:`);
  teachers.forEach((t, i) => {
    console.log(`\nTeacher #${i + 1}:`);
    console.log(`  ID: ${t.id}`);
    console.log(`  fullName: "${t.fullName}"`);
    console.log(`  username: "${t.username}"`);
    console.log(`  assignedClass:`, JSON.stringify(t.assignedClass));
    console.log(`  assignedClassName: "${t.assignedClassName}"`);

    if (!t.fullName || t.fullName === 'Teacher') {
      console.error(`❌ FAIL: Invalid teacher name "${t.fullName}"!`);
      process.exit(1);
    }
    if (!t.assignedClass || !t.assignedClass.className || t.assignedClassName === 'None') {
      console.error(`❌ FAIL: Invalid assigned class for teacher "${t.fullName}"!`);
      process.exit(1);
    }
  });

  console.log('\n🎉 ✅ PASS: All existing teachers have valid names and assigned classes!');

  // Step 3: Create Teacher and Verify Immediate Response
  console.log('\n--- Step 3: Create new teacher and verify immediate DTO response ---');
  const classesRes = await fetch(`${URL}/classes`, {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  const classesData = await classesRes.json();
  const availableClass = (classesData.data || []).find((c) => !c.class_teacher_id);

  if (!availableClass) {
    console.error('❌ No available class to test teacher creation');
    process.exit(1);
  }

  const createRes = await fetch(`${URL}/teachers`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      fullName: 'Ashraf',
      username: `ashraf_${Date.now()}`,
      classId: availableClass.id,
    }),
  });

  const createData = await createRes.json();
  console.log('Create response status:', createRes.status);
  console.log('Create response data:', JSON.stringify(createData, null, 2));

  const newTeacher = createData.data;

  if (
    createRes.status !== 201 ||
    newTeacher.fullName !== 'Ashraf' ||
    !newTeacher.assignedClass ||
    !newTeacher.assignedClass.className
  ) {
    console.error('❌ FAIL: Created teacher DTO missing fullName or assignedClass!');
    process.exit(1);
  }

  console.log(`🎉 ✅ PASS: Teacher "${newTeacher.fullName}" created with assigned class "${newTeacher.assignedClass.className}"!`);

  // Cleanup created teacher
  await fetch(`${URL}/teachers/${newTeacher.id}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  console.log('✅ Cleaned up test teacher record.');

  console.log('\n======================================================');
  console.log('🎉 ALL TEACHER FLOW & DTO MAPPING VERIFICATIONS PASSED!');
  console.log('======================================================\n');
}

testCompleteTeacherFlow().catch((err) => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
