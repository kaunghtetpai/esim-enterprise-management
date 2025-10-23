import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';
import { query } from '../config/database';

const execAsync = promisify(exec);

interface GraphError {
  code: string;
  message: string;
  details?: any;
}

interface DeviceInfo {
  id: string;
  deviceName: string;
  operatingSystem: string;
  complianceState: string;
  lastSyncDateTime: string;
  enrollmentType: string;
  managementAgent: string;
}

interface ProfileStatus {
  settingName: string;
  state: string;
  errorDescription?: string;
  lastReportedDateTime: string;
}

export class GraphPowerShellService {
  private scriptsPath: string;
  private isConnected: boolean = false;

  constructor() {
    this.scriptsPath = path.join(process.cwd(), 'scripts');
  }

  async connectToGraph(tenantId: string, clientId: string, clientSecret?: string): Promise<boolean> {
    try {
      if (!tenantId || typeof tenantId !== 'string' || tenantId.trim().length === 0) {
        throw new Error('Valid tenant ID is required');
      }
      
      if (!clientId || typeof clientId !== 'string' || clientId.trim().length === 0) {
        throw new Error('Valid client ID is required');
      }
      
      // Validate tenant ID format (GUID)
      const guidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
      if (!guidRegex.test(tenantId)) {
        throw new Error('Tenant ID must be a valid GUID format');
      }
      
      if (!guidRegex.test(clientId)) {
        throw new Error('Client ID must be a valid GUID format');
      }

      const scriptPath = path.join(this.scriptsPath, 'Connect-GraphAPI.ps1');
      
      // Verify script exists
      const fs = require('fs');
      if (!fs.existsSync(scriptPath)) {
        throw new Error('Graph API connection script not found');
      }
      
      let command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" -TenantId "${tenantId}" -ClientId "${clientId}"`;
      
      if (clientSecret) {
        if (clientSecret.length < 8) {
          throw new Error('Client secret must be at least 8 characters');
        }
        command += ` -ClientSecret "${clientSecret}"`;
      } else {
        command += ' -Interactive';
      }

      const { stdout, stderr } = await execAsync(command, { timeout: 60000 });
      
      if (stderr && !stderr.includes('WARNING') && !stderr.includes('VERBOSE')) {
        await this.logError('GRAPH_CONNECTION_ERROR', stderr, { tenantId, clientId });
        throw new Error(`PowerShell execution error: ${stderr}`);
      }

      this.isConnected = stdout.includes('Connected to Microsoft Graph successfully');
      
      if (this.isConnected) {
        await this.logSuccess('GRAPH_CONNECTED', 'Successfully connected to Microsoft Graph', { tenantId });
      } else {
        await this.logError('GRAPH_CONNECTION_FAILED', 'Connection attempt did not succeed', { tenantId, clientId });
      }
      
      return this.isConnected;
    } catch (error) {
      await this.logError('GRAPH_CONNECTION_EXCEPTION', error.message, { tenantId, clientId });
      throw new Error(`Failed to connect to Microsoft Graph: ${error.message}`);
    }
  }

  async getManagedDevices(): Promise<DeviceInfo[]> {
    if (!this.isConnected) {
      throw new Error('Not connected to Microsoft Graph. Please connect first.');
    }

    try {
      const scriptPath = path.join(this.scriptsPath, 'Manage-eSIMProfiles.ps1');
      
      // Verify script exists
      const fs = require('fs');
      if (!fs.existsSync(scriptPath)) {
        throw new Error('eSIM management script not found');
      }
      
      const command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" -Action List`;

      const { stdout, stderr } = await execAsync(command, { timeout: 30000 });
      
      if (stderr && !stderr.includes('WARNING') && !stderr.includes('VERBOSE')) {
        await this.logError('DEVICE_LIST_ERROR', stderr);
        throw new Error(`PowerShell execution error: ${stderr}`);
      }
      
      if (!stdout || stdout.trim().length === 0) {
        await this.logError('DEVICE_LIST_EMPTY', 'No output received from device list command');
        return [];
      }

      const devices = this.parseDeviceOutput(stdout);
      await this.logSuccess('DEVICE_LIST_SUCCESS', `Retrieved ${devices.length} managed devices`);
      
      return devices;
    } catch (error) {
      await this.logError('DEVICE_LIST_EXCEPTION', error.message);
      throw new Error(`Failed to get managed devices: ${error.message}`);
    }
  }

  async createeSIMProfile(profileName: string, iccid: string, carrier: string, activationCode?: string): Promise<string> {
    if (!this.isConnected) {
      throw new Error('Not connected to Microsoft Graph. Please connect first.');
    }

    try {
      // Validate inputs
      if (!profileName || typeof profileName !== 'string' || profileName.trim().length === 0) {
        throw new Error('Valid profile name is required');
      }
      
      if (!iccid || !/^\d{19,20}$/.test(iccid)) {
        throw new Error('ICCID must be 19-20 digits');
      }
      
      const validCarriers = ['MPT', 'ATOM', 'U9', 'MYTEL'];
      if (!carrier || !validCarriers.includes(carrier)) {
        throw new Error(`Carrier must be one of: ${validCarriers.join(', ')}`);
      }
      
      if (profileName.length > 100) {
        throw new Error('Profile name must be 100 characters or less');
      }
      
      if (activationCode && (activationCode.length < 10 || activationCode.length > 200)) {
        throw new Error('Activation code must be between 10 and 200 characters');
      }

      const scriptPath = path.join(this.scriptsPath, 'Manage-eSIMProfiles.ps1');
      
      // Verify script exists
      const fs = require('fs');
      if (!fs.existsSync(scriptPath)) {
        throw new Error('eSIM management script not found');
      }
      
      let command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" -Action Create -ProfileName "${profileName}" -ICCID "${iccid}" -Carrier "${carrier}"`;
      
      if (activationCode) {
        command += ` -ActivationCode "${activationCode}"`;
      }

      const { stdout, stderr } = await execAsync(command, { timeout: 60000 });
      
      if (stderr && !stderr.includes('WARNING') && !stderr.includes('VERBOSE')) {
        await this.logError('PROFILE_CREATE_ERROR', stderr, { profileName, iccid, carrier });
        throw new Error(`PowerShell execution error: ${stderr}`);
      }
      
      if (!stdout || stdout.trim().length === 0) {
        await this.logError('PROFILE_CREATE_NO_OUTPUT', 'No output received from profile creation', { profileName, iccid });
        throw new Error('No response received from profile creation');
      }

      const profileId = this.extractProfileId(stdout);
      
      if (!profileId) {
        await this.logError('PROFILE_CREATE_NO_ID', 'Profile ID not found in output', { profileName, iccid, stdout });
        throw new Error('Profile creation may have failed - no profile ID returned');
      }
      
      await this.logSuccess('PROFILE_CREATE_SUCCESS', `eSIM profile created successfully`, { profileName, iccid, carrier, profileId });
      
      return profileId;
    } catch (error) {
      await this.logError('PROFILE_CREATE_EXCEPTION', error.message, { profileName, iccid, carrier });
      throw new Error(`Failed to create eSIM profile: ${error.message}`);
    }
  }

  async deployeSIMProfile(deviceId: string, profileId: string): Promise<boolean> {
    if (!this.isConnected) {
      throw new Error('Not connected to Microsoft Graph');
    }

    try {
      const scriptPath = path.join(this.scriptsPath, 'Manage-eSIMProfiles.ps1');
      const command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" -Action Deploy -DeviceId "${deviceId}" -ICCID "${profileId}"`;

      const { stdout, stderr } = await execAsync(command);
      
      if (stderr && !stderr.includes('WARNING')) {
        throw new Error(`PowerShell error: ${stderr}`);
      }

      return stdout.includes('deployed successfully');
    } catch (error) {
      throw new Error(`Failed to deploy eSIM profile: ${error.message}`);
    }
  }

  async removeeSIMProfile(deviceId: string, iccid: string): Promise<boolean> {
    if (!this.isConnected) {
      throw new Error('Not connected to Microsoft Graph');
    }

    try {
      const scriptPath = path.join(this.scriptsPath, 'Manage-eSIMProfiles.ps1');
      const command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" -Action Remove -DeviceId "${deviceId}" -ICCID "${iccid}"`;

      const { stdout, stderr } = await execAsync(command);
      
      if (stderr && !stderr.includes('WARNING')) {
        throw new Error(`PowerShell error: ${stderr}`);
      }

      return stdout.includes('removed successfully');
    } catch (error) {
      throw new Error(`Failed to remove eSIM profile: ${error.message}`);
    }
  }

  async geteSIMStatus(deviceId: string, iccid: string): Promise<any> {
    if (!this.isConnected) {
      throw new Error('Not connected to Microsoft Graph');
    }

    try {
      const scriptPath = path.join(this.scriptsPath, 'Manage-eSIMProfiles.ps1');
      const command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" -Action Status -DeviceId "${deviceId}" -ICCID "${iccid}"`;

      const { stdout, stderr } = await execAsync(command);
      
      if (stderr && !stderr.includes('WARNING')) {
        throw new Error(`PowerShell error: ${stderr}`);
      }

      return this.parseStatusOutput(stdout);
    } catch (error) {
      throw new Error(`Failed to get eSIM status: ${error.message}`);
    }
  }

  async installGraphSDK(useBeta: boolean = false): Promise<boolean> {
    try {
      const scriptPath = path.join(this.scriptsPath, 'Install-GraphSDK.ps1');
      let command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" -Force`;
      
      if (useBeta) {
        command += ' -Beta';
      }

      const { stdout, stderr } = await execAsync(command, { timeout: 300000 }); // 5 minute timeout
      
      if (stderr && !stderr.includes('WARNING')) {
        throw new Error(`PowerShell error: ${stderr}`);
      }

      return stdout.includes('installed successfully');
    } catch (error) {
      throw new Error(`Failed to install Graph SDK: ${error.message}`);
    }
  }

  private parseDeviceOutput(output: string): any[] {
    const lines = output.split('\n').filter(line => line.trim());
    const devices: any[] = [];
    
    for (let i = 2; i < lines.length; i++) { // Skip header lines
      const parts = lines[i].split(/\s+/);
      if (parts.length >= 5) {
        devices.push({
          id: parts[0],
          deviceName: parts[1],
          operatingSystem: parts[2],
          complianceState: parts[3],
          lastSyncDateTime: parts[4]
        });
      }
    }
    
    return devices;
  }

  private extractProfileId(output: string): string {
    const match = output.match(/ID:\s*([a-f0-9-]+)/i);
    return match ? match[1] : '';
  }

  private parseStatusOutput(output: string): any {
    const lines = output.split('\n').filter(line => line.trim());
    const status: any = {};
    
    for (const line of lines) {
      if (line.includes(':')) {
        const [key, value] = line.split(':').map(s => s.trim());
        status[key.toLowerCase().replace(/\s+/g, '_')] = value;
      }
    }
    
    return status;
  }

  private async logError(code: string, message: string, details?: any): Promise<void> {
    try {
      await query(`
        INSERT INTO system_error_logs (timestamp, method, url, error_details, request_data)
        VALUES ($1, $2, $3, $4, $5)
      `, [
        new Date().toISOString(),
        'GRAPH_POWERSHELL',
        'graph-service',
        JSON.stringify({ code, message }),
        JSON.stringify(details || {})
      ]);
    } catch (logError) {
      console.error('Failed to log Graph service error:', logError);
    }
  }
  
  private async logSuccess(code: string, message: string, details?: any): Promise<void> {
    try {
      await query(`
        INSERT INTO api_request_logs (timestamp, method, url, status_code, request_id)
        VALUES ($1, $2, $3, $4, $5)
      `, [
        new Date().toISOString(),
        'GRAPH_POWERSHELL',
        'graph-service',
        200,
        `${code}_${Date.now()}`
      ]);
    } catch (logError) {
      console.error('Failed to log Graph service success:', logError);
    }
  }

  async validateConnection(): Promise<boolean> {
    if (!this.isConnected) {
      return false;
    }
    
    try {
      // Test connection with a simple Graph call
      const command = 'powershell.exe -Command "Get-MgContext | Select-Object TenantId, Account"';
      const { stdout, stderr } = await execAsync(command, { timeout: 10000 });
      
      if (stderr && !stderr.includes('WARNING')) {
        this.isConnected = false;
        return false;
      }
      
      return stdout.includes('TenantId');
    } catch (error) {
      this.isConnected = false;
      await this.logError('CONNECTION_VALIDATION_FAILED', error.message);
      return false;
    }
  }

  async getConnectionStatus(): Promise<{ connected: boolean; context?: any }> {
    try {
      if (!this.isConnected) {
        return { connected: false };
      }
      
      const command = 'powershell.exe -Command "Get-MgContext | ConvertTo-Json"';
      const { stdout, stderr } = await execAsync(command, { timeout: 10000 });
      
      if (stderr && !stderr.includes('WARNING')) {
        this.isConnected = false;
        return { connected: false };
      }
      
      try {
        const context = JSON.parse(stdout);
        return { connected: true, context };
      } catch (parseError) {
        return { connected: true };
      }
    } catch (error) {
      this.isConnected = false;
      return { connected: false };
    }
  }

  disconnect(): void {
    try {
      // Attempt to disconnect from Graph
      execAsync('powershell.exe -Command "Disconnect-MgGraph"', { timeout: 5000 })
        .catch(error => console.warn('Graph disconnect warning:', error.message));
    } catch (error) {
      console.warn('Graph disconnect error:', error.message);
    } finally {
      this.isConnected = false;
    }
  }
}