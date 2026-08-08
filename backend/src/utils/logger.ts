import { prisma } from '../config/db';

export const logActivity = async (
  userId: string | undefined,
  action: string,
  entityType?: string,
  entityId?: string,
  description?: string,
  classId?: string
) => {
  try {
    await prisma.activity_logs.create({
      data: {
        user_id: userId,
        action,
        entity_type: entityType,
        entity_id: entityId,
        description,
        class_id: classId,
      },
    });
  } catch (error) {
    console.error('Failed to log activity:', error);
  }
};
