"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deploymentController = void 0;
const deploymentErrorService_1 = require("../services/deploymentErrorService");
const deploymentService = new deploymentErrorService_1.DeploymentErrorService();
exports.deploymentController = {
    async checkAllDeployments(req, res) {
        try {
            const deploymentStatus = await deploymentService.checkAllDeployments();
            res.json({
                success: true,
                data: deploymentStatus,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                message: 'Failed to check deployments',
                error: error.message
            });
        }
    },
    async getActiveErrors(req, res) {
        try {
            const errors = await deploymentService.getActiveErrors();
            res.json({
                success: true,
                data: errors,
                count: errors.length
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                message: 'Failed to get active errors',
                error: error.message
            });
        }
    },
    async resolveError(req, res) {
        try {
            const { errorId } = req.params;
            await deploymentService.resolveError(errorId);
            res.json({
                success: true,
                message: 'Error resolved successfully'
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                message: 'Failed to resolve error',
                error: error.message
            });
        }
    },
    async syncAllPlatforms(req, res) {
        try {
            const result = await deploymentService.syncAllPlatforms();
            res.json({
                success: result.success,
                message: result.message,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                message: 'Failed to sync platforms',
                error: error.message
            });
        }
    },
    async logError(req, res) {
        try {
            const { platform, errorType, message } = req.body;
            await deploymentService.logError(platform, errorType, message);
            res.json({
                success: true,
                message: 'Error logged successfully'
            });
        }
        catch (error) {
            res.status(500).json({
                success: false,
                message: 'Failed to log error',
                error: error.message
            });
        }
    }
};
//# sourceMappingURL=deploymentController.js.map