interface DeploymentError {
    id?: string;
    platform: 'github' | 'vercel' | 'azure' | 'intune';
    error_type: string;
    error_message: string;
    status: 'active' | 'resolved' | 'ignored';
    created_at?: string;
    resolved_at?: string;
}
interface DeploymentStatus {
    platform: string;
    status: 'healthy' | 'error' | 'warning';
    last_check: string;
    error_count: number;
}
export declare class DeploymentErrorService {
    checkAllDeployments(): Promise<DeploymentStatus[]>;
    private checkGitHub;
    private checkVercel;
    private checkAzure;
    private checkIntune;
    logError(platform: string, errorType: string, message: string): Promise<void>;
    resolveError(errorId: string): Promise<void>;
    getActiveErrors(): Promise<DeploymentError[]>;
    private getErrorCount;
    private logDeploymentCheck;
    syncAllPlatforms(): Promise<{
        success: boolean;
        message: string;
    }>;
    private syncGitHub;
    private syncVercel;
    private syncAzure;
    private syncIntune;
}
export {};
//# sourceMappingURL=deploymentErrorService.d.ts.map