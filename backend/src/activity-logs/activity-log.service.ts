import { prisma } from '../config/db';

export const getActivityLogsService = async (user: any, requestedClassId?: string) => {
  try {
    if (user?.role === 'super_admin') {
      const whereClause = requestedClassId ? { class_id: requestedClassId } : {};
      return await prisma.activity_logs.findMany({
        where: whereClause,
        include: {
          profile: { select: { username: true, role: true } }
        },
        orderBy: { created_at: 'desc' },
        take: 100
      });
    }

    let assignedClassId: string | null = null;
    const teacherClass = await prisma.classes.findFirst({
      where: { class_teacher_id: user?.id }
    });

    if (teacherClass) {
      assignedClassId = teacherClass.id;
    }

    const targetClassId = requestedClassId || assignedClassId;
    const whereClause: any = {};
    if (targetClassId) {
      whereClause.OR = [
        { class_id: targetClassId },
        { user_id: user?.id }
      ];
    } else if (user?.id) {
      whereClause.user_id = user.id;
    }

    return await prisma.activity_logs.findMany({
      where: whereClause,
      include: {
        profile: { select: { username: true, role: true } }
      },
      orderBy: { created_at: 'desc' },
      take: 100
    });
  } catch (_) {
    return [];
  }
};
