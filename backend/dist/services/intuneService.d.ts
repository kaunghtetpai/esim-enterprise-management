import { AuthenticationProvider } from '@azure/msal-node';
interface eUICCDevice {
    eUICC: string;
    actions: {
        resetToFactoryState: boolean;
        status: string;
    };
    downloadServers: DownloadServer[];
    policies: {
        localUIEnabled: boolean;
        PPR1Allowed: boolean;
        PPR1AlreadySet: boolean;
    };
    profiles: eUICCProfile[];
}
interface DownloadServer {
    serverName: string;
    autoEnable: boolean;
    discoveryState: string;
    ICCID: string;
    isDiscoveryServer: boolean;
    maximumAttempts: number;
    identifier: string;
    isActive: boolean;
}
interface eUICCProfile {
    ICCID: string;
    errorDetail: string;
    isEnabled: boolean;
    matchingID: string;
    PPR1Set: boolean;
    PPR2Set: boolean;
    serverName: string;
    state: string;
}
export declare class IntuneService {
    private graphClient;
    private readonly CSP_PATH;
    constructor(authProvider: AuthenticationProvider);
    getManagedDevices(): Promise<any[]>;
    getDeviceConfiguration(deviceId: string): Promise<any>;
    geteUICCDevices(deviceId: string): Promise<eUICCDevice[]>;
    configureeSIMProfile(deviceId: string, profileConfig: any): Promise<boolean>;
    reseteSIMToFactory(deviceId: string, eUICCId: string): Promise<boolean>;
    geteSIMProfileStatus(deviceId: string, ICCID: string): Promise<any>;
    enableeSIMProfile(deviceId: string, ICCID: string): Promise<boolean>;
    disableeSIMProfile(deviceId: string, ICCID: string): Promise<boolean>;
    getComplianceStatus(deviceId: string): Promise<any>;
    private assignConfigurationToDevice;
    private parseeUICCData;
    private parseProfileStatus;
    syncDeviceWithIntune(deviceId: string): Promise<boolean>;
    getDeviceActions(deviceId: string): Promise<any[]>;
}
export {};
//# sourceMappingURL=intuneService.d.ts.map