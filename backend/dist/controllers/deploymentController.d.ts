import { Request, Response } from 'express';
export declare const deploymentController: {
    checkAllDeployments(req: Request, res: Response): Promise<void>;
    getActiveErrors(req: Request, res: Response): Promise<void>;
    resolveError(req: Request, res: Response): Promise<void>;
    syncAllPlatforms(req: Request, res: Response): Promise<void>;
    logError(req: Request, res: Response): Promise<void>;
};
//# sourceMappingURL=deploymentController.d.ts.map