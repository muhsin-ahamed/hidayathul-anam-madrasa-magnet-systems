const http = require('http');

const PORT = 5000;
const URL = `http://localhost:${PORT}/api`;

async function fetchJSON(path, method, body, token) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const options = { method, headers };
  if (body) options.body = JSON.stringify(body);

  try {
    const res = await fetch(`${URL}${path}`, options);
    const json = await res.json().catch((err) => ({ parseError: err.message }));
    return { status: res.status, data: json };
  } catch (e) {
    return { status: 500, error: e.message };
  }
}

async function runBusinessRuleTests() {
  console.log('====================================================');
  console.log('=== VERIFYING MANDATORY CLASS ASSIGNMENT RULES ===');
  console.log('====================================================\n');

  // Step 1: Admin Login
  const loginRes = await fetchJSON('/auth/login', 'POST', { username: 'sadar', password: 'Ham@9345' });
  const adminToken = loginRes.data?.data?.token || loginRes.data?.token;

  if (!adminToken) {
    console.error('❌ Failed admin login');
    process.exit(1);
  }

  // Get available classes
  const classesRes = await fetchJSON('/classes', 'GET', null, adminToken);
  const classes = classesRes.data?.data || classesRes.data || [];
  if (!classes || classes.length < 2) {
    console.error('❌ Could not fetch at least 2 classes for testing');
    process.exit(1);
  }

  const class1 = classes[0]; // e.g. Class 1
  const class2 = classes[1]; // e.g. Class 2

  console.log(`Using testing classes: "${class1.class_name}" (ID: ${class1.id}) and "${class2.class_name}" (ID: ${class2.id})`);

  // Test 1: Super Admin cannot create teacher without class
  console.log('\n--- Test 1: Super Admin cannot create teacher without class ---');
  const tNoClassRes = await fetchJSON('/teachers', 'POST', {
    fullName: 'Teacher Without Class',
    username: `t_noclass_${Date.now()}`,
    classId: null,
  }, adminToken);
  console.log('Status:', tNoClassRes.status, 'Message:', tNoClassRes.data?.message);
  if (tNoClassRes.status === 400 && tNoClassRes.data?.message === 'Class is required.') {
    console.log('🎉 ✅ PASS: Super Admin rejected creating teacher without class with "Class is required."!');
  } else {
    console.error('❌ FAIL: Super Admin created teacher without class or returned wrong error!');
    process.exit(1);
  }

  // Test 2: Super Admin cannot create student without class
  console.log('\n--- Test 2: Super Admin cannot create student without class ---');
  const sNoClassRes = await fetchJSON('/students', 'POST', {
    admission_number: `ADM_NOCLS_${Date.now()}`,
    roll_number: '999',
    full_name: 'Student Without Class',
    class_id: null,
  }, adminToken);
  console.log('Status:', sNoClassRes.status, 'Message:', sNoClassRes.data?.message);
  if (sNoClassRes.status === 400 && sNoClassRes.data?.message === 'Student must be assigned to a class.') {
    console.log('🎉 ✅ PASS: Super Admin rejected creating student without class with "Student must be assigned to a class."!');
  } else {
    console.error('❌ FAIL: Super Admin created student without class or returned wrong error!');
    process.exit(1);
  }

  // Test 3: Create Teacher assigned to Class 1
  console.log(`\n--- Test 3: Create Teacher assigned to ${class1.class_name} ---`);
  const tUsername = `teacher_${Date.now()}`;
  const createTeacherRes = await fetchJSON('/teachers', 'POST', {
    fullName: 'Class Teacher One',
    username: tUsername,
    classId: class1.id,
  }, adminToken);

  console.log('Status:', createTeacherRes.status);
  if (createTeacherRes.status !== 201) {
    console.error('❌ FAIL: Teacher creation failed:', createTeacherRes.data);
    process.exit(1);
  }
  console.log(`🎉 ✅ PASS: Created teacher assigned to ${class1.class_name}!`);
  const teacherObj = createTeacherRes.data.data;

  // Test 4: One class has only one teacher (try assigning second teacher to Class 1)
  console.log(`\n--- Test 4: Prevent duplicate teacher assignment to ${class1.class_name} ---`);
  const dupTeacherRes = await fetchJSON('/teachers', 'POST', {
    fullName: 'Second Teacher Same Class',
    username: `t_dup_${Date.now()}`,
    classId: class1.id,
  }, adminToken);
  console.log('Status:', dupTeacherRes.status, 'Message:', dupTeacherRes.data?.message);
  if (dupTeacherRes.status === 400 && dupTeacherRes.data?.message === 'This class already has a class teacher.') {
    console.log('🎉 ✅ PASS: Rejected second teacher assignment with "This class already has a class teacher."!');
  } else {
    console.error('❌ FAIL: Duplicate teacher assigned to same class!');
    process.exit(1);
  }

  // Test 5: Verify Teacher Login with generated password (Ham@cls<X>)
  console.log(`\n--- Test 5: Verify Teacher login with default generated password ---`);
  const classMatch = class1.class_name.match(/\d+/);
  const expectedPassword = `Ham@cls${classMatch ? classMatch[0] : '1'}`;
  console.log(`Attempting login for username "${tUsername}" with password "${expectedPassword}"...`);
  const teacherLoginRes = await fetchJSON('/auth/login', 'POST', {
    username: tUsername,
    password: expectedPassword,
  });

  const teacherToken = teacherLoginRes.data?.data?.token || teacherLoginRes.data?.token;
  if (teacherLoginRes.status === 200 && teacherToken) {
    console.log(`🎉 ✅ PASS: Teacher logged in successfully with generated password (${expectedPassword})!`);
  } else {
    console.error('❌ FAIL: Teacher login failed:', teacherLoginRes.data);
    process.exit(1);
  }

  // Test 6: Teacher CANNOT create student in another class (Class 2)
  console.log(`\n--- Test 6: Teacher CANNOT create student in another class (${class2.class_name}) ---`);
  const tOtherClassStudentRes = await fetchJSON('/students', 'POST', {
    admission_number: `ADM_WRONGCLS_${Date.now()}`,
    roll_number: '101',
    full_name: 'Unallowed Student',
    class_id: class2.id,
  }, teacherToken);
  console.log('Status:', tOtherClassStudentRes.status, 'Message:', tOtherClassStudentRes.data?.message);
  if (tOtherClassStudentRes.status === 403) {
    console.log('🎉 ✅ PASS: Teacher blocked from creating student in another class!');
  } else {
    console.error('❌ FAIL: Teacher created student in another class!');
    process.exit(1);
  }

  // Test 7: Teacher CAN create student in their assigned class (Class 1)
  console.log(`\n--- Test 7: Teacher CAN create student in assigned class (${class1.class_name}) ---`);
  const admNum = `ADM_TEACHER_${Date.now()}`;
  const tOwnClassStudentRes = await fetchJSON('/students', 'POST', {
    admission_number: admNum,
    roll_number: '102',
    full_name: 'Teacher Student',
    class_id: class1.id,
  }, teacherToken);
  console.log('Status:', tOwnClassStudentRes.status);
  if (tOwnClassStudentRes.status === 201) {
    console.log(`🎉 ✅ PASS: Teacher created student in assigned class!`);
  } else {
    console.error('❌ FAIL: Teacher could not create student in assigned class:', tOwnClassStudentRes.data);
    process.exit(1);
  }
  const createdStudentObj = tOwnClassStudentRes.data.data;

  // Test 8: Verify Student Login (Username = Admission Number, Password = Admission Number)
  console.log(`\n--- Test 8: Verify Student login (Username = Admission Number, Password = Admission Number) ---`);
  const studentLoginRes = await fetchJSON('/auth/login', 'POST', {
    username: admNum,
    password: admNum,
  });
  if (studentLoginRes.status === 200) {
    console.log('🎉 ✅ PASS: Student logged in successfully using admission number!');
  } else {
    console.error('❌ FAIL: Student login failed:', studentLoginRes.data);
    process.exit(1);
  }

  // Cleanup test records
  console.log('\n--- Cleanup test records ---');
  await fetchJSON(`/students/${createdStudentObj.id}`, 'DELETE', null, adminToken);
  await fetchJSON(`/teachers/${teacherObj.id}`, 'DELETE', null, adminToken);
  console.log('✅ Cleaned up test records.');

  console.log('\n====================================================');
  console.log('🎉 ALL MANDATORY CLASS ASSIGNMENT BUSINESS RULES PASSED!');
  console.log('====================================================\n');
}

runBusinessRuleTests().catch(err => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
