import { prisma } from '../config/db';

export const getDashboardStats = async (user: any) => {
  let classesCount = 0;
  let studentsCount = 0;
  let teachersCount = 0;

  if (user.role === 'super_admin') {
    classesCount = await prisma.classes.count();
    studentsCount = await prisma.students.count();
    teachersCount = await prisma.teachers.count();
  } else if (user.role === 'class_teacher') {
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user.id },
    });
    if (teacherClass) {
      classesCount = 1;
      studentsCount = await prisma.students.count({
        where: { class_id: teacherClass.id },
      });
    }
    teachersCount = 1;
  } else if (user.role === 'student') {
      // Students don't see these aggregated counts in the same way, but keeping API structure
  }

  // Get recent activity logs for this user (or all if super admin)
  const activityFilter = user.role === 'super_admin' ? {} : { user_id: user.id };
  const recentActivity = await prisma.activity_logs.findMany({
    where: activityFilter,
    take: 10,
    orderBy: { created_at: 'desc' },
    include: { profile: { select: { username: true } } }
  });

  return {
    total_classes: classesCount,
    total_students: studentsCount,
    total_teachers: teachersCount,
    recent_activity: recentActivity,
  };
};
