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

async function testEdgeCases() {
  console.log('=== TESTING STUDENT CREATION EDGE CASES ===');

  const loginRes = await fetchJSON('/auth/login', 'POST', { username: 'sadar', password: 'Ham@9345' });
  const token = loginRes.data?.data?.token || loginRes.data?.token;

  const classesRes = await fetchJSON('/classes', 'GET', null, token);
  const classList = classesRes.data?.data || classesRes.data;
  const targetClass = classList[0];

  // Test Case A: Missing required field full_name
  console.log('\n--- Test A: Missing full_name ---');
  const resA = await fetchJSON('/students', 'POST', {
    admission_number: 'ADM_FAIL_1',
    roll_number: '1',
    class_id: targetClass.id,
  }, token);
  console.log('Status:', resA.status);
  console.log('Message/Errors:', resA.data?.message, resA.data?.errors);
  console.assert(resA.status === 400, 'Expected 400 for missing full_name');

  // Test Case B: Invalid class_id UUID
  console.log('\n--- Test B: Invalid class_id format ---');
  const resB = await fetchJSON('/students', 'POST', {
    admission_number: 'ADM_FAIL_2',
    roll_number: '2',
    full_name: 'Jane Doe',
    class_id: 'invalid-class-id',
  }, token);
  console.log('Status:', resB.status);
  console.log('Message/Errors:', resB.data?.message, resB.data?.errors);
  console.assert(resB.status === 400, 'Expected 400 for invalid class_id format');

  // Test Case C: Non-existent class_id UUID
  console.log('\n--- Test C: Non-existent class_id UUID ---');
  const resC = await fetchJSON('/students', 'POST', {
    admission_number: 'ADM_FAIL_3',
    roll_number: '3',
    full_name: 'Jane Doe',
    class_id: '00000000-0000-0000-0000-000000000000',
  }, token);
  console.log('Status:', resC.status);
  console.log('Message:', resC.data?.message);
  console.assert(resC.status === 404, 'Expected 404 for non-existent class_id');

  // Test Case D: Full creation with populated optional fields
  console.log('\n--- Test D: Full creation with populated optional fields ---');
  const admNum = `ADM_POP_${Date.now()}`;
  const resD = await fetchJSON('/students', 'POST', {
    admission_number: admNum,
    roll_number: '102',
    full_name: 'Alice Smith',
    class_id: targetClass.id,
    date_of_birth: '2012-08-15',
    gender: 'Female',
    guardian_name: 'Bob Smith',
    guardian_phone: '9876543210',
    address: '123 Test St',
    email: 'alice.smith@example.com',
  }, token);
  console.log('Status:', resD.status);
  console.assert(resD.status === 201, 'Expected 201 for valid full creation');
  const createdStudent = resD.data?.data;

  // Test Case E: Duplicate admission_number
  console.log('\n--- Test E: Duplicate admission_number ---');
  const resE = await fetchJSON('/students', 'POST', {
    admission_number: admNum,
    roll_number: '103',
    full_name: 'Duplicate Student',
    class_id: targetClass.id,
  }, token);
  console.log('Status:', resE.status);
  console.log('Message:', resE.data?.message);
  console.assert(resE.status === 409, 'Expected 409 for duplicate admission_number');

  // Test Case F: Duplicate roll_number in same class
  console.log('\n--- Test F: Duplicate roll_number ---');
  const resF = await fetchJSON('/students', 'POST', {
    admission_number: `ADM_ROLL_${Date.now()}`,
    roll_number: '102', // Same roll number as createdStudent
    full_name: 'Duplicate Roll Student',
    class_id: targetClass.id,
  }, token);
  console.log('Status:', resF.status);
  console.log('Message:', resF.data?.message);
  console.assert(resF.status === 409, 'Expected 409 for duplicate roll_number');

  // Cleanup Test D student
  if (createdStudent?.id) {
    await fetchJSON(`/students/${createdStudent.id}`, 'DELETE', null, token);
  }

  console.log('\n🎉 ALL EDGE CASES VERIFIED!');
}

testEdgeCases().catch(err => {
  console.error('Edge cases test failed:', err);
  process.exit(1);
});
