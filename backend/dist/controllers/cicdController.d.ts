import { Request, Response } from 'express';
export declare class CICDController {
    getDeploymentStatus(req: Request, res: Response): Promise<void>;
    triggerDeployment(req: Request, res: Response): Promise<void>;
    rollbackDeployment(req: Request, res: Response): Promise<void>;
    getCICDMetrics(req: Request, res: Response): Promise<void>;
    validateDeployment(req: Request, res: Response): Promise<void>;
    syncGitHubVercel(req: Request, res: Response): Promise<void>;
}
export declare const cicdController: CICDController;
//# sourceMappingURL=cicdController.d.ts.map