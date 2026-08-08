import { prisma } from './src/config/db';
import { hashPassword } from './src/utils/hash';

async function seedAndSyncPasswords() {
  console.log('======================================================');
  console.log('=== SEEDING AND SYNCING BCRYPT PASSWORD HASHES ===');
  console.log('======================================================\n');

  // 1. Seed / Sync Super Admin 'sadar'
  let sadarProfile = await prisma.profiles.findUnique({
    where: { username: 'sadar' },
  });

  if (!sadarProfile) {
    console.log('Creating Super Admin profile for "sadar"...');
    sadarProfile = await prisma.profiles.create({
      data: {
        username: 'sadar',
        full_name: 'Super Admin',
        role: 'super_admin',
        is_active: true,
      },
    });
  }

  const sadarHash = await hashPassword('Ham@9345');
  await prisma.users.upsert({
    where: { profile_id: sadarProfile.id },
    update: {
      username: 'sadar',
      password_hash: sadarHash,
      role: 'super_admin',
    },
    create: {
      profile_id: sadarProfile.id,
      username: 'sadar',
      password_hash: sadarHash,
      role: 'super_admin',
    },
  });
  console.log('✅ Super Admin "sadar" bcrypt password_hash synced to users table!');

  // 2. Sync all Teachers
  const teachers = await prisma.teachers.findMany({
    include: {
      profile: {
        include: {
          classes: true,
        },
      },
    },
  });

  for (const t of teachers) {
    const p = t.profile;
    if (!p || !p.username) continue;

    const assignedClass = p.classes.length > 0 ? p.classes[0] : null;
    const matchNum = assignedClass?.class_name.match(/\d+/);
    const clsNum = matchNum ? matchNum[0] : '1';
    const teacherPlainPassword = `Ham@cls${clsNum}`;
    const teacherHash = await hashPassword(teacherPlainPassword);

    await prisma.users.upsert({
      where: { profile_id: p.id },
      update: {
        username: p.username,
        password_hash: teacherHash,
        role: 'class_teacher',
      },
      create: {
        profile_id: p.id,
        username: p.username,
        password_hash: teacherHash,
        role: 'class_teacher',
      },
    });
    console.log(`✅ Teacher "${p.username}" password_hash synced for class "${assignedClass?.class_name || 'Class 1'}"!`);
  }

  // 3. Sync all Students
  const students = await prisma.students.findMany({
    include: { profile: true },
  });

  for (const s of students) {
    const profileId = s.profile_id;
    if (!profileId) continue;

    const username = s.admission_number;
    const studentHash = await hashPassword(s.admission_number);

    await prisma.users.upsert({
      where: { profile_id: profileId },
      update: {
        username: username,
        password_hash: studentHash,
        role: 'student',
      },
      create: {
        profile_id: profileId,
        username: username,
        password_hash: studentHash,
        role: 'student',
      },
    });

    // Ensure profile username is populated
    await prisma.profiles.update({
      where: { id: profileId },
      data: { username: username },
    });

    console.log(`✅ Student admission_number "${s.admission_number}" password_hash synced!`);
  }

  console.log('\n======================================================');
  console.log('🎉 ALL USERS PASSWORD_HASH RECORDS SYNCED IN DATABASE!');
  console.log('======================================================\n');
}

seedAndSyncPasswords()
  .catch((e) => {
    console.error('Error seeding passwords:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
