"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.IntuneService = void 0;
const microsoft_graph_client_1 = require("@microsoft/microsoft-graph-client");
class IntuneService {
    constructor(authProvider) {
        this.CSP_PATH = './Device/Vendor/MSFT/eUICCs';
        try {
            this.graphClient = microsoft_graph_client_1.Client.initWithMiddleware({ authProvider });
        }
        catch (error) {
            throw new Error(`Failed to initialize Graph client: ${error.message}`);
        }
    }
    async getManagedDevices() {
        try {
            const response = await this.graphClient
                .api('/deviceManagement/managedDevices')
                .select('id,deviceName,operatingSystem,complianceState,managementState,enrolledDateTime')
                .filter("operatingSystem eq 'Windows'")
                .get();
            if (!response || !response.value) {
                throw new Error('Invalid response from Microsoft Graph API');
            }
            return response.value;
        }
        catch (error) {
            throw new Error(`Failed to fetch managed devices: ${error.message}`);
        }
    }
    async getDeviceConfiguration(deviceId) {
        try {
            if (!deviceId || typeof deviceId !== 'string') {
                throw new Error('Valid device ID is required');
            }
            const response = await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}/deviceConfigurationStates`)
                .get();
            if (!response) {
                throw new Error('No configuration found for device');
            }
            return response;
        }
        catch (error) {
            throw new Error(`Failed to get device configuration: ${error.message}`);
        }
    }
    async geteUICCDevices(deviceId) {
        try {
            if (!deviceId) {
                throw new Error('Device ID is required');
            }
            const cspUri = `${this.CSP_PATH}`;
            const response = await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}/deviceConfigurationStates`)
                .filter(`settingName eq '${cspUri}'`)
                .get();
            if (!response || !response.value) {
                return [];
            }
            return this.parseeUICCData(response.value);
        }
        catch (error) {
            throw new Error(`Failed to get eUICC devices: ${error.message}`);
        }
    }
    async configureeSIMProfile(deviceId, profileConfig) {
        try {
            if (!deviceId || !profileConfig) {
                throw new Error('Device ID and profile configuration are required');
            }
            const { ICCID, serverName, activationCode } = profileConfig;
            if (!ICCID || !serverName) {
                throw new Error('ICCID and server name are required');
            }
            const configPayload = {
                '@odata.type': '#microsoft.graph.windows10EsimConfiguration',
                displayName: `eSIM Profile - ${ICCID}`,
                description: 'eSIM profile configuration via Intune',
                activationCode: activationCode || '',
                cellularData: {
                    apn: profileConfig.apn || '',
                    username: profileConfig.username || '',
                    password: profileConfig.password || ''
                }
            };
            const response = await this.graphClient
                .api('/deviceManagement/deviceConfigurations')
                .post(configPayload);
            if (!response || !response.id) {
                throw new Error('Failed to create eSIM configuration');
            }
            await this.assignConfigurationToDevice(response.id, deviceId);
            return true;
        }
        catch (error) {
            throw new Error(`Failed to configure eSIM profile: ${error.message}`);
        }
    }
    async reseteSIMToFactory(deviceId, eUICCId) {
        try {
            if (!deviceId || !eUICCId) {
                throw new Error('Device ID and eUICC ID are required');
            }
            const resetPayload = {
                '@odata.type': '#microsoft.graph.deviceAction',
                actionName: 'resetToFactoryState',
                deviceIds: [deviceId],
                parameters: {
                    eUICCId: eUICCId
                }
            };
            const response = await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}/resetToFactoryState`)
                .post(resetPayload);
            return response ? true : false;
        }
        catch (error) {
            throw new Error(`Failed to reset eSIM to factory state: ${error.message}`);
        }
    }
    async geteSIMProfileStatus(deviceId, ICCID) {
        try {
            if (!deviceId || !ICCID) {
                throw new Error('Device ID and ICCID are required');
            }
            const cspPath = `${this.CSP_PATH}/{eUICC}/Profiles/${ICCID}`;
            const response = await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}/deviceConfigurationStates`)
                .filter(`settingName eq '${cspPath}'`)
                .get();
            if (!response || !response.value || response.value.length === 0) {
                throw new Error('Profile not found');
            }
            return this.parseProfileStatus(response.value[0]);
        }
        catch (error) {
            throw new Error(`Failed to get eSIM profile status: ${error.message}`);
        }
    }
    async enableeSIMProfile(deviceId, ICCID) {
        try {
            if (!deviceId || !ICCID) {
                throw new Error('Device ID and ICCID are required');
            }
            const enablePayload = {
                '@odata.type': '#microsoft.graph.deviceAction',
                actionName: 'enableProfile',
                deviceIds: [deviceId],
                parameters: {
                    ICCID: ICCID,
                    isEnabled: true
                }
            };
            const response = await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}/enableeSIMProfile`)
                .post(enablePayload);
            return response ? true : false;
        }
        catch (error) {
            throw new Error(`Failed to enable eSIM profile: ${error.message}`);
        }
    }
    async disableeSIMProfile(deviceId, ICCID) {
        try {
            if (!deviceId || !ICCID) {
                throw new Error('Device ID and ICCID are required');
            }
            const disablePayload = {
                '@odata.type': '#microsoft.graph.deviceAction',
                actionName: 'disableProfile',
                deviceIds: [deviceId],
                parameters: {
                    ICCID: ICCID,
                    isEnabled: false
                }
            };
            const response = await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}/disableeSIMProfile`)
                .post(disablePayload);
            return response ? true : false;
        }
        catch (error) {
            throw new Error(`Failed to disable eSIM profile: ${error.message}`);
        }
    }
    async getComplianceStatus(deviceId) {
        try {
            if (!deviceId) {
                throw new Error('Device ID is required');
            }
            const response = await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}/deviceCompliancePolicyStates`)
                .get();
            if (!response) {
                throw new Error('No compliance data found');
            }
            return {
                complianceState: response.complianceState || 'unknown',
                lastReportedDateTime: response.lastReportedDateTime,
                policies: response.value || []
            };
        }
        catch (error) {
            throw new Error(`Failed to get compliance status: ${error.message}`);
        }
    }
    async assignConfigurationToDevice(configId, deviceId) {
        try {
            const assignmentPayload = {
                assignments: [{
                        '@odata.type': '#microsoft.graph.deviceConfigurationAssignment',
                        target: {
                            '@odata.type': '#microsoft.graph.deviceAndAppManagementAssignmentTarget',
                            deviceAndAppManagementAssignmentFilterId: null,
                            deviceAndAppManagementAssignmentFilterType: 'none'
                        }
                    }]
            };
            await this.graphClient
                .api(`/deviceManagement/deviceConfigurations/${configId}/assign`)
                .post(assignmentPayload);
        }
        catch (error) {
            throw new Error(`Failed to assign configuration: ${error.message}`);
        }
    }
    parseeUICCData(rawData) {
        try {
            return rawData.map(item => ({
                eUICC: item.eUICC || '',
                actions: {
                    resetToFactoryState: item.actions?.resetToFactoryState || false,
                    status: item.actions?.status || 'unknown'
                },
                downloadServers: item.downloadServers || [],
                policies: {
                    localUIEnabled: item.policies?.localUIEnabled || false,
                    PPR1Allowed: item.policies?.PPR1Allowed || false,
                    PPR1AlreadySet: item.policies?.PPR1AlreadySet || false
                },
                profiles: item.profiles || []
            }));
        }
        catch (error) {
            throw new Error(`Failed to parse eUICC data: ${error.message}`);
        }
    }
    parseProfileStatus(rawStatus) {
        try {
            return {
                ICCID: rawStatus.ICCID || '',
                isEnabled: rawStatus.isEnabled || false,
                state: rawStatus.state || 'unknown',
                errorDetail: rawStatus.errorDetail || '',
                matchingID: rawStatus.matchingID || '',
                PPR1Set: rawStatus.PPR1Set || false,
                PPR2Set: rawStatus.PPR2Set || false,
                serverName: rawStatus.serverName || ''
            };
        }
        catch (error) {
            throw new Error(`Failed to parse profile status: ${error.message}`);
        }
    }
    async syncDeviceWithIntune(deviceId) {
        try {
            if (!deviceId) {
                throw new Error('Device ID is required');
            }
            const response = await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}/syncDevice`)
                .post({});
            return response ? true : false;
        }
        catch (error) {
            throw new Error(`Failed to sync device: ${error.message}`);
        }
    }
    async getDeviceActions(deviceId) {
        try {
            if (!deviceId) {
                throw new Error('Device ID is required');
            }
            const response = await this.graphClient
                .api(`/deviceManagement/managedDevices/${deviceId}/deviceActionResults`)
                .get();
            return response?.value || [];
        }
        catch (error) {
            throw new Error(`Failed to get device actions: ${error.message}`);
        }
    }
}
exports.IntuneService = IntuneService;
//# sourceMappingURL=intuneService.js.map