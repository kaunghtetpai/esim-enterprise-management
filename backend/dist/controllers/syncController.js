"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.syncController = exports.SyncController = void 0;
const vercelGitHubSyncService_1 = require("../services/vercelGitHubSyncService");
const completeSystemService_1 = require("../services/completeSystemService");
class SyncController {
    async checkSyncStatus(req, res) {
        try {
            const status = await vercelGitHubSyncService_1.vercelGitHubSyncService.checkSyncStatus();
            res.json({
                success: true,
                data: status,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to check sync status',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async updateAllData(req, res) {
        try {
            const result = await vercelGitHubSyncService_1.vercelGitHubSyncService.updateAllData();
            res.json({
                success: result.errors.length === 0,
                data: result,
                message: `Updated ${result.updated.length} services, ${result.errors.length} errors`,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to update data',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async validateAPIs(req, res) {
        try {
            const validation = await vercelGitHubSyncService_1.vercelGitHubSyncService.validateAPIs();
            res.json({
                success: validation.invalid.length === 0,
                data: validation,
                message: `${validation.valid.length} APIs valid, ${validation.invalid.length} invalid`,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to validate APIs',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async fixSyncIssues(req, res) {
        try {
            const result = await vercelGitHubSyncService_1.vercelGitHubSyncService.fixSyncIssues();
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
                error: 'Failed to fix sync issues',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async checkAllSystems(req, res) {
        try {
            const status = await completeSystemService_1.completeSystemService.checkAllSystems();
            res.json({
                success: status.errors.length === 0,
                data: status,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'System check failed',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async updateAllSystems(req, res) {
        try {
            const result = await completeSystemService_1.completeSystemService.updateAllData();
            res.json({
                success: result.errors.length === 0,
                data: result,
                message: `Updated ${result.updated.length} systems, ${result.errors.length} errors`,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'System update failed',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async createBackup(req, res) {
        try {
            const result = await completeSystemService_1.completeSystemService.createSystemBackup();
            res.json({
                success: result.success,
                data: result,
                message: result.success ? 'Backup created successfully' : 'Backup creation failed',
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Backup creation failed',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async deleteOldData(req, res) {
        try {
            const { days = 30 } = req.body;
            const result = await completeSystemService_1.completeSystemService.deleteOldData(days);
            res.json({
                success: true,
                data: result,
                message: `Deleted ${result.deleted} old records`,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Data deletion failed',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async clearErrors(req, res) {
        try {
            const result = await completeSystemService_1.completeSystemService.clearAllErrors();
            res.json({
                success: true,
                data: result,
                message: `Cleared ${result.cleared} resolved errors`,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Error clearing failed',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
}
exports.SyncController = SyncController;
exports.syncController = new SyncController();
//# sourceMappingURL=syncController.js.map