interface SystemError {
    id: string;
    type: 'database' | 'api' | 'auth' | 'network' | 'file' | 'memory' | 'disk';
    severity: 'low' | 'medium' | 'high' | 'critical';
    message: string;
    details: any;
    timestamp: Date;
    resolved: boolean;
    autoFixAttempted: boolean;
}
interface SystemHealth {
    overall: 'healthy' | 'warning' | 'critical';
    database: boolean;
    api: boolean;
    auth: boolean;
    network: boolean;
    disk: number;
    memory: number;
    errors: SystemError[];
}
export declare class SystemErrorService {
    private supabase;
    private errors;
    checkSystemHealth(): Promise<SystemHealth>;
    private checkDatabase;
    private checkAPIEndpoints;
    private checkAuthentication;
    private checkNetworkConnectivity;
    private checkSystemResources;
    private calculateOverallHealth;
    private logError;
    private attemptDatabaseFix;
    private attemptAuthFix;
    autoFixErrors(): Promise<{
        fixed: number;
        failed: number;
    }>;
    private cleanupDiskSpace;
    private freeMemory;
    getErrorReport(): Promise<SystemError[]>;
    clearResolvedErrors(): Promise<void>;
}
export declare const systemErrorService: SystemErrorService;
export {};
//# sourceMappingURL=systemErrorService.d.ts.map