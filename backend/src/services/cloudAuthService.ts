import { exec } from 'child_process';
import { promisify } from 'util';
import { createClient } from '@supabase/supabase-js';

const execAsync = promisify(exec);

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

export class CloudAuthService {
  private supabase = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_ANON_KEY!
  );

  async checkAllAuthentications(): Promise<CloudServices> {
    const services: CloudServices = {
      github: await this.checkGitHubAuth(),
      vercel: await this.checkVercelAuth(),
      microsoftGraph: await this.checkMicrosoftGraphAuth(),
      intune: await this.checkIntuneAuth()
    };

    await this.logAuthStatus(services);
    return services;
  }

  private async checkGitHubAuth(): Promise<AuthStatus> {
    try {
      const { stdout } = await execAsync('gh auth status');
      if (stdout.includes('Logged in')) {
        const { stdout: user } = await execAsync('gh api user --jq .login');
        return {
          service: 'github',
          authenticated: true,
          user: user.trim(),
          lastCheck: new Date()
        };
      }
    } catch (error) {
      return {
        service: 'github',
        authenticated: false,
        lastCheck: new Date(),
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }

    return {
      service: 'github',
      authenticated: false,
      lastCheck: new Date()
    };
  }

  private async checkVercelAuth(): Promise<AuthStatus> {
    try {
      const { stdout } = await execAsync('vercel whoami');
      if (stdout.trim() && stdout.trim() !== 'Not logged in') {
        return {
          service: 'vercel',
          authenticated: true,
          user: stdout.trim(),
          lastCheck: new Date()
        };
      }
    } catch (error) {
      return {
        service: 'vercel',
        authenticated: false,
        lastCheck: new Date(),
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }

    return {
      service: 'vercel',
      authenticated: false,
      lastCheck: new Date()
    };
  }

  private async checkMicrosoftGraphAuth(): Promise<AuthStatus> {
    try {
      const { stdout } = await execAsync('powershell -Command "Get-MgContext | ConvertTo-Json"');
      const context = JSON.parse(stdout);
      
      if (context && context.Account) {
        return {
          service: 'microsoftGraph',
          authenticated: true,
          user: context.Account,
          lastCheck: new Date()
        };
      }
    } catch (error) {
      return {
        service: 'microsoftGraph',
        authenticated: false,
        lastCheck: new Date(),
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }

    return {
      service: 'microsoftGraph',
      authenticated: false,
      lastCheck: new Date()
    };
  }

  private async checkIntuneAuth(): Promise<AuthStatus> {
    try {
      const { stdout } = await execAsync('powershell -Command "Invoke-MgGraphRequest -Uri \'https://graph.microsoft.com/v1.0/deviceManagement\' -Method GET | ConvertTo-Json"');
      const result = JSON.parse(stdout);
      
      if (result && result.mdmAuthority) {
        return {
          service: 'intune',
          authenticated: true,
          user: result.mdmAuthority,
          lastCheck: new Date()
        };
      }
    } catch (error) {
      return {
        service: 'intune',
        authenticated: false,
        lastCheck: new Date(),
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }

    return {
      service: 'intune',
      authenticated: false,
      lastCheck: new Date()
    };
  }

  async loginToGitHub(): Promise<{ success: boolean; message: string }> {
    try {
      await execAsync('gh auth login --web --scopes "repo,workflow,admin:org,admin:repo_hook"');
      const auth = await this.checkGitHubAuth();
      
      return {
        success: auth.authenticated,
        message: auth.authenticated ? `Logged in as ${auth.user}` : 'Login failed'
      };
    } catch (error) {
      return {
        success: false,
        message: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  async loginToVercel(): Promise<{ success: boolean; message: string }> {
    try {
      await execAsync('vercel login');
      const auth = await this.checkVercelAuth();
      
      return {
        success: auth.authenticated,
        message: auth.authenticated ? `Logged in as ${auth.user}` : 'Login failed'
      };
    } catch (error) {
      return {
        success: false,
        message: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  async loginToMicrosoftGraph(): Promise<{ success: boolean; message: string }> {
    try {
      const scopes = [
        'Directory.ReadWrite.All',
        'User.ReadWrite.All',
        'Group.ReadWrite.All',
        'Policy.ReadWrite.ConditionalAccess',
        'DeviceManagementConfiguration.ReadWrite.All',
        'DeviceManagementManagedDevices.ReadWrite.All'
      ].join(' ');

      await execAsync(`powershell -Command "Connect-MgGraph -Scopes '${scopes}' -NoWelcome"`);
      const auth = await this.checkMicrosoftGraphAuth();
      
      return {
        success: auth.authenticated,
        message: auth.authenticated ? `Connected as ${auth.user}` : 'Connection failed'
      };
    } catch (error) {
      return {
        success: false,
        message: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  async validateSystemSync(): Promise<{ synced: boolean; issues: string[] }> {
    const issues = [];
    
    try {
      // Check GitHub-Vercel sync
      const { stdout: repoInfo } = await execAsync('gh repo view kaunghtetpai/esim-enterprise-management --json name');
      const { stdout: vercelProjects } = await execAsync('vercel ls --json');
      
      const repo = JSON.parse(repoInfo);
      const projects = JSON.parse(vercelProjects);
      
      const matchingProject = projects.find((p: any) => p.name === 'esim-enterprise-management');
      if (!matchingProject) {
        issues.push('GitHub repository not connected to Vercel project');
      }

      // Check Entra-Intune sync
      const { stdout: graphCheck } = await execAsync('powershell -Command "Get-MgUser -Top 1 | ConvertTo-Json"');
      const { stdout: intuneCheck } = await execAsync('powershell -Command "Invoke-MgGraphRequest -Uri \'https://graph.microsoft.com/v1.0/deviceManagement\' -Method GET | ConvertTo-Json"');
      
      if (!graphCheck || !intuneCheck) {
        issues.push('Entra ID and Intune synchronization issue detected');
      }

      return {
        synced: issues.length === 0,
        issues
      };
    } catch (error) {
      issues.push(`Sync validation failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
      return { synced: false, issues };
    }
  }

  async autoFixAuth(): Promise<{ fixed: string[]; failed: string[] }> {
    const fixed = [];
    const failed = [];

    try {
      // Refresh GitHub auth
      try {
        await execAsync('gh auth refresh');
        fixed.push('GitHub authentication refreshed');
      } catch {
        failed.push('GitHub authentication refresh failed');
      }

      // Check Vercel auth
      try {
        await execAsync('vercel whoami');
        fixed.push('Vercel authentication verified');
      } catch {
        failed.push('Vercel authentication verification failed');
      }

      // Refresh Microsoft Graph
      try {
        await execAsync('powershell -Command "Disconnect-MgGraph -ErrorAction SilentlyContinue; Connect-MgGraph -Scopes \'Directory.ReadWrite.All\' -NoWelcome"');
        fixed.push('Microsoft Graph connection refreshed');
      } catch {
        failed.push('Microsoft Graph connection refresh failed');
      }

      return { fixed, failed };
    } catch (error) {
      failed.push(`Auto-fix failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
      return { fixed, failed };
    }
  }

  async createCarrierGroups(): Promise<{ created: string[]; existing: string[]; errors: string[] }> {
    const created = [];
    const existing = [];
    const errors = [];

    const carriers = [
      { name: 'MPT', mcc: '414', mnc: '01' },
      { name: 'ATOM', mcc: '414', mnc: '06' },
      { name: 'MYTEL', mcc: '414', mnc: '09' }
    ];

    for (const carrier of carriers) {
      const groupName = `Group_${carrier.name}_eSIM`;
      
      try {
        const checkCmd = `powershell -Command "Get-MgGroup -Filter \\"displayName eq '${groupName}'\\" | ConvertTo-Json"`;
        const { stdout } = await execAsync(checkCmd);
        
        if (stdout.trim() && stdout !== 'null') {
          existing.push(groupName);
        } else {
          const createCmd = `powershell -Command "New-MgGroup -DisplayName '${groupName}' -Description 'eSIM devices for ${carrier.name} carrier' -MailEnabled:$false -SecurityEnabled:$true"`;
          await execAsync(createCmd);
          created.push(groupName);
        }
      } catch (error) {
        errors.push(`Failed to process group ${groupName}: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }
    }

    return { created, existing, errors };
  }

  private async logAuthStatus(services: CloudServices): Promise<void> {
    try {
      await this.supabase
        .from('cloud_auth_logs')
        .insert({
          github_status: services.github.authenticated,
          github_user: services.github.user,
          vercel_status: services.vercel.authenticated,
          vercel_user: services.vercel.user,
          microsoft_graph_status: services.microsoftGraph.authenticated,
          microsoft_graph_user: services.microsoftGraph.user,
          intune_status: services.intune.authenticated,
          intune_user: services.intune.user,
          checked_at: new Date().toISOString()
        });
    } catch (error) {
      console.error('Failed to log auth status:', error);
    }
  }
}

export const cloudAuthService = new CloudAuthService();