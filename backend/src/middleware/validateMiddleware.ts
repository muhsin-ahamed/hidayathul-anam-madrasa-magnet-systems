import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';

export const validate = (schema: ZodSchema) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    console.log(`[VALIDATION INPUT] ${req.method} ${req.originalUrl} body:`, JSON.stringify(req.body, null, 2));
    try {
      await schema.parseAsync({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      next();
    } catch (error: any) {
      if (error instanceof ZodError) {
        const issues = error.issues || (error as any).errors || [];
        const formattedErrors = issues.map((issue: any) => ({
          field: (issue.path || []).filter((p: any) => p !== 'body').join('.'),
          message: issue.message,
        }));

        console.error(`[ZOD VALIDATION ERROR] ${req.method} ${req.originalUrl}:`, JSON.stringify(formattedErrors, null, 2));

        const mainMessage = formattedErrors.length > 0 ? formattedErrors[0].message : 'Validation failed';

        return res.status(400).json({
          success: false,
          message: mainMessage,
          errors: formattedErrors,
          details: typeof error.flatten === 'function' ? error.flatten() : issues,
        });
      }

      console.error(`[VALIDATION ERROR] ${req.method} ${req.originalUrl}:`, error);
      return res.status(400).json({
        success: false,
        message: error.message || 'Validation error',
        errors: (error.issues || error.errors || [error.message]).map((i: any) =>
          typeof i === 'string' ? { message: i } : { field: (i.path || []).filter((p: any) => p !== 'body').join('.'), message: i.message }
        ),
      });
    }
  };
};
