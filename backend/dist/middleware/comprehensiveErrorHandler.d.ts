import { Request, Response, NextFunction } from 'express';
interface ErrorMetrics {
    totalErrors: number;
    errorsByType: Record<string, number>;
    errorsByEndpoint: Record<string, number>;
    lastError: Date;
}
declare class ComprehensiveErrorHandler {
    private static metrics;
    static logError(req: Request, error: any, responseTime?: number): Promise<void>;
    private static updateMetrics;
    static getMetrics(): ErrorMetrics;
    static handleError: (error: any, req: Request, res: Response, next: NextFunction) => Promise<void>;
    private static getUserFriendlyMessage;
}
export declare const requestTracker: (req: Request, res: Response, next: NextFunction) => void;
export declare const responseLogger: (req: Request, res: Response, next: NextFunction) => void;
export declare const healthMonitor: (req: Request, res: Response, next: NextFunction) => Promise<void>;
export declare const inputValidator: (req: Request, res: Response, next: NextFunction) => void;
export declare const securityValidator: (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>>;
export declare const rateLimiter: (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>>;
export { ComprehensiveErrorHandler };
//# sourceMappingURL=comprehensiveErrorHandler.d.ts.map