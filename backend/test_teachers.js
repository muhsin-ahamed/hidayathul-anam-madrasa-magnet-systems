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
    const json = await res.json().catch(() => ({}));
    return { status: res.status, data: json };
  } catch (e) {
    return { status: 500, error: e.message };
  }
}

async function runTests() {
  console.log('--- STARTING TEACHERS TESTS ---');
  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`✅ PASS: ${message}`);
      passed++;
    } else {
      console.error(`❌ FAIL: ${message}`);
      failed++;
    }
  }

  // 1. Get Token (Super Admin required)
  const loginRes = await fetchJSON('/auth/login', 'POST', { username: 'sadar', password: 'Ham@9345' });
  const token = loginRes.data?.token;

  if (!token) {
    console.error('Failed to get token for tests. Make sure database is seeded and credentials are correct.');
    return;
  }

  // Test 1: Unauthorized request (no token)
  const res1 = await fetchJSON('/teachers', 'GET');
  assert(res1.status === 401, 'Unauthorized request returns 401');

  // Test 2: Validation error on create
  const res2 = await fetchJSON('/teachers', 'POST', { username: 'a' }, token); // Invalid schema
  assert(res2.status === 400 || res2.status === 422, 'Invalid create request returns 400/422');

  // Test 3: Successful creation
  const res3 = await fetchJSON('/teachers', 'POST', {
    username: 'test_teacher_01',
    full_name: 'Test Teacher',
    class_number: 1,
    employee_number: 'EMP001'
  }, token);
  assert(res3.status === 201 && res3.data.success, 'Successful teacher creation returns 201');
  
  const teacherId = res3.data?.data?.id;

  // Test 4: Duplicate creation
  const res4 = await fetchJSON('/teachers', 'POST', {
    username: 'test_teacher_01',
    full_name: 'Test Teacher 2',
    class_number: 1
  }, token);
  assert(res4.status === 409, 'Duplicate username returns 409');

  // Test 5: Get all teachers
  const res5 = await fetchJSON('/teachers', 'GET', null, token);
  assert(res5.status === 200 && Array.isArray(res5.data.data), 'Get all teachers returns 200');

  if (teacherId) {
    // Test 6: Get teacher by ID
    const res6 = await fetchJSON(`/teachers/${teacherId}`, 'GET', null, token);
    assert(res6.status === 200 && res6.data.data.id === teacherId, 'Get teacher by ID returns 200');

    // Test 7: Update teacher
    const res7 = await fetchJSON(`/teachers/${teacherId}`, 'PUT', { full_name: 'Updated Name' }, token);
    assert(res7.status === 200 && res7.data.data.profile.full_name === 'Updated Name', 'Update teacher returns 200');

    // Test 8: Delete teacher
    const res8 = await fetchJSON(`/teachers/${teacherId}`, 'DELETE', null, token);
    assert(res8.status === 200, 'Delete teacher returns 200');

    // Test 9: Get deleted teacher
    const res9 = await fetchJSON(`/teachers/${teacherId}`, 'GET', null, token);
    assert(res9.status === 404, 'Get deleted teacher returns 404');
  }

  console.log('--- TEST RESULTS ---');
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);
  console.log(JSON.stringify({ passed, failed }));
}

setTimeout(runTests, 1000);
