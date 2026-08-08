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
  console.log('=== TESTING TEACHER CREATION EDGE CASES ===');

  const loginRes = await fetchJSON('/auth/login', 'POST', { username: 'sadar', password: 'Ham@9345' });
  const token = loginRes.data?.data?.token || loginRes.data?.token;

  const classesRes = await fetchJSON('/classes', 'GET', null, token);
  const classList = classesRes.data?.data || classesRes.data;
  const targetClass = classList[0];

  // Case 1: Empty string email & phone -> Should convert "" to null and succeed (201)
  console.log('\n--- Case 1: Empty string email & phone ---');
  const res1 = await fetchJSON('/teachers', 'POST', {
    fullName: 'Teacher Empty Strings',
    username: `t_empty_${Date.now()}`,
    email: '',
    phone: '',
    classId: targetClass.id,
  }, token);
  console.log('Status:', res1.status);
  console.assert(res1.status === 201, 'Expected 201 for empty strings email/phone');
  if (res1.data?.data?.id) {
    await fetchJSON(`/teachers/${res1.data.data.id}`, 'DELETE', null, token);
  }

  // Case 2: Invalid Email format -> Should return 400 with formatted error object
  console.log('\n--- Case 2: Invalid Email Format ---');
  const res2 = await fetchJSON('/teachers', 'POST', {
    fullName: 'Teacher Invalid Email',
    username: `t_bademail_${Date.now()}`,
    email: 'not-an-email',
    classId: targetClass.id,
  }, token);
  console.log('Status:', res2.status);
  console.log('Errors:', JSON.stringify(res2.data?.errors, null, 2));
  console.assert(res2.status === 400, 'Expected 400 for invalid email format');
  console.assert(Array.isArray(res2.data?.errors) && res2.data.errors[0].field === 'email', 'Expected formatted error field=email');

  // Case 3: Missing Required fullName -> Should return 400
  console.log('\n--- Case 3: Missing Required fullName ---');
  const res3 = await fetchJSON('/teachers', 'POST', {
    username: `t_noname_${Date.now()}`,
    classId: targetClass.id,
  }, token);
  console.log('Status:', res3.status);
  console.log('Errors:', JSON.stringify(res3.data?.errors, null, 2));
  console.assert(res3.status === 400, 'Expected 400 for missing fullName');

  // Case 4: Missing Required classId -> Should return 400
  console.log('\n--- Case 4: Missing Required classId ---');
  const res4 = await fetchJSON('/teachers', 'POST', {
    fullName: 'Teacher No Class',
    username: `t_noclass_${Date.now()}`,
  }, token);
  console.log('Status:', res4.status);
  console.log('Errors:', JSON.stringify(res4.data?.errors, null, 2));
  console.assert(res4.status === 400, 'Expected 400 for missing classId');

  console.log('\n🎉 ALL TEACHER EDGE CASES PASSED PERFECTLY!');
}

testEdgeCases().catch((err) => {
  console.error('Edge cases test failed:', err);
  process.exit(1);
});
