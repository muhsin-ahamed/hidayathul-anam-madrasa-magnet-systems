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

async function testStudentCreation() {
  console.log('=== TESTING STUDENT CREATION API ===');

  // Step 1: Login as super admin
  console.log('\n--- Step 1: Login as sadar ---');
  const loginRes = await fetchJSON('/auth/login', 'POST', { username: 'sadar', password: 'Ham@9345' });
  console.log('Login status:', loginRes.status);
  const token = loginRes.data?.data?.token || loginRes.data?.token;

  if (!token) {
    console.error('❌ Failed to get auth token:', loginRes.data);
    process.exit(1);
  }
  console.log('✅ Obtained Auth Token');

  // Step 2: Fetch classes
  console.log('\n--- Step 2: Get active classes ---');
  const classesRes = await fetchJSON('/classes', 'GET', null, token);
  console.log('Get classes status:', classesRes.status);
  const classList = classesRes.data?.data || classesRes.data;

  if (!Array.isArray(classList) || classList.length === 0) {
    console.error('❌ No classes found in database!');
    process.exit(1);
  }

  const targetClass = classList[0];
  console.log(`✅ Found target class: "${targetClass.class_name}" (ID: ${targetClass.id})`);

  // Step 3: Test Flutter Payload (with null fields)
  console.log('\n--- Step 3: Create Student with Flutter DTO Payload ---');
  const testAdmissionNumber = `ADM_TEST_${Date.now()}`;
  const flutterPayload = {
    id: '',
    profile_id: null,
    admission_number: testAdmissionNumber,
    roll_number: '101',
    full_name: 'Test Student John Doe',
    class_id: targetClass.id,
    date_of_birth: null,
    gender: null,
    guardian_name: null,
    guardian_phone: null,
    address: null,
    photo_path: null,
    is_active: true,
    email: null,
    password: testAdmissionNumber,
  };

  const createRes = await fetchJSON('/students', 'POST', flutterPayload, token);
  console.log('Create student status:', createRes.status);
  console.log('Create student response:', JSON.stringify(createRes.data, null, 2));

  if (createRes.status === 201 && createRes.data?.success) {
    console.log('🎉 ✅ SUCCESS: Student created successfully!');
    const createdStudent = createRes.data.data;

    // Step 4: Cleanup created student
    console.log('\n--- Step 4: Clean up test student ---');
    const deleteRes = await fetchJSON(`/students/${createdStudent.id}`, 'DELETE', null, token);
    console.log('Delete student status:', deleteRes.status);
    console.log('✅ Cleaned up test student.');
  } else {
    console.error('❌ FAIL: Student creation failed with status', createRes.status);
    process.exit(1);
  }
}

testStudentCreation().catch(err => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
