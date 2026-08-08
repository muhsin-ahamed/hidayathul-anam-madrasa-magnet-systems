const http = require('http');

const PORT = 5000;
const URL = `http://localhost:${PORT}/api/auth`;

async function fetchJSON(path, method, body, token) {
  const headers = {
    'Content-Type': 'application/json',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const options = {
    method,
    headers,
  };
  if (body) {
    options.body = JSON.stringify(body);
  }

  try {
    const res = await fetch(`${URL}${path}`, options);
    const json = await res.json();
    return { status: res.status, data: json };
  } catch (e) {
    return { status: 500, error: e.message };
  }
}

async function runTests() {
  console.log('--- STARTING AUTH TESTS ---');
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

  // Test 1: Invalid request (missing username)
  const res1 = await fetchJSON('/login', 'POST', { password: 'abc' });
  assert(res1.status === 400 || res1.status === 422, 'Invalid request returns 400/422');

  // Test 2: Unauthorized login (wrong credentials)
  const res2 = await fetchJSON('/login', 'POST', { username: 'wrong', password: 'abc' });
  assert(res2.status === 401 || res2.status === 404, 'Unauthorized login returns 401/404');

  // Test 3: Success login
  const res3 = await fetchJSON('/login', 'POST', { username: 'sadar', password: 'Ham@9345' });
  assert(res3.status === 200 && res3.data.success && res3.data.token, 'Successful login returns 200 and token');
  
  const token = res3.data?.token;

  // Test 4: Unauthorized request to /me
  const res4 = await fetchJSON('/me', 'GET');
  assert(res4.status === 401, 'Accessing /me without token returns 401');

  // Test 5: Success /me
  const res5 = await fetchJSON('/me', 'GET', null, token);
  assert(res5.status === 200 && res5.data.success && res5.data.data.username === 'sadar', 'Accessing /me with token returns user data');

  // Test 6: Success /logout
  const res6 = await fetchJSON('/logout', 'POST', null, token);
  assert(res6.status === 200 && res6.data.success, 'Successful logout returns 200');

  console.log('--- TEST RESULTS ---');
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);
  console.log(JSON.stringify({ passed, failed }));
}

setTimeout(runTests, 2000);
