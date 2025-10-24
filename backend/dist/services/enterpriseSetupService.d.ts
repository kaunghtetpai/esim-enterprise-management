interface SetupPhase {
    phase: string;
    status: 'pending' | 'running' | 'completed' | 'failed';
    errors: string[];
    fixed: string[];
    startTime?: Date;
    endTime?: Date;
}
export declare class EnterpriseSetupService {
    private supabase;
    private config;
    private phases;
    runCompleteSetup(): Promise<{
        success: boolean;
        phases: SetupPhase[];
        summary: any;
    }>;
    validateCurrentSetup(): Promise<{
        valid: boolean;
        issues: string[];
        recommendations: string[];
    }>;
    getSetupStatus(): Promise<SetupPhase[]>;
    runPhase(phaseNumber: number): Promise<SetupPhase>;
    createCarrierGroups(): Promise<{
        created: string[];
        existing: string[];
        errors: string[];
    }>;
    createCompliancePolicies(): Promise<{
        created: string[];
        existing: string[];
        errors: string[];
    }>;
    configureCompanyPortal(): Promise<{
        success: boolean;
        message: string;
    }>;
    private parseSetupResults;
    private parseValidationResults;
    private extractPhaseFromLine;
    private storeSetupResults;
}
export declare const enterpriseSetupService: EnterpriseSetupService;
export {};
//# sourceMappingURL=enterpriseSetupService.d.ts.map