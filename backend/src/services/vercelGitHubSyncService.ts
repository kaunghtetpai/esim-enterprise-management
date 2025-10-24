import { exec } from 'child_process';
import { promisify } from 'util';
import { createClient } from '@supabase/supabase-js';

const execAsync = promisify(exec);

interface SyncStatus {
  github: { connected: boolean; repo: string; branch: string; lastCommit: string };
  vercel: { connected: boolean; project: string; deployments: any[]; lastDeploy: string };
  sync: { status: 'synced' | 'drift' | 'error'; issues: string[]; lastSync: Date };
}

export class VercelGitHubSyncService {
  private supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!);

  async checkSyncStatus(): Promise<SyncStatus> {
    const status: SyncStatus = {
      github: { connected: false, repo: '', branch: '', lastCommit: '' },
      vercel: { connected: false, project: '', deployments: [], lastDeploy: '' },
      sync: { status: 'error', issues: [], lastSync: new Date() }
    };

    try {
      // Check GitHub
      const { stdout: ghStatus } = await execAsync('gh auth status');
      if (ghStatus.includes('Logged in')) {
        status.github.connected = true;
        const { stdout: repoInfo } = await execAsync('gh repo view --json name,defaultBranchRef');
        const repo = JSON.parse(repoInfo);
        status.github.repo = repo.name;
        status.github.branch = repo.defaultBranchRef.name;
        
        const { stdout: lastCommit } = await execAsync('git log -1 --format="%H %s"');
        status.github.lastCommit = lastCommit.trim();
      }

      // Check Vercel
      const { stdout: vercelUser } = await execAsync('vercel whoami');
      if (vercelUser.trim() && vercelUser.trim() !== 'Not logged in') {
        status.vercel.connected = true;
        const { stdout: projects } = await execAsync('vercel ls --json');
        const projectList = JSON.parse(projects);
        const project = projectList.find((p: any) => p.name === 'esim-enterprise-management');
        
        if (project) {
          status.vercel.project = project.name;
          status.vercel.lastDeploy = project.createdAt;
          
          const { stdout: deployments } = await execAsync(`vercel ls ${project.name} --json`);
          status.vercel.deployments = JSON.parse(deployments);
        }
      }

      // Determine sync status
      if (status.github.connected && status.vercel.connected) {
        status.sync.status = 'synced';
      } else {
        status.sync.status = 'error';
        if (!status.github.connected) status.sync.issues.push('GitHub not connected');
        if (!status.vercel.connected) status.sync.issues.push('Vercel not connected');
      }

      await this.logSyncStatus(status);
      return status;
    } catch (error) {
      status.sync.status = 'error';
      status.sync.issues.push(error instanceof Error ? error.message : 'Unknown error');
      return status;
    }
  }

  async updateAllData(): Promise<{ updated: string[]; errors: string[] }> {
    const updated = [];
    const errors = [];

    try {
      // Update GitHub data
      try {
        await execAsync('git fetch origin');
        await execAsync('git pull origin main');
        updated.push('GitHub repository updated');
      } catch (error) {
        errors.push(`GitHub update failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }

      // Trigger Vercel deployment
      try {
        const { stdout } = await execAsync('vercel --prod --yes');
        updated.push('Vercel deployment triggered');
      } catch (error) {
        errors.push(`Vercel deployment failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }

      // Update database
      try {
        await this.supabase.from('sync_operations').insert({
          operation_type: 'full_update',
          updated_services: updated,
          errors: errors,
          performed_at: new Date().toISOString()
        });
        updated.push('Database updated');
      } catch (error) {
        errors.push('Database update failed');
      }

      return { updated, errors };
    } catch (error) {
      errors.push(`Update operation failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
      return { updated, errors };
    }
  }

  async validateAPIs(): Promise<{ valid: string[]; invalid: string[] }> {
    const valid = [];
    const invalid = [];

    const endpoints = [
      '/api/v1/system/health',
      '/api/v1/system/status',
      '/api/v1/enterprise/status',
      '/api/v1/cicd/deployments',
      '/api/v1/auth/status'
    ];

    for (const endpoint of endpoints) {
      try {
        const response = await fetch(`https://esim-enterprise-management.vercel.app${endpoint}`);
        if (response.ok) {
          valid.push(endpoint);
        } else {
          invalid.push(`${endpoint} - Status: ${response.status}`);
        }
      } catch (error) {
        invalid.push(`${endpoint} - Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }
    }

    return { valid, invalid };
  }

  async fixSyncIssues(): Promise<{ fixed: string[]; failed: string[] }> {
    const fixed = [];
    const failed = [];

    try {
      // Fix GitHub auth
      try {
        await execAsync('gh auth refresh');
        fixed.push('GitHub authentication refreshed');
      } catch {
        failed.push('GitHub authentication refresh failed');
      }

      // Fix Vercel connection
      try {
        await execAsync('vercel whoami');
        fixed.push('Vercel connection verified');
      } catch {
        failed.push('Vercel connection verification failed');
      }

      // Sync repository with Vercel
      try {
        await execAsync('vercel link --yes');
        fixed.push('Repository linked to Vercel project');
      } catch {
        failed.push('Repository linking failed');
      }

      return { fixed, failed };
    } catch (error) {
      failed.push(`Fix operation failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
      return { fixed, failed };
    }
  }

  private async logSyncStatus(status: SyncStatus): Promise<void> {
    try {
      await this.supabase.from('github_vercel_sync').upsert({
        repository_name: 'kaunghtetpai/esim-enterprise-management',
        github_connected: status.github.connected,
        vercel_connected: status.vercel.connected,
        sync_status: status.sync.status,
        issues: status.sync.issues,
        last_sync_at: new Date().toISOString()
      });
    } catch (error) {
      console.error('Failed to log sync status:', error);
    }
  }
}

export const vercelGitHubSyncService = new VercelGitHubSyncService();