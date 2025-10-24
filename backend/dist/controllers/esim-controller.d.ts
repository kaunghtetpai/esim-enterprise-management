import { Request, Response } from 'express';
import { ESIMProfileService } from '../services/esim-profile-service';
import { IntuneService } from '../services/intune-service';
import { AuditService } from '../services/audit-service';
export declare class ESIMController {
    private esimService;
    private intuneService;
    private auditService;
    constructor(esimService: ESIMProfileService, intuneService: IntuneService, auditService: AuditService);
    getProfiles(req: Request, res: Response): Promise<void>;
    createProfile(req: Request, res: Response): Promise<void>;
    updateProfile(req: Request, res: Response): Promise<void>;
    deleteProfile(req: Request, res: Response): Promise<void>;
    assignProfileToDevice(req: Request, res: Response): Promise<void>;
    removeProfileFromDevice(req: Request, res: Response): Promise<void>;
    migrateProfile(req: Request, res: Response): Promise<void>;
    bulkActivation(req: Request, res: Response): Promise<void>;
    getActivationStatus(req: Request, res: Response): Promise<void>;
    getDashboardStats(req: Request, res: Response): Promise<void>;
}
//# sourceMappingURL=esim-controller.d.ts.map