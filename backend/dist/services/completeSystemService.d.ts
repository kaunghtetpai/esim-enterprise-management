interface SystemStatus {
    github: boolean;
    vercel: boolean;
    database: boolean;
    apis: boolean;
    sync: boolean;
    errors: string[];
}
export declare class CompleteSystemService {
    private supabase;
    checkAllSystems(): Promise<SystemStatus>;
    updateAllData(): Promise<{
        updated: string[];
        errors: string[];
    }>;
    validateAPIs(): Promise<{
        valid: string[];
        invalid: string[];
    }>;
    fixAllIssues(): Promise<{
        fixed: string[];
        failed: string[];
    }>;
    createSystemBackup(): Promise<{
        success: boolean;
        backupId?: string;
    }>;
    deleteOldData(days?: number): Promise<{
        deleted: number;
    }>;
    clearAllErrors(): Promise<{
        cleared: number;
    }>;
    private checkSync;
    private getAllSystemData;
}
export declare const completeSystemService: CompleteSystemService;
export {};
//# sourceMappingURL=completeSystemService.d.ts.map