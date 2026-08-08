import { prisma } from './src/config/db';

async function main() {
  await prisma.classes.updateMany({
    data: { class_teacher_id: null },
  });
  console.log('Unassigned all class teachers for clean test environment');
}

main().finally(() => prisma.$disconnect());
