"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cicdController = exports.CICDController = void 0;
const cicdService_1 = require("../services/cicdService");
class CICDController {
    async getDeploymentStatus(req, res) {
        try {
            const deployments = await cicdService_1.cicdService.getDeploymentStatus();
            res.json({
                success: true,
                data: deployments,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to get deployment status',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async triggerDeployment(req, res) {
        try {
            const { branch = 'main' } = req.body;
            const result = await cicdService_1.cicdService.triggerDeployment(branch);
            res.json({
                success: result.success,
                data: result,
                message: result.success ? 'Deployment triggered successfully' : 'Failed to trigger deployment'
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to trigger deployment',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async rollbackDeployment(req, res) {
        try {
            const { deploymentId } = req.body;
            const result = await cicdService_1.cicdService.rollbackDeployment(deploymentId);
            res.json({
                success: result.success,
                message: result.message,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to rollback deployment',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async getCICDMetrics(req, res) {
        try {
            const metrics = await cicdService_1.cicdService.getCICDMetrics();
            res.json({
                success: true,
                data: metrics,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to get CI/CD metrics',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async validateDeployment(req, res) {
        try {
            const { url = 'https://esim-enterprise-management.vercel.app' } = req.body;
            const validation = await cicdService_1.cicdService.validateDeployment(url);
            res.json({
                success: validation.healthy,
                data: validation,
                message: validation.healthy ? 'Deployment is healthy' : 'Deployment validation failed'
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to validate deployment',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async syncGitHubVercel(req, res) {
        try {
            const sync = await cicdService_1.cicdService.syncGitHubVercel();
            res.json({
                success: sync.synced,
                data: sync,
                message: sync.synced ? 'GitHub and Vercel are synchronized' : 'Synchronization issues detected'
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to check synchronization',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
}
exports.CICDController = CICDController;
exports.cicdController = new CICDController();
//# sourceMappingURL=cicdController.js.map