interface DeviceInfo {
    id: string;
    deviceName: string;
    operatingSystem: string;
    complianceState: string;
    lastSyncDateTime: string;
    enrollmentType: string;
    managementAgent: string;
}
export declare class GraphPowerShellService {
    private scriptsPath;
    private isConnected;
    constructor();
    connectToGraph(tenantId: string, clientId: string, clientSecret?: string): Promise<boolean>;
    getManagedDevices(): Promise<DeviceInfo[]>;
    createeSIMProfile(profileName: string, iccid: string, carrier: string, activationCode?: string): Promise<string>;
    deployeSIMProfile(deviceId: string, profileId: string): Promise<boolean>;
    removeeSIMProfile(deviceId: string, iccid: string): Promise<boolean>;
    geteSIMStatus(deviceId: string, iccid: string): Promise<any>;
    installGraphSDK(useBeta?: boolean): Promise<boolean>;
    private parseDeviceOutput;
    private extractProfileId;
    private parseStatusOutput;
    private logError;
    private logSuccess;
    validateConnection(): Promise<boolean>;
    getConnectionStatus(): Promise<{
        connected: boolean;
        context?: any;
    }>;
    disconnect(): void;
}
export {};
//# sourceMappingURL=graphPowerShellService.d.ts.map