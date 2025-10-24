"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cicdService = exports.CICDService = void 0;
const child_process_1 = require("child_process");
const util_1 = require("util");
const supabase_js_1 = require("@supabase/supabase-js");
const execAsync = (0, util_1.promisify)(child_process_1.exec);
class CICDService {
    constructor() {
        this.supabase = (0, supabase_js_1.createClient)(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
    }
    async getDeploymentStatus() {
        try {
            // Check Vercel deployments
            const { stdout } = await execAsync('vercel ls --token=$VERCEL_TOKEN');
            const deployments = this.parseVercelOutput(stdout);
            // Store in database
            await this.storeDeploymentStatus(deployments);
            return deployments;
        }
        catch (error) {
            console.error('Failed to get deployment status:', error);
            return [];
        }
    }
    async triggerDeployment(branch = 'main') {
        try {
            // Trigger GitHub Actions workflow
            const { stdout } = await execAsync(`gh workflow run ci-cd-pipeline.yml --ref ${branch}`);
            const deploymentId = this.extractDeploymentId(stdout);
            await this.logDeploymentTrigger(branch, deploymentId);
            return {
                success: true,
                deploymentId
            };
        }
        catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error.message : 'Unknown error'
            };
        }
    }
    async rollbackDeployment(deploymentId) {
        try {
            if (deploymentId) {
                await execAsync(`vercel rollback ${deploymentId} --token=$VERCEL_TOKEN`);
            }
            else {
                // Rollback to previous deployment
                const { stdout } = await execAsync('vercel ls --token=$VERCEL_TOKEN');
                const deployments = this.parseVercelOutput(stdout);
                const readyDeployments = deployments.filter(d => d.status === 'ready');
                if (readyDeployments.length >= 2) {
                    const previousDeployment = readyDeployments[1];
                    await execAsync(`vercel rollback ${previousDeployment.id} --token=$VERCEL_TOKEN`);
                }
            }
            await this.logRollback(deploymentId);
            return {
                success: true,
                message: 'Rollback completed successfully'
            };
        }
        catch (error) {
            return {
                success: false,
                message: error instanceof Error ? error.message : 'Rollback failed'
            };
        }
    }
    async getCICDMetrics() {
        try {
            const { data: deployments } = await this.supabase
                .from('deployment_logs')
                .select('*')
                .order('created_at', { ascending: false })
                .limit(100);
            if (!deployments || deployments.length === 0) {
                return {
                    deploymentFrequency: 0,
                    successRate: 0,
                    averageBuildTime: 0,
                    failureRate: 0,
                    lastDeployment: new Date(),
                    totalDeployments: 0
                };
            }
            const successful = deployments.filter(d => d.status === 'ready').length;
            const failed = deployments.filter(d => d.status === 'error').length;
            const totalBuildTime = deployments
                .filter(d => d.build_duration)
                .reduce((sum, d) => sum + d.build_duration, 0);
            return {
                deploymentFrequency: this.calculateDeploymentFrequency(deployments),
                successRate: (successful / deployments.length) * 100,
                averageBuildTime: totalBuildTime / deployments.length,
                failureRate: (failed / deployments.length) * 100,
                lastDeployment: new Date(deployments[0].created_at),
                totalDeployments: deployments.length
            };
        }
        catch (error) {
            console.error('Failed to get CI/CD metrics:', error);
            return {
                deploymentFrequency: 0,
                successRate: 0,
                averageBuildTime: 0,
                failureRate: 0,
                lastDeployment: new Date(),
                totalDeployments: 0
            };
        }
    }
    async validateDeployment(url) {
        const checks = [];
        let healthy = true;
        try {
            // Health check
            const healthResponse = await fetch(`${url}/api/v1/system/health`, {
                method: 'GET',
                timeout: 10000
            });
            checks.push({
                name: 'Health Check',
                status: healthResponse.ok ? 'pass' : 'fail',
                responseTime: Date.now(),
                statusCode: healthResponse.status
            });
            if (!healthResponse.ok)
                healthy = false;
            // API endpoints check
            const endpoints = ['/api/v1/system/status', '/api/v1/enterprise/status'];
            for (const endpoint of endpoints) {
                try {
                    const response = await fetch(`${url}${endpoint}`, {
                        method: 'GET',
                        timeout: 5000
                    });
                    checks.push({
                        name: `API ${endpoint}`,
                        status: response.ok ? 'pass' : 'fail',
                        statusCode: response.status
                    });
                    if (!response.ok)
                        healthy = false;
                }
                catch (error) {
                    checks.push({
                        name: `API ${endpoint}`,
                        status: 'fail',
                        error: error instanceof Error ? error.message : 'Unknown error'
                    });
                    healthy = false;
                }
            }
            return { healthy, checks };
        }
        catch (error) {
            return {
                healthy: false,
                checks: [{
                        name: 'Deployment Validation',
                        status: 'fail',
                        error: error instanceof Error ? error.message : 'Unknown error'
                    }]
            };
        }
    }
    async syncGitHubVercel() {
        const issues = [];
        try {
            // Check GitHub repository status
            const { stdout: gitStatus } = await execAsync('git status --porcelain');
            if (gitStatus.trim()) {
                issues.push('Uncommitted changes in repository');
            }
            // Check Vercel project connection
            const { stdout: vercelStatus } = await execAsync('vercel ls --token=$VERCEL_TOKEN');
            if (!vercelStatus.includes('esim-enterprise-management')) {
                issues.push('Vercel project not found or not connected');
            }
            // Check branch protection
            const { stdout: branchInfo } = await execAsync('gh api repos/kaunghtetpai/esim-enterprise-management/branches/main/protection');
            const protection = JSON.parse(branchInfo);
            if (!protection.required_status_checks?.strict) {
                issues.push('Branch protection not properly configured');
            }
            return {
                synced: issues.length === 0,
                issues
            };
        }
        catch (error) {
            issues.push(`Sync check failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
            return { synced: false, issues };
        }
    }
    parseVercelOutput(output) {
        const lines = output.split('\n').slice(1); // Skip header
        return lines
            .filter(line => line.trim())
            .map(line => {
            const parts = line.trim().split(/\s+/);
            return {
                id: parts[0] || '',
                status: this.mapVercelStatus(parts[1] || ''),
                url: parts[2] || '',
                createdAt: new Date(parts[3] || Date.now())
            };
        });
    }
    mapVercelStatus(status) {
        switch (status.toLowerCase()) {
            case 'ready': return 'ready';
            case 'building': return 'building';
            case 'error': return 'error';
            case 'canceled': return 'canceled';
            default: return 'pending';
        }
    }
    extractDeploymentId(output) {
        const match = output.match(/deployment[:\s]+([a-zA-Z0-9-]+)/i);
        return match ? match[1] : `deploy_${Date.now()}`;
    }
    calculateDeploymentFrequency(deployments) {
        if (deployments.length < 2)
            return 0;
        const latest = new Date(deployments[0].created_at);
        const oldest = new Date(deployments[deployments.length - 1].created_at);
        const daysDiff = (latest.getTime() - oldest.getTime()) / (1000 * 60 * 60 * 24);
        return deployments.length / daysDiff;
    }
    async storeDeploymentStatus(deployments) {
        try {
            const records = deployments.map(d => ({
                deployment_id: d.id,
                status: d.status,
                url: d.url,
                created_at: d.createdAt.toISOString(),
                ready_at: d.readyAt?.toISOString(),
                error_message: d.errorMessage
            }));
            await this.supabase
                .from('deployment_logs')
                .upsert(records, { onConflict: 'deployment_id' });
        }
        catch (error) {
            console.error('Failed to store deployment status:', error);
        }
    }
    async logDeploymentTrigger(branch, deploymentId) {
        try {
            await this.supabase
                .from('deployment_triggers')
                .insert({
                deployment_id: deploymentId,
                branch,
                triggered_at: new Date().toISOString(),
                trigger_type: 'manual'
            });
        }
        catch (error) {
            console.error('Failed to log deployment trigger:', error);
        }
    }
    async logRollback(deploymentId) {
        try {
            await this.supabase
                .from('deployment_rollbacks')
                .insert({
                deployment_id: deploymentId,
                rolled_back_at: new Date().toISOString(),
                reason: 'manual_rollback'
            });
        }
        catch (error) {
            console.error('Failed to log rollback:', error);
        }
    }
}
exports.CICDService = CICDService;
exports.cicdService = new CICDService();
//# sourceMappingURL=cicdService.js.map