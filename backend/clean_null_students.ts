import { prisma } from './src/config/db';

async function main() {
  const result = await prisma.students.deleteMany({
    where: { class_id: null as any },
  });
  console.log('Cleaned up unassigned student records:', result.count);
}

main().finally(() => prisma.$disconnect());
