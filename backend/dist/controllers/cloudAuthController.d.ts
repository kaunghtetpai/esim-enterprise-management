import { Request, Response } from 'express';
export declare class CloudAuthController {
    checkAllAuth(req: Request, res: Response): Promise<void>;
    loginGitHub(req: Request, res: Response): Promise<void>;
    loginVercel(req: Request, res: Response): Promise<void>;
    loginMicrosoftGraph(req: Request, res: Response): Promise<void>;
    validateSync(req: Request, res: Response): Promise<void>;
    autoFix(req: Request, res: Response): Promise<void>;
    createCarrierGroups(req: Request, res: Response): Promise<void>;
}
export declare const cloudAuthController: CloudAuthController;
//# sourceMappingURL=cloudAuthController.d.ts.map