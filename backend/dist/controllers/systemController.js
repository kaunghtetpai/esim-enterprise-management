"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.systemController = exports.SystemController = void 0;
const systemErrorService_1 = require("../services/systemErrorService");
const diagnosticService_1 = require("../services/diagnosticService");
class SystemController {
    async getSystemHealth(req, res) {
        try {
            const health = await systemErrorService_1.systemErrorService.checkSystemHealth();
            res.json({
                success: true,
                data: health,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to check system health',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async runDiagnostics(req, res) {
        try {
            const diagnostics = await diagnosticService_1.diagnosticService.runFullDiagnostic();
            res.json({
                success: true,
                data: diagnostics,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to run diagnostics',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async autoFixErrors(req, res) {
        try {
            const result = await systemErrorService_1.systemErrorService.autoFixErrors();
            res.json({
                success: true,
                data: result,
                message: `Fixed ${result.fixed} errors, ${result.failed} failed to fix`
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to auto-fix errors',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async getErrorReport(req, res) {
        try {
            const errors = await systemErrorService_1.systemErrorService.getErrorReport();
            res.json({
                success: true,
                data: errors,
                count: errors.length
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to get error report',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async clearErrors(req, res) {
        try {
            await systemErrorService_1.systemErrorService.clearResolvedErrors();
            res.json({
                success: true,
                message: 'Resolved errors cleared'
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to clear errors',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    async getSystemStatus(req, res) {
        try {
            const [health, diagnostics] = await Promise.all([
                systemErrorService_1.systemErrorService.checkSystemHealth(),
                diagnosticService_1.diagnosticService.runQuickCheck()
            ]);
            const status = {
                health,
                diagnostics,
                uptime: process.uptime(),
                memory: process.memoryUsage(),
                version: process.version,
                platform: process.platform
            };
            res.json({
                success: true,
                data: status,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                error: 'Failed to get system status',
                details: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
}
exports.SystemController = SystemController;
exports.systemController = new SystemController();
//# sourceMappingURL=systemController.js.map