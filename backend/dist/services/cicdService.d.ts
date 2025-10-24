interface DeploymentStatus {
    id: string;
    status: 'pending' | 'building' | 'ready' | 'error' | 'canceled';
    url?: string;
    createdAt: Date;
    readyAt?: Date;
    buildLogs?: string[];
    errorMessage?: string;
}
interface CICDMetrics {
    deploymentFrequency: number;
    successRate: number;
    averageBuildTime: number;
    failureRate: number;
    lastDeployment: Date;
    totalDeployments: number;
}
export declare class CICDService {
    private supabase;
    getDeploymentStatus(): Promise<DeploymentStatus[]>;
    triggerDeployment(branch?: string): Promise<{
        success: boolean;
        deploymentId?: string;
        error?: string;
    }>;
    rollbackDeployment(deploymentId?: string): Promise<{
        success: boolean;
        message: string;
    }>;
    getCICDMetrics(): Promise<CICDMetrics>;
    validateDeployment(url: string): Promise<{
        healthy: boolean;
        checks: any[];
    }>;
    syncGitHubVercel(): Promise<{
        synced: boolean;
        issues: string[];
    }>;
    private parseVercelOutput;
    private mapVercelStatus;
    private extractDeploymentId;
    private calculateDeploymentFrequency;
    private storeDeploymentStatus;
    private logDeploymentTrigger;
    private logRollback;
}
export declare const cicdService: CICDService;
export {};
//# sourceMappingURL=cicdService.d.ts.map