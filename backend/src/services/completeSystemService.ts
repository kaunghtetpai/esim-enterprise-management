import { exec } from 'child_process';
import { promisify } from 'util';
import { createClient } from '@supabase/supabase-js';

const execAsync = promisify(exec);

interface SystemStatus {
  github: boolean;
  vercel: boolean;
  database: boolean;
  apis: boolean;
  sync: boolean;
  errors: string[];
}

export class CompleteSystemService {
  private supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!);

  async checkAllSystems(): Promise<SystemStatus> {
    const status: SystemStatus = {
      github: false,
      vercel: false,
      database: false,
      apis: false,
      sync: false,
      errors: []
    };

    try {
      // Check GitHub
      const { stdout: ghStatus } = await execAsync('gh auth status');
      status.github = ghStatus.includes('Logged in');
      if (!status.github) status.errors.push('GitHub not authenticated');

      // Check Vercel
      const { stdout: vercelUser } = await execAsync('vercel whoami');
      status.vercel = vercelUser.trim() !== 'Not logged in';
      if (!status.vercel) status.errors.push('Vercel not authenticated');

      // Check Database
      const { data } = await this.supabase.from('users').select('id').limit(1);
      status.database = !!data;
      if (!status.database) status.errors.push('Database connection failed');

      // Check APIs
      const apiCheck = await this.validateAPIs();
      status.apis = apiCheck.valid.length > apiCheck.invalid.length;
      if (!status.apis) status.errors.push('API validation failed');

      // Check Sync
      const syncCheck = await this.checkSync();
      status.sync = syncCheck.synced;
      if (!status.sync) status.errors.push('Sync issues detected');

      return status;
    } catch (error) {
      status.errors.push(error instanceof Error ? error.message : 'Unknown error');
      return status;
    }
  }

  async updateAllData(): Promise<{ updated: string[]; errors: string[] }> {
    const updated = [];
    const errors = [];

    try {
      // Update GitHub
      await execAsync('git fetch origin && git pull origin main');
      updated.push('GitHub repository updated');
    } catch (error) {
      errors.push('GitHub update failed');
    }

    try {
      // Update Vercel
      await execAsync('vercel --prod --yes');
      updated.push('Vercel deployment triggered');
    } catch (error) {
      errors.push('Vercel deployment failed');
    }

    try {
      // Update Database
      await this.supabase.from('system_updates').insert({
        update_type: 'full_system',
        updated_at: new Date().toISOString()
      });
      updated.push('Database updated');
    } catch (error) {
      errors.push('Database update failed');
    }

    return { updated, errors };
  }

  async validateAPIs(): Promise<{ valid: string[]; invalid: string[] }> {
    const valid = [];
    const invalid = [];
    const endpoints = [
      '/api/v1/system/health',
      '/api/v1/system/status',
      '/api/v1/enterprise/status',
      '/api/v1/cicd/deployments',
      '/api/v1/auth/status',
      '/api/v1/sync/status'
    ];

    for (const endpoint of endpoints) {
      try {
        const response = await fetch(`https://esim-enterprise-management.vercel.app${endpoint}`);
        if (response.ok) {
          valid.push(endpoint);
        } else {
          invalid.push(endpoint);
        }
      } catch {
        invalid.push(endpoint);
      }
    }

    return { valid, invalid };
  }

  async fixAllIssues(): Promise<{ fixed: string[]; failed: string[] }> {
    const fixed = [];
    const failed = [];

    try {
      await execAsync('gh auth refresh');
      fixed.push('GitHub authentication refreshed');
    } catch {
      failed.push('GitHub authentication refresh failed');
    }

    try {
      await execAsync('vercel whoami');
      fixed.push('Vercel connection verified');
    } catch {
      failed.push('Vercel connection verification failed');
    }

    try {
      await execAsync('vercel link --yes');
      fixed.push('Repository linked to Vercel');
    } catch {
      failed.push('Repository linking failed');
    }

    return { fixed, failed };
  }

  async createSystemBackup(): Promise<{ success: boolean; backupId?: string }> {
    try {
      const backupId = `backup_${Date.now()}`;
      await this.supabase.from('system_backups').insert({
        backup_id: backupId,
        backup_data: await this.getAllSystemData(),
        created_at: new Date().toISOString()
      });
      return { success: true, backupId };
    } catch {
      return { success: false };
    }
  }

  async deleteOldData(days: number = 30): Promise<{ deleted: number }> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    const tables = ['system_errors', 'deployment_logs', 'auth_events', 'sync_operations'];
    let totalDeleted = 0;

    for (const table of tables) {
      try {
        const { count } = await this.supabase
          .from(table)
          .delete()
          .lt('created_at', cutoffDate.toISOString());
        totalDeleted += count || 0;
      } catch {
        // Continue with other tables
      }
    }

    return { deleted: totalDeleted };
  }

  async clearAllErrors(): Promise<{ cleared: number }> {
    try {
      const { count } = await this.supabase
        .from('system_errors')
        .delete()
        .eq('resolved', true);
      return { cleared: count || 0 };
    } catch {
      return { cleared: 0 };
    }
  }

  private async checkSync(): Promise<{ synced: boolean; issues: string[] }> {
    const issues = [];
    
    try {
      const { stdout: repoInfo } = await execAsync('gh repo view --json name');
      const { stdout: vercelProjects } = await execAsync('vercel ls --json');
      
      const repo = JSON.parse(repoInfo);
      const projects = JSON.parse(vercelProjects);
      
      if (!projects.find((p: any) => p.name === 'esim-enterprise-management')) {
        issues.push('Repository not linked to Vercel project');
      }

      return { synced: issues.length === 0, issues };
    } catch {
      return { synced: false, issues: ['Sync check failed'] };
    }
  }

  private async getAllSystemData(): Promise<any> {
    const data = {};
    const tables = ['users', 'organizations', 'devices', 'esim_profiles'];
    
    for (const table of tables) {
      try {
        const { data: tableData } = await this.supabase.from(table).select('*');
        data[table] = tableData;
      } catch {
        data[table] = [];
      }
    }
    
    return data;
  }
}

export const completeSystemService = new CompleteSystemService();