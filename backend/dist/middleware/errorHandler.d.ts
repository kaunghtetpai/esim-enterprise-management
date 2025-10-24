import { Request, Response, NextFunction } from 'express';
export declare class AppError extends Error {
    statusCode: number;
    code: string;
    isOperational: boolean;
    constructor(message: string, statusCode: number, code?: string);
}
export declare const handleDatabaseError: (error: any) => AppError;
export declare const asyncHandler: (fn: Function) => (req: Request, res: Response, next: NextFunction) => void;
export declare const globalErrorHandler: (err: any, req: Request, res: Response, next: NextFunction) => void;
export declare const notFoundHandler: (req: Request, res: Response, next: NextFunction) => void;
export declare const handleUnhandledRejection: () => void;
export declare const handleUncaughtException: () => void;
export declare const timeoutHandler: (timeout?: number) => (req: Request, res: Response, next: NextFunction) => void;
export declare const rateLimitHandler: (req: Request, res: Response) => void;
export declare const corsErrorHandler: (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>>;
//# sourceMappingURL=errorHandler.d.ts.map