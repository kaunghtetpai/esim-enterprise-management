"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DeploymentErrorService = void 0;
const database_1 = require("../config/database");
class DeploymentErrorService {
    async checkAllDeployments() {
        const results = [];
        // Check GitHub
        results.push(await this.checkGitHub());
        // Check Vercel
        results.push(await this.checkVercel());
        // Check Azure
        results.push(await this.checkAzure());
        // Check Intune
        results.push(await this.checkIntune());
        return results;
    }
    async checkGitHub() {
        try {
            const response = await fetch('https://api.github.com/repos/kaunghtetpai/esim-enterprise-management');
            const status = response.ok ? 'healthy' : 'error';
            await this.logDeploymentCheck('github', status);
            return {
                platform: 'github',
                status,
                last_check: new Date().toISOString(),
                error_count: await this.getErrorCount('github')
            };
        }
        catch (error) {
            await this.logError('github', 'connection_error', error.message);
            return {
                platform: 'github',
                status: 'error',
                last_check: new Date().toISOString(),
                error_count: await this.getErrorCount('github')
            };
        }
    }
    async checkVercel() {
        try {
            const response = await fetch('https://esim-enterprise-management.vercel.app/health');
            const status = response.ok ? 'healthy' : 'error';
            await this.logDeploymentCheck('vercel', status);
            return {
                platform: 'vercel',
                status,
                last_check: new Date().toISOString(),
                error_count: await this.getErrorCount('vercel')
            };
        }
        catch (error) {
            await this.logError('vercel', 'deployment_error', error.message);
            return {
                platform: 'vercel',
                status: 'error',
                last_check: new Date().toISOString(),
                error_count: await this.getErrorCount('vercel')
            };
        }
    }
    async checkAzure() {
        try {
            // Check Azure AD authentication
            const { data, error } = await database_1.supabase
                .from('cloud_authentication')
                .select('*')
                .eq('platform', 'azure')
                .eq('status', 'active')
                .single();
            const status = data && !error ? 'healthy' : 'warning';
            await this.logDeploymentCheck('azure', status);
            return {
                platform: 'azure',
                status,
                last_check: new Date().toISOString(),
                error_count: await this.getErrorCount('azure')
            };
        }
        catch (error) {
            await this.logError('azure', 'auth_error', error.message);
            return {
                platform: 'azure',
                status: 'error',
                last_check: new Date().toISOString(),
                error_count: await this.getErrorCount('azure')
            };
        }
    }
    async checkIntune() {
        try {
            // Check Intune integration status
            const { data, error } = await database_1.supabase
                .from('intune_devices')
                .select('count')
                .limit(1);
            const status = !error ? 'healthy' : 'warning';
            await this.logDeploymentCheck('intune', status);
            return {
                platform: 'intune',
                status,
                last_check: new Date().toISOString(),
                error_count: await this.getErrorCount('intune')
            };
        }
        catch (error) {
            await this.logError('intune', 'integration_error', error.message);
            return {
                platform: 'intune',
                status: 'error',
                last_check: new Date().toISOString(),
                error_count: await this.getErrorCount('intune')
            };
        }
    }
    async logError(platform, errorType, message) {
        await database_1.supabase
            .from('deployment_errors')
            .insert({
            platform,
            error_type: errorType,
            error_message: message,
            status: 'active'
        });
    }
    async resolveError(errorId) {
        await database_1.supabase
            .from('deployment_errors')
            .update({
            status: 'resolved',
            resolved_at: new Date().toISOString()
        })
            .eq('id', errorId);
    }
    async getActiveErrors() {
        const { data, error } = await database_1.supabase
            .from('deployment_errors')
            .select('*')
            .eq('status', 'active')
            .order('created_at', { ascending: false });
        return data || [];
    }
    async getErrorCount(platform) {
        const { count } = await database_1.supabase
            .from('deployment_errors')
            .select('*', { count: 'exact' })
            .eq('platform', platform)
            .eq('status', 'active');
        return count || 0;
    }
    async logDeploymentCheck(platform, status) {
        await database_1.supabase
            .from('deployment_checks')
            .insert({
            platform,
            status,
            checked_at: new Date().toISOString()
        });
    }
    async syncAllPlatforms() {
        try {
            // Sync GitHub
            await this.syncGitHub();
            // Sync Vercel
            await this.syncVercel();
            // Sync Azure
            await this.syncAzure();
            // Sync Intune
            await this.syncIntune();
            return { success: true, message: 'All platforms synced successfully' };
        }
        catch (error) {
            await this.logError('system', 'sync_error', error.message);
            return { success: false, message: error.message };
        }
    }
    async syncGitHub() {
        // Update GitHub sync status
        await database_1.supabase
            .from('platform_sync')
            .upsert({
            platform: 'github',
            last_sync: new Date().toISOString(),
            status: 'synced'
        });
    }
    async syncVercel() {
        // Update Vercel sync status
        await database_1.supabase
            .from('platform_sync')
            .upsert({
            platform: 'vercel',
            last_sync: new Date().toISOString(),
            status: 'synced'
        });
    }
    async syncAzure() {
        // Update Azure sync status
        await database_1.supabase
            .from('platform_sync')
            .upsert({
            platform: 'azure',
            last_sync: new Date().toISOString(),
            status: 'synced'
        });
    }
    async syncIntune() {
        // Update Intune sync status
        await database_1.supabase
            .from('platform_sync')
            .upsert({
            platform: 'intune',
            last_sync: new Date().toISOString(),
            status: 'synced'
        });
    }
}
exports.DeploymentErrorService = DeploymentErrorService;
//# sourceMappingURL=deploymentErrorService.js.map