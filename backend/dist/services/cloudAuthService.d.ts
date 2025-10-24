interface AuthStatus {
    service: string;
    authenticated: boolean;
    user?: string;
    lastCheck: Date;
    error?: string;
}
interface CloudServices {
    github: AuthStatus;
    vercel: AuthStatus;
    microsoftGraph: AuthStatus;
    intune: AuthStatus;
}
export declare class CloudAuthService {
    private supabase;
    checkAllAuthentications(): Promise<CloudServices>;
    private checkGitHubAuth;
    private checkVercelAuth;
    private checkMicrosoftGraphAuth;
    private checkIntuneAuth;
    loginToGitHub(): Promise<{
        success: boolean;
        message: string;
    }>;
    loginToVercel(): Promise<{
        success: boolean;
        message: string;
    }>;
    loginToMicrosoftGraph(): Promise<{
        success: boolean;
        message: string;
    }>;
    validateSystemSync(): Promise<{
        synced: boolean;
        issues: string[];
    }>;
    autoFixAuth(): Promise<{
        fixed: string[];
        failed: string[];
    }>;
    createCarrierGroups(): Promise<{
        created: string[];
        existing: string[];
        errors: string[];
    }>;
    private logAuthStatus;
}
export declare const cloudAuthService: CloudAuthService;
export {};
//# sourceMappingURL=cloudAuthService.d.ts.map