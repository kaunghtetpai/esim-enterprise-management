import { Client } from '@microsoft/microsoft-graph-client';
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

export class IntuneService {
  private graphClient: Client;

  constructor(authProvider: AuthenticationProvider) {
    this.graphClient = Client.initWithMiddleware({ authProvider });
  }

  // Device Management
  async getDevices(tenantId: string): Promise<IntuneDevice[]> {
    try {
      const response = await this.graphClient
        .api('/deviceManagement/managedDevices')
        .select('id,deviceName,managedDeviceOwnerType,enrolledDateTime,lastSyncDateTime,complianceState,operatingSystem,osVersion,model,manufacturer,serialNumber,imei,userId,userDisplayName,userPrincipalName')
        .get();
      
      return response.value;
    } catch (error) {
      throw new Error(`Failed to fetch devices: ${error.message}`);
    }
  }

  async getDevice(deviceId: string): Promise<IntuneDevice> {
    try {
      return await this.graphClient
        .api(`/deviceManagement/managedDevices/${deviceId}`)
        .get();
    } catch (error) {
      throw new Error(`Failed to fetch device ${deviceId}: ${error.message}`);
    }
  }

  async syncDevice(deviceId: string): Promise<void> {
    try {
      await this.graphClient
        .api(`/deviceManagement/managedDevices/${deviceId}/syncDevice`)
        .post({});
    } catch (error) {
      throw new Error(`Failed to sync device ${deviceId}: ${error.message}`);
    }
  }

  // User Management
  async getUsers(tenantId: string): Promise<IntuneUser[]> {
    try {
      const response = await this.graphClient
        .api('/users')
        .select('id,userPrincipalName,displayName,jobTitle,mobilePhone,department')
        .filter('accountEnabled eq true')
        .get();
      
      return response.value;
    } catch (error) {
      throw new Error(`Failed to fetch users: ${error.message}`);
    }
  }

  async getUser(userId: string): Promise<IntuneUser> {
    try {
      return await this.graphClient
        .api(`/users/${userId}`)
        .select('id,userPrincipalName,displayName,jobTitle,mobilePhone,department')
        .get();
    } catch (error) {
      throw new Error(`Failed to fetch user ${userId}: ${error.message}`);
    }
  }

  // eSIM Profile Management via Intune
  async assignESIMProfile(deviceId: string, profileData: any): Promise<string> {
    try {
      const command = {
        '@odata.type': 'microsoft.graph.eSIMProfileAssignment',
        deviceId: deviceId,
        profileData: profileData,
        activationCode: profileData.activationCode
      };

      const response = await this.graphClient
        .api(`/deviceManagement/managedDevices/${deviceId}/assignESIMProfile`)
        .post(command);

      return response.commandId;
    } catch (error) {
      throw new Error(`Failed to assign eSIM profile to device ${deviceId}: ${error.message}`);
    }
  }

  async removeESIMProfile(deviceId: string, iccid: string): Promise<string> {
    try {
      const command = {
        '@odata.type': 'microsoft.graph.eSIMProfileRemoval',
        iccid: iccid
      };

      const response = await this.graphClient
        .api(`/deviceManagement/managedDevices/${deviceId}/removeESIMProfile`)
        .post(command);

      return response.commandId;
    } catch (error) {
      throw new Error(`Failed to remove eSIM profile from device ${deviceId}: ${error.message}`);
    }
  }

  // Compliance and Policies
  async getDeviceComplianceStatus(deviceId: string): Promise<any> {
    try {
      return await this.graphClient
        .api(`/deviceManagement/managedDevices/${deviceId}/deviceCompliancePolicyStates`)
        .get();
    } catch (error) {
      throw new Error(`Failed to get compliance status for device ${deviceId}: ${error.message}`);
    }
  }

  async enforceCompliancePolicy(deviceId: string): Promise<void> {
    try {
      await this.graphClient
        .api(`/deviceManagement/managedDevices/${deviceId}/requestRemoteAssistance`)
        .post({});
    } catch (error) {
      throw new Error(`Failed to enforce compliance for device ${deviceId}: ${error.message}`);
    }
  }

  // Device Actions
  async sendCustomNotification(deviceIds: string[], title: string, message: string): Promise<void> {
    try {
      const notification = {
        notificationTitle: title,
        notificationBody: message,
        groupsToNotify: deviceIds
      };

      await this.graphClient
        .api('/deviceManagement/sendCustomNotificationToCompanyPortal')
        .post(notification);
    } catch (error) {
      throw new Error(`Failed to send notification: ${error.message}`);
    }
  }

  async getDeviceActions(deviceId: string): Promise<any[]> {
    try {
      const response = await this.graphClient
        .api(`/deviceManagement/managedDevices/${deviceId}/deviceManagementActions`)
        .get();
      
      return response.value;
    } catch (error) {
      throw new Error(`Failed to get device actions for ${deviceId}: ${error.message}`);
    }
  }

  // Bulk Operations
  async bulkDeviceAction(deviceIds: string[], action: string): Promise<any> {
    try {
      const bulkAction = {
        deviceIds: deviceIds,
        actionName: action
      };

      return await this.graphClient
        .api('/deviceManagement/managedDevices/bulkDeviceActions')
        .post(bulkAction);
    } catch (error) {
      throw new Error(`Failed to perform bulk action ${action}: ${error.message}`);
    }
  }

  // Reporting
  async getDeviceInventoryReport(): Promise<any> {
    try {
      return await this.graphClient
        .api('/deviceManagement/reports/getDeviceInventoryReport')
        .post({
          reportName: 'DeviceInventory',
          format: 'json'
        });
    } catch (error) {
      throw new Error(`Failed to generate device inventory report: ${error.message}`);
    }
  }

  async getComplianceReport(): Promise<any> {
    try {
      return await this.graphClient
        .api('/deviceManagement/reports/getComplianceReport')
        .post({
          reportName: 'DeviceCompliance',
          format: 'json'
        });
    } catch (error) {
      throw new Error(`Failed to generate compliance report: ${error.message}`);
    }
  }
}