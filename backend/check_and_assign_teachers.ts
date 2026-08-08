import { prisma } from './src/config/db';

async function main() {
  console.log('=== CHECKING EXISTING TEACHERS AND CLASS ASSIGNMENTS ===');

  const teachers = await prisma.teachers.findMany({
    include: {
      profile: {
        include: {
          classes: true,
        },
      },
    },
  });

  const allClasses = await prisma.classes.findMany({
    orderBy: { created_at: 'asc' },
  });

  console.log(`Total teachers in DB: ${teachers.length}`);
  console.log(`Total classes in DB: ${allClasses.length}`);

  for (const t of teachers) {
    const assignedClasses = t.profile?.classes || [];
    console.log(`Teacher ID: ${t.id} | Name: "${t.profile?.full_name}" | Username: "${t.profile?.username}" | Assigned classes count: ${assignedClasses.length}`);

    if (assignedClasses.length === 0) {
      // Find an unassigned class
      const availableClass = allClasses.find((c) => !c.class_teacher_id);
      if (availableClass) {
        console.log(`-> Assigning teacher "${t.profile?.full_name}" to class "${availableClass.class_name}" (${availableClass.id})`);
        await prisma.classes.update({
          where: { id: availableClass.id },
          data: { class_teacher_id: t.profile_id },
        });
        availableClass.class_teacher_id = t.profile_id;
      } else {
        console.warn(`⚠️ No available unassigned class for teacher "${t.profile?.full_name}"`);
      }
    }
  }

  // Re-verify
  const updatedTeachers = await prisma.teachers.findMany({
    include: {
      profile: {
        include: {
          classes: true,
        },
      },
    },
  });

  console.log('\n--- Final Verification ---');
  for (const t of updatedTeachers) {
    const cls = t.profile?.classes?.[0];
    const name = t.profile?.full_name;
    const clsName = cls ? (cls.section ? `${cls.class_name} - ${cls.section}` : cls.class_name) : 'NONE';
    console.log(`Teacher: "${name}" -> Class: "${clsName}"`);
  }
}

main().finally(() => prisma.$disconnect());
