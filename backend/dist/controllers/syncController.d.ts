import { Request, Response } from 'express';
export declare class SyncController {
    checkSyncStatus(req: Request, res: Response): Promise<void>;
    updateAllData(req: Request, res: Response): Promise<void>;
    validateAPIs(req: Request, res: Response): Promise<void>;
    fixSyncIssues(req: Request, res: Response): Promise<void>;
    checkAllSystems(req: Request, res: Response): Promise<void>;
    updateAllSystems(req: Request, res: Response): Promise<void>;
    createBackup(req: Request, res: Response): Promise<void>;
    deleteOldData(req: Request, res: Response): Promise<void>;
    clearErrors(req: Request, res: Response): Promise<void>;
}
export declare const syncController: SyncController;
//# sourceMappingURL=syncController.d.ts.map