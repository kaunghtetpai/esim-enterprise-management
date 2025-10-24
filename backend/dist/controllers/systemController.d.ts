import { Request, Response } from 'express';
export declare class SystemController {
    getSystemHealth(req: Request, res: Response): Promise<void>;
    runDiagnostics(req: Request, res: Response): Promise<void>;
    autoFixErrors(req: Request, res: Response): Promise<void>;
    getErrorReport(req: Request, res: Response): Promise<void>;
    clearErrors(req: Request, res: Response): Promise<void>;
    getSystemStatus(req: Request, res: Response): Promise<void>;
}
export declare const systemController: SystemController;
//# sourceMappingURL=systemController.d.ts.map