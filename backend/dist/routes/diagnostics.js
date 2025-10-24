"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const diagnosticService_1 = require("../services/diagnosticService");
const auth_1 = require("../middleware/auth");
const errorHandler_1 = require("../middleware/errorHandler");
const router = express_1.default.Router();
const diagnosticService = new diagnosticService_1.DiagnosticService();
router.get('/health', auth_1.authenticateToken, (0, auth_1.requireRole)(['admin']), (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const results = await diagnosticService.runFullDiagnostic();
        const summary = {
            healthy: results.filter(r => r.status === 'healthy').length,
            warning: results.filter(r => r.status === 'warning').length,
            error: results.filter(r => r.status === 'error').length,
            total: results.length
        };
        const overallStatus = summary.error > 0 ? 'error' : (summary.warning > 0 ? 'warning' : 'healthy');
        res.json({
            success: true,
            data: {
                overallStatus,
                summary,
                results,
                recommendations: generateRecommendations(results)
            },
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: error.message,
            code: 'DIAGNOSTIC_ERROR',
            timestamp: new Date().toISOString()
        });
    }
}));
router.post('/solve', auth_1.authenticateToken, (0, auth_1.requireRole)(['admin']), (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const { component, issue } = req.body;
        if (!component || !issue) {
            return res.status(400).json({
                success: false,
                error: 'Component and issue description are required',
                code: 'MISSING_PARAMETERS',
                timestamp: new Date().toISOString()
            });
        }
        const solution = await diagnosticService.solveProblem(component, issue);
        res.json({
            success: true,
            data: solution,
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: error.message,
            code: 'SOLUTION_ERROR',
            timestamp: new Date().toISOString()
        });
    }
}));
router.get('/quick-check', auth_1.authenticateToken, (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const checks = [
            diagnosticService['checkDatabase'](),
            diagnosticService['checkSystemResources'](),
            diagnosticService['checkNetworkConnectivity']()
        ];
        const results = await Promise.allSettled(checks);
        const quickResults = results.map((result, index) => {
            if (result.status === 'fulfilled') {
                return result.value;
            }
            else {
                return {
                    component: ['database', 'system', 'network'][index],
                    status: 'error',
                    message: 'Check failed',
                    timestamp: new Date().toISOString()
                };
            }
        });
        const isHealthy = quickResults.every(r => r.status === 'healthy');
        res.json({
            success: true,
            data: {
                status: isHealthy ? 'healthy' : 'issues_detected',
                results: quickResults
            },
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: error.message,
            code: 'QUICK_CHECK_ERROR',
            timestamp: new Date().toISOString()
        });
    }
}));
function generateRecommendations(results) {
    const recommendations = [];
    results.forEach(result => {
        switch (result.component) {
            case 'database':
                if (result.status !== 'healthy') {
                    recommendations.push('Check database connection and optimize queries');
                }
                break;
            case 'graph_connection':
                if (result.status !== 'healthy') {
                    recommendations.push('Reconnect to Microsoft Graph and verify permissions');
                }
                break;
            case 'system_resources':
                if (result.status === 'warning') {
                    recommendations.push('Monitor memory usage and consider scaling resources');
                }
                break;
            case 'network_connectivity':
                if (result.status !== 'healthy') {
                    recommendations.push('Check network connectivity and firewall settings');
                }
                break;
            case 'error_rates':
                if (result.status !== 'healthy') {
                    recommendations.push('Review error logs and implement fixes for common issues');
                }
                break;
            case 'disk_space':
                if (result.status !== 'healthy') {
                    recommendations.push('Clean up disk space and implement log rotation');
                }
                break;
        }
    });
    if (recommendations.length === 0) {
        recommendations.push('System is running optimally');
    }
    return recommendations;
}
exports.default = router;
//# sourceMappingURL=diagnostics.js.map