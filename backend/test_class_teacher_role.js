const URL = `http://localhost:5000/api`;

function parseJwt(token) {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = Buffer.from(base64, 'base64').toString('utf8');
    return JSON.parse(jsonPayload);
  } catch (e) {
    return null;
  }
}

async function testClassTeacherRole() {
  console.log('====================================================');
  console.log('=== VERIFYING EXACT ROLE "class_teacher" RETURN ===');
  console.log('====================================================\n');

  // Test teacher login for "nizar" (assigned to Class 2, password "Ham@cls2")
  const loginRes = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: 'nizar',
      password: 'Ham@cls2',
    }),
  });

  const loginData = await loginRes.json();
  console.log('Login HTTP Status:', loginRes.status);
  console.log('Login Response Body:', JSON.stringify(loginData, null, 2));

  const token = loginData.token || loginData.data?.token;
  const jwt = parseJwt(token);

  console.log('Decoded JWT Payload:', jwt);

  if (loginRes.status !== 200) {
    console.error('❌ FAIL: Teacher login returned non-200 status');
    process.exit(1);
  }

  if (loginData.user?.role !== 'class_teacher') {
    console.error(`❌ FAIL: Expected user.role to be "class_teacher", but got "${loginData.user?.role}"`);
    process.exit(1);
  }

  if (jwt.role !== 'class_teacher') {
    console.error(`❌ FAIL: Expected JWT role to be "class_teacher", but got "${jwt.role}"`);
    process.exit(1);
  }

  console.log('\n====================================================');
  console.log('🎉 SUCCESS: Teacher login returns EXACT role "class_teacher" and valid JWT!');
  console.log('====================================================\n');
}

testClassTeacherRole().catch((err) => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
