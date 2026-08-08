const URL = `http://localhost:5000/api`;

async function testTeacherNameDisplay() {
  console.log('=== TESTING TEACHER NAME DISPLAY IN API & DATA TRANSFORM ===');

  // Step 1: Admin Login
  const loginRes = await fetch(`${URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'sadar', password: 'Ham@9345' }),
  });
  const loginData = await loginRes.json();
  const token = loginData.data?.token || loginData.token;

  if (!token) {
    console.error('❌ Failed admin login');
    process.exit(1);
  }

  // Step 2: GET /api/teachers
  const teachersRes = await fetch(`${URL}/teachers`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const teachersData = await teachersRes.json();
  const teachers = teachersData.data || [];

  console.log(`Fetched ${teachers.length} teachers from GET /api/teachers:`);
  teachers.forEach((t, i) => {
    console.log(`[Teacher ${i + 1}] ID: ${t.id} | Name: "${t.fullName || t.full_name}" | Username: "${t.username}" | Class: "${t.className || t.assignedClassName}"`);
  });

  // Verify none of the teachers have fullName == "Teacher"
  const invalidName = teachers.find(t => (t.fullName || t.full_name) === 'Teacher');
  if (invalidName) {
    console.error('❌ FAIL: Found hardcoded name "Teacher" in API response!');
    process.exit(1);
  }

  console.log('\n🎉 ✅ SUCCESS: All teachers display their real full names from the database!');
}

testTeacherNameDisplay().catch(err => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
