interface DiagnosticResult {
    component: string;
    status: 'healthy' | 'warning' | 'error';
    message: string;
    details?: any;
    timestamp: string;
}
export declare class DiagnosticService {
    runFullDiagnostic(): Promise<DiagnosticResult[]>;
    private checkDatabase;
    private checkGraphConnection;
    private checkSystemResources;
    private checkNetworkConnectivity;
    private checkPowerShellModules;
    private checkErrorRates;
    private checkDiskSpace;
    private checkServices;
    solveProblem(component: string, issue: string): Promise<{
        success: boolean;
        message: string;
        actions: string[];
    }>;
    private solveDatabaseIssues;
    private solveGraphIssues;
    private solveResourceIssues;
    private solveNetworkIssues;
    private solvePowerShellIssues;
    private solveErrorRateIssues;
    private solveDiskSpaceIssues;
    private solveServiceIssues;
}
export {};
//# sourceMappingURL=diagnosticService.d.ts.map