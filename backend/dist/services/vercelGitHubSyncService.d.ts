interface SyncStatus {
    github: {
        connected: boolean;
        repo: string;
        branch: string;
        lastCommit: string;
    };
    vercel: {
        connected: boolean;
        project: string;
        deployments: any[];
        lastDeploy: string;
    };
    sync: {
        status: 'synced' | 'drift' | 'error';
        issues: string[];
        lastSync: Date;
    };
}
export declare class VercelGitHubSyncService {
    private supabase;
    checkSyncStatus(): Promise<SyncStatus>;
    updateAllData(): Promise<{
        updated: string[];
        errors: string[];
    }>;
    validateAPIs(): Promise<{
        valid: string[];
        invalid: string[];
    }>;
    fixSyncIssues(): Promise<{
        fixed: string[];
        failed: string[];
    }>;
    private logSyncStatus;
}
export declare const vercelGitHubSyncService: VercelGitHubSyncService;
export {};
//# sourceMappingURL=vercelGitHubSyncService.d.ts.map