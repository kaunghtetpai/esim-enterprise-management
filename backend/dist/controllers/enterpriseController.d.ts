import { Request, Response } from 'express';
export declare class EnterpriseController {
    runCompleteSetup(req: Request, res: Response): Promise<void>;
    validateSetup(req: Request, res: Response): Promise<void>;
    getSetupStatus(req: Request, res: Response): Promise<void>;
    runPhase(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    createCarrierGroups(req: Request, res: Response): Promise<void>;
    createCompliancePolicies(req: Request, res: Response): Promise<void>;
    configureCompanyPortal(req: Request, res: Response): Promise<void>;
}
export declare const enterpriseController: EnterpriseController;
//# sourceMappingURL=enterpriseController.d.ts.map