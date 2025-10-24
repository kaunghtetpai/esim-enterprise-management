"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cloudAuthController = exports.CloudAuthController = void 0;
const cloudAuthService_1 = require("../services/cloudAuthService");
class CloudAuthController {
    async checkAllAuth(req, res) {
        try {
            const services = await cloudAuthService_1.cloudAuthService.checkAllAuthentications();
            res.json({
                success: true,
                data: services,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to check authentications',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async loginGitHub(req, res) {
        try {
            const result = await cloudAuthService_1.cloudAuthService.loginToGitHub();
            res.json({
                success: result.success,
                message: result.message,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'GitHub login failed',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async loginVercel(req, res) {
        try {
            const result = await cloudAuthService_1.cloudAuthService.loginToVercel();
            res.json({
                success: result.success,
                message: result.message,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Vercel login failed',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async loginMicrosoftGraph(req, res) {
        try {
            const result = await cloudAuthService_1.cloudAuthService.loginToMicrosoftGraph();
            res.json({
                success: result.success,
                message: result.message,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Microsoft Graph login failed',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async validateSync(req, res) {
        try {
            const sync = await cloudAuthService_1.cloudAuthService.validateSystemSync();
            res.json({
                success: sync.synced,
                data: sync,
                message: sync.synced ? 'All systems synchronized' : 'Synchronization issues detected',
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Sync validation failed',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async autoFix(req, res) {
        try {
            const result = await cloudAuthService_1.cloudAuthService.autoFixAuth();
            res.json({
                success: result.failed.length === 0,
                data: result,
                message: `Fixed ${result.fixed.length} issues, ${result.failed.length} failed`,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Auto-fix failed',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async createCarrierGroups(req, res) {
        try {
            const result = await cloudAuthService_1.cloudAuthService.createCarrierGroups();
            res.json({
                success: result.errors.length === 0,
                data: result,
                message: `Created ${result.created.length} groups, ${result.existing.length} already existed`,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to create carrier groups',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
}
exports.CloudAuthController = CloudAuthController;
exports.cloudAuthController = new CloudAuthController();
//# sourceMappingURL=cloudAuthController.js.map