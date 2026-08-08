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
  console.log('--- STARTING ACTIVITY LOGS TESTS ---');
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

  const loginRes = await fetchJSON('/auth/login', 'POST', { username: 'sadar', password: 'Ham@9345' });
  const token = loginRes.data?.token;

  if (!token) {
    console.error('Failed to get token for tests.');
    return;
  }
  
  // Test 1: Unauthorized
  const res1 = await fetchJSON('/activity-logs', 'GET');
  assert(res1.status === 401, 'Unauthorized request returns 401');

  // Test 2: Get all logs (Authorized)
  const res2 = await fetchJSON('/activity-logs', 'GET', null, token);
  assert(res2.status === 200 && Array.isArray(res2.data?.data), 'Get all activity logs returns 200');

  console.log('--- TEST RESULTS ---');
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);
}

setTimeout(runTests, 1000);
