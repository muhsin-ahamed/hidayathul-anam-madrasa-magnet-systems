import { Request, Response, NextFunction } from 'express';

export const authorize = (roles: string[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      console.log(`JWT role: undefined`);
      console.log(`Required role: ${roles.join(', ')}`);
      console.log(`Authorized: false`);
      return res.status(403).json({ success: false, message: 'User role not authorized' });
    }

    const userRole = req.user.role;
    const allowedRoles = [...roles];

    // Support class_teacher seamlessly
    if (roles.includes('class_teacher') && !allowedRoles.includes('teacher')) {
      allowedRoles.push('teacher');
    }
    if (roles.includes('teacher') && !allowedRoles.includes('class_teacher')) {
      allowedRoles.push('class_teacher');
    }

    const isAuthorized = allowedRoles.includes(userRole);

    console.log(`JWT role: ${userRole}`);
    console.log(`Required role: ${roles.join(', ')}`);
    console.log(`Authorized: ${isAuthorized}`);

    if (!isAuthorized) {
      return res.status(403).json({ success: false, message: 'User role not authorized' });
    }

    next();
  };
};
