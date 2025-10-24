"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.IntuneService = void 0;
const microsoft_graph_client_1 = require("@microsoft/microsoft-graph-client");
class IntuneService {
    constructor(authProvider) {
        this.graphClient = microsoft_graph_client_1.Client.initWithMiddleware({ authProvider });
    }
    // Device Management
    async getDevices(tenantId) {
        try {
            const response = await this.graphClient
                .api('/deviceManagement/managedDevices')
                .select('id,deviceName,managedDeviceOwnerType,enrolledDateTime,lastSyncDateTime,complianceState,operatingSystem,osVersion,model,manufacturer,serialNumber,imei,userId,userDisplayName,userPrincipalName')
                .get();
            return response.value;
        }
        catch (error) {
            throw new Error(`Failed to fetch devices: ${error.message}`);
        }
    }
    async getDevice(deviceId) {
        try {
            return await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}`)
                .get();
        }
        catch (error) {
            throw new Error(`Failed to fetch device ${deviceId}: ${error.message}`);
        }
    }
    async syncDevice(deviceId) {
        try {
            await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}/syncDevice`)
                .post({});
        }
        catch (error) {
            throw new Error(`Failed to sync device ${deviceId}: ${error.message}`);
        }
    }
    // User Management
    async getUsers(tenantId) {
        try {
            const response = await this.graphClient
                .api('/users')
                .select('id,userPrincipalName,displayName,jobTitle,mobilePhone,department')
                .filter('accountEnabled eq true')
                .get();
            return response.value;
        }
        catch (error) {
            throw new Error(`Failed to fetch users: ${error.message}`);
        }
    }
    async getUser(userId) {
        try {
            return await this.graphClient
                .api(`/users/${userId}`)
                .select('id,userPrincipalName,displayName,jobTitle,mobilePhone,department')
                .get();
        }
        catch (error) {
            throw new Error(`Failed to fetch user ${userId}: ${error.message}`);
        }
    }
    // eSIM Profile Management via Intune
    async assignESIMProfile(deviceId, profileData) {
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
        }
        catch (error) {
            throw new Error(`Failed to assign eSIM profile to device ${deviceId}: ${error.message}`);
        }
    }
    async removeESIMProfile(deviceId, iccid) {
        try {
            const command = {
                '@odata.type': 'microsoft.graph.eSIMProfileRemoval',
                iccid: iccid
            };
            const response = await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}/removeESIMProfile`)
                .post(command);
            return response.commandId;
        }
        catch (error) {
            throw new Error(`Failed to remove eSIM profile from device ${deviceId}: ${error.message}`);
        }
    }
    // Compliance and Policies
    async getDeviceComplianceStatus(deviceId) {
        try {
            return await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}/deviceCompliancePolicyStates`)
                .get();
        }
        catch (error) {
            throw new Error(`Failed to get compliance status for device ${deviceId}: ${error.message}`);
        }
    }
    async enforceCompliancePolicy(deviceId) {
        try {
            await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}/requestRemoteAssistance`)
                .post({});
        }
        catch (error) {
            throw new Error(`Failed to enforce compliance for device ${deviceId}: ${error.message}`);
        }
    }
    // Device Actions
    async sendCustomNotification(deviceIds, title, message) {
        try {
            const notification = {
                notificationTitle: title,
                notificationBody: message,
                groupsToNotify: deviceIds
            };
            await this.graphClient
                .api('/deviceManagement/sendCustomNotificationToCompanyPortal')
                .post(notification);
        }
        catch (error) {
            throw new Error(`Failed to send notification: ${error.message}`);
        }
    }
    async getDeviceActions(deviceId) {
        try {
            const response = await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}/deviceManagementActions`)
                .get();
            return response.value;
        }
        catch (error) {
            throw new Error(`Failed to get device actions for ${deviceId}: ${error.message}`);
        }
    }
    // Bulk Operations
    async bulkDeviceAction(deviceIds, action) {
        try {
            const bulkAction = {
                deviceIds: deviceIds,
                actionName: action
            };
            return await this.graphClient
                .api('/deviceManagement/managedDevices/bulkDeviceActions')
                .post(bulkAction);
        }
        catch (error) {
            throw new Error(`Failed to perform bulk action ${action}: ${error.message}`);
        }
    }
    // Reporting
    async getDeviceInventoryReport() {
        try {
            return await this.graphClient
                .api('/deviceManagement/reports/getDeviceInventoryReport')
                .post({
                reportName: 'DeviceInventory',
                format: 'json'
            });
        }
        catch (error) {
            throw new Error(`Failed to generate device inventory report: ${error.message}`);
        }
    }
    async getComplianceReport() {
        try {
            return await this.graphClient
                .api('/deviceManagement/reports/getComplianceReport')
                .post({
                reportName: 'DeviceCompliance',
                format: 'json'
            });
        }
        catch (error) {
            throw new Error(`Failed to generate compliance report: ${error.message}`);
        }
    }
}
exports.IntuneService = IntuneService;
