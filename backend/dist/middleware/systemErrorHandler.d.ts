import { Request, Response, NextFunction } from 'express';
export declare class SystemError extends Error {
    statusCode: number;
    code: string;
    details?: any;
    constructor(message: string, statusCode?: number, code?: string, details?: any);
}
export declare const systemHealthCheck: (req: Request, res: Response, next: NextFunction) => Promise<Response<any, Record<string, any>>>;
export declare const requestValidator: (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>>;
export declare const rateLimitHandler: (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>>;
export declare const securityHeaders: (req: Request, res: Response, next: NextFunction) => void;
export declare const errorLogger: (error: any, req: Request, res: Response, next: NextFunction) => void;
//# sourceMappingURL=systemErrorHandler.d.ts.map