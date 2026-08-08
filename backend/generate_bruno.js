const fs = require('fs');
const path = require('path');

const collectionDir = path.join(__dirname, 'bruno_collection');

if (fs.existsSync(collectionDir)) {
    fs.rmSync(collectionDir, { recursive: true, force: true });
}
fs.mkdirSync(collectionDir, { recursive: true });

// bruno.json
fs.writeFileSync(path.join(collectionDir, 'bruno.json'), JSON.stringify({
    version: "1",
    name: "HIDAYATHUL ANAM MADRASA API",
    type: "collection",
    ignore: [ "node_modules", ".git" ]
}, null, 2));

// environments folder
const envDir = path.join(collectionDir, 'environments');
fs.mkdirSync(envDir);
fs.writeFileSync(path.join(envDir, 'local.bru'), `vars
  baseUrl: http://localhost:5000/api
  superAdminToken: 
  teacherToken: 
  studentToken: 
`);

const modules = [
    { name: "1_Auth", endpoints: [
        { name: "Login Success", method: "post", url: "{{baseUrl}}/auth/login", body: '{"username": "admin", "password": "password"}' },
        { name: "Login Invalid", method: "post", url: "{{baseUrl}}/auth/login", body: '{"username": "invalid", "password": "bad"}' },
        { name: "Me Success", method: "get", url: "{{baseUrl}}/auth/me", auth: "superAdminToken" },
        { name: "Me Unauthorized", method: "get", url: "{{baseUrl}}/auth/me" },
    ]},
    { name: "2_Teachers", endpoints: [
        { name: "Get All Teachers", method: "get", url: "{{baseUrl}}/teachers", auth: "superAdminToken" },
        { name: "Create Teacher Success", method: "post", url: "{{baseUrl}}/teachers", body: '{"username": "newteacher", "email": "t@t.com", "fullName": "T", "password": "pw", "classId": "1"}', auth: "superAdminToken" },
        { name: "Create Teacher Forbidden", method: "post", url: "{{baseUrl}}/teachers", body: '{"username": "t2", "email": "t2@t.com", "fullName": "T2", "password": "pw", "classId": "1"}', auth: "studentToken" },
        { name: "Get Teacher Not Found", method: "get", url: "{{baseUrl}}/teachers/99999", auth: "superAdminToken" },
    ]},
    { name: "3_Students", endpoints: [
        { name: "Get All Students", method: "get", url: "{{baseUrl}}/students", auth: "superAdminToken" },
        { name: "Create Student Success", method: "post", url: "{{baseUrl}}/students", body: '{"username": "newstudent", "admissionNumber": "A1", "firstName": "F", "lastName": "L", "classId": "1"}', auth: "superAdminToken" },
        { name: "Create Student Forbidden", method: "post", url: "{{baseUrl}}/students", body: '{}', auth: "studentToken" },
        { name: "Create Student Duplicate", method: "post", url: "{{baseUrl}}/students", body: '{"username": "existingstudent", "admissionNumber": "A1"}', auth: "superAdminToken" },
    ]},
    { name: "4_Classes", endpoints: [
        { name: "Get All Classes", method: "get", url: "{{baseUrl}}/classes", auth: "superAdminToken" },
        { name: "Create Class", method: "post", url: "{{baseUrl}}/classes", body: '{"displayName": "Class 1", "level": 1}', auth: "superAdminToken" },
        { name: "Get Class Not Found", method: "get", url: "{{baseUrl}}/classes/9999", auth: "superAdminToken" },
    ]},
    { name: "5_Dashboard", endpoints: [
        { name: "Get Dashboard", method: "get", url: "{{baseUrl}}/dashboard", auth: "superAdminToken" },
        { name: "Get Dashboard Unauthorized", method: "get", url: "{{baseUrl}}/dashboard" },
    ]},
    { name: "6_Results", endpoints: [
        { name: "Get Results By Student", method: "get", url: "{{baseUrl}}/results?studentId=1", auth: "studentToken" },
        { name: "Upload Bulk Results", method: "post", url: "{{baseUrl}}/results/bulk", body: '{"examId": "1", "results": []}', auth: "teacherToken" },
    ]},
    { name: "7_Notes", endpoints: [
        { name: "Get Notes By Class", method: "get", url: "{{baseUrl}}/notes?classId=1", auth: "studentToken" },
        { name: "Upload Note", method: "post", url: "{{baseUrl}}/notes", body: '{}', auth: "teacherToken" }, // Note: requires multipart in actual test
    ]},
    { name: "8_HallTickets", endpoints: [
        { name: "Get Hall Tickets By Student", method: "get", url: "{{baseUrl}}/hall-tickets?studentId=1", auth: "studentToken" },
        { name: "Generate Hall Tickets", method: "post", url: "{{baseUrl}}/hall-tickets/generate", body: '{"examId": "1", "classId": "1"}', auth: "teacherToken" },
    ]},
    { name: "9_ActivityLogs", endpoints: [
        { name: "Get All Logs", method: "get", url: "{{baseUrl}}/activity-logs", auth: "superAdminToken" },
        { name: "Get Logs Forbidden", method: "get", url: "{{baseUrl}}/activity-logs", auth: "studentToken" },
    ]},
];

for (const mod of modules) {
    const modDir = path.join(collectionDir, mod.name);
    fs.mkdirSync(modDir);
    for (const ep of mod.endpoints) {
        let content = "meta {\\n" +
  "  name: " + ep.name + "\\n" +
  "  type: http\\n" +
  "  seq: 1\\n" +
"}\\n\\n" +
ep.method + " {\\n" +
"  url: " + ep.url + "\\n" +
"  body: " + (ep.body ? 'json' : 'none') + "\\n" +
"  auth: " + (ep.auth ? 'bearer' : 'none') + "\\n" +
"}\\n\\n";
        
        if (ep.auth) {
            content += "auth:bearer {\\n" +
"  token: {{" + ep.auth + "}}\\n" +
"}\\n\\n";
        }
        if (ep.body) {
            content += "body:json {\\n" +
"  " + ep.body + "\\n" +
"}\\n";
        }
        
        fs.writeFileSync(path.join(modDir, ep.name.replace(/ /g, '_') + ".bru"), content);
    }
}

console.log("Bruno collection generated successfully at " + collectionDir);
