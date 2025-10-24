import { AuthenticationProvider } from '@azure/msal-node';
interface IntuneDevice {
    id: string;
    deviceName: string;
    managedDeviceOwnerType: string;
    enrolledDateTime: string;
    lastSyncDateTime: string;
    complianceState: string;
    operatingSystem: string;
    osVersion: string;
    model: string;
    manufacturer: string;
    serialNumber: string;
    imei: string;
    userId: string;
    userDisplayName: string;
    userPrincipalName: string;
}
interface IntuneUser {
    id: string;
    userPrincipalName: string;
    displayName: string;
    jobTitle: string;
    mobilePhone: string;
    department: string;
}
export declare class IntuneService {
    private graphClient;
    constructor(authProvider: AuthenticationProvider);
    getDevices(tenantId: string): Promise<IntuneDevice[]>;
    getDevice(deviceId: string): Promise<IntuneDevice>;
    syncDevice(deviceId: string): Promise<void>;
    getUsers(tenantId: string): Promise<IntuneUser[]>;
    getUser(userId: string): Promise<IntuneUser>;
    assignESIMProfile(deviceId: string, profileData: any): Promise<string>;
    removeESIMProfile(deviceId: string, iccid: string): Promise<string>;
    getDeviceComplianceStatus(deviceId: string): Promise<any>;
    enforceCompliancePolicy(deviceId: string): Promise<void>;
    sendCustomNotification(deviceIds: string[], title: string, message: string): Promise<void>;
    getDeviceActions(deviceId: string): Promise<any[]>;
    bulkDeviceAction(deviceIds: string[], action: string): Promise<any>;
    getDeviceInventoryReport(): Promise<any>;
    getComplianceReport(): Promise<any>;
}
export {};
//# sourceMappingURL=intune-service.d.ts.map