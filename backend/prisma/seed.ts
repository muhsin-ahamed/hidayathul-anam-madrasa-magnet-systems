import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();
const SALT_ROUNDS = 10;

async function main() {
  console.log('Seeding database for production release...');

  // 1. Seed Super Admin
  const superAdminUsername = 'sadar';
  const superAdminPassword = 'Ham@9345';
  const superAdminHash = await bcrypt.hash(superAdminPassword, SALT_ROUNDS);

  let superAdminProfile = await prisma.profiles.findUnique({
    where: { username: superAdminUsername }
  });

  if (!superAdminProfile) {
    superAdminProfile = await prisma.profiles.create({
      data: {
        username: superAdminUsername,
        full_name: 'Super Admin',
        role: 'super_admin',
        is_active: true,
      }
    });
  }

  const existingSuperAdminUser = await prisma.users.findUnique({
    where: { username: superAdminUsername }
  });

  if (!existingSuperAdminUser) {
    await prisma.users.create({
      data: {
        username: superAdminUsername,
        password_hash: superAdminHash,
        role: 'super_admin',
        profile_id: superAdminProfile.id
      }
    });
    console.log('✅ Super Admin seeded.');
  }

  // 2. Seed Classes 1 to 12
  const classNames = Array.from({ length: 12 }, (_, i) => `Class ${i + 1}`);

  for (const className of classNames) {
    let cls = await prisma.classes.findFirst({
      where: { class_name: className }
    });

    if (!cls) {
      cls = await prisma.classes.create({
        data: {
          class_name: className,
          academic_year: '2026',
          is_active: true
        }
      });
      console.log(`✅ ${className} seeded.`);
    }
  }

  console.log('Production seeding complete.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
