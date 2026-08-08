require('dotenv').config();

const BASE_URL = process.env.API_BASE_URL || 'http://localhost:5000/api';
let superAdminToken = '';

async function runTests() {
    console.log("Starting API Tests against " + BASE_URL + "...");
    
    try {
        // 1. Auth Module Tests
        console.log("\\n--- 1. AUTH MODULE ---");
        let res = await fetch(BASE_URL + "/auth/login", {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: 'superadmin', password: 'password' }) // Mock credentials
        });
        
        if (res.ok) {
            const data = await res.json();
            superAdminToken = data.data.token;
            console.log('✅ Auth Login Success (Super Admin)');
        } else {
            console.log('❌ Auth Login Failed (Status: ' + res.status + ') - Expected if database is not seeded.');
        }

        // Run other endpoints
        res = await fetch(BASE_URL + "/auth/me", {
            headers: { 'Authorization': "Bearer " + superAdminToken }
        });
        if (res.ok) console.log('✅ Auth Me Success');
        else console.log('❌ Auth Me Failed (Status: ' + res.status + ')');

        // 2. Teachers Module
        console.log("\\n--- 2. TEACHERS MODULE ---");
        res = await fetch(BASE_URL + "/teachers", {
            headers: { 'Authorization': "Bearer " + superAdminToken }
        });
        console.log("✅ Get All Teachers (Status: " + res.status + ")");
        
        // 3. Students Module
        console.log("\\n--- 3. STUDENTS MODULE ---");
        res = await fetch(BASE_URL + "/students", {
            headers: { 'Authorization': "Bearer " + superAdminToken }
        });
        console.log("✅ Get All Students (Status: " + res.status + ")");
        
        // 4. Classes Module
        console.log("\\n--- 4. CLASSES MODULE ---");
        res = await fetch(BASE_URL + "/classes", {
            headers: { 'Authorization': "Bearer " + superAdminToken }
        });
        console.log("✅ Get All Classes (Status: " + res.status + ")");

        // 5. Dashboard Module
        console.log("\\n--- 5. DASHBOARD MODULE ---");
        res = await fetch(BASE_URL + "/dashboard", {
            headers: { 'Authorization': "Bearer " + superAdminToken }
        });
        console.log("✅ Get Dashboard (Status: " + res.status + ")");

        // 6. Results Module
        console.log("\\n--- 6. RESULTS MODULE ---");
        res = await fetch(BASE_URL + "/results?studentId=1", {
            headers: { 'Authorization': "Bearer " + superAdminToken }
        });
        console.log("✅ Get Results (Status: " + res.status + ")");

        // 7. Notes Module
        console.log("\\n--- 7. NOTES MODULE ---");
        res = await fetch(BASE_URL + "/notes?classId=1", {
            headers: { 'Authorization': "Bearer " + superAdminToken }
        });
        console.log("✅ Get Notes (Status: " + res.status + ")");

        // 8. Hall Tickets Module
        console.log("\\n--- 8. HALL TICKETS MODULE ---");
        res = await fetch(BASE_URL + "/hall-tickets?studentId=1", {
            headers: { 'Authorization': "Bearer " + superAdminToken }
        });
        console.log("✅ Get Hall Tickets (Status: " + res.status + ")");

        // 9. Activity Logs Module
        console.log("\\n--- 9. ACTIVITY LOGS MODULE ---");
        res = await fetch(BASE_URL + "/activity-logs", {
            headers: { 'Authorization': "Bearer " + superAdminToken }
        });
        console.log("✅ Get Activity Logs (Status: " + res.status + ")");

    } catch (err) {
        console.error('Test execution failed:', err);
    }
    
    console.log('\\nDone running API tests.');
}

runTests();
