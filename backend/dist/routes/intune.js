"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const intuneService_1 = require("../services/intuneService");
const auth_1 = require("../middleware/auth");
const validation_1 = require("../middleware/validation");
const errorHandler_1 = require("../middleware/errorHandler");
const router = express_1.default.Router();
// Get managed devices from Intune
router.get('/devices', auth_1.authenticateToken, validation_1.validatePagination, (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const intuneService = new intuneService_1.IntuneService(req.authProvider);
        const devices = await intuneService.getManagedDevices();
        if (!devices || !Array.isArray(devices)) {
            return res.status(500).json({
                success: false,
                error: 'Invalid response from Intune service',
                code: 'INTUNE_SERVICE_ERROR',
                timestamp: new Date().toISOString()
            });
        }
        const { page, limit } = req.query;
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const startIndex = (pageNum - 1) * limitNum;
        const endIndex = startIndex + limitNum;
        const paginatedDevices = devices.slice(startIndex, endIndex);
        res.json({
            success: true,
            data: {
                devices: paginatedDevices,
                pagination: {
                    total: devices.length,
                    page: pageNum,
                    limit: limitNum,
                    totalPages: Math.ceil(devices.length / limitNum),
                    hasNext: endIndex < devices.length,
                    hasPrev: pageNum > 1
                }
            },
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: error.message || 'Failed to fetch Intune devices',
            code: 'INTUNE_DEVICES_FETCH_ERROR',
            timestamp: new Date().toISOString()
        });
    }
}));
// Get device configuration
router.get('/devices/:deviceId/configuration', auth_1.authenticateToken, (0, validation_1.validateUUID)('deviceId'), (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const { deviceId } = req.params;
        const intuneService = new intuneService_1.IntuneService(req.authProvider);
        const configuration = await intuneService.getDeviceConfiguration(deviceId);
        res.json({
            success: true,
            data: configuration,
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        const statusCode = error.message.includes('not found') ? 404 : 500;
        res.status(statusCode).json({
            success: false,
            error: error.message || 'Failed to get device configuration',
            code: 'DEVICE_CONFIG_ERROR',
            timestamp: new Date().toISOString()
        });
    }
}));
// Get eUICC devices
router.get('/devices/:deviceId/euicc', auth_1.authenticateToken, (0, validation_1.validateUUID)('deviceId'), (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const { deviceId } = req.params;
        const intuneService = new intuneService_1.IntuneService(req.authProvider);
        const eUICCDevices = await intuneService.geteUICCDevices(deviceId);
        res.json({
            success: true,
            data: {
                eUICCDevices,
                count: eUICCDevices.length
            },
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: error.message || 'Failed to get eUICC devices',
            code: 'EUICC_FETCH_ERROR',
            timestamp: new Date().toISOString()
        });
    }
}));
// Configure eSIM profile
router.post('/devices/:deviceId/esim/configure', auth_1.authenticateToken, (0, auth_1.requireRole)(['admin', 'it_staff']), (0, validation_1.validateUUID)('deviceId'), (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const { deviceId } = req.params;
        const profileConfig = req.body;
        if (!profileConfig || Object.keys(profileConfig).length === 0) {
            return res.status(400).json({
                success: false,
                error: 'Profile configuration is required',
                code: 'MISSING_PROFILE_CONFIG',
                timestamp: new Date().toISOString()
            });
        }
        const { ICCID, serverName } = profileConfig;
        if (!ICCID || !serverName) {
            return res.status(400).json({
                success: false,
                error: 'ICCID and server name are required',
                code: 'MISSING_REQUIRED_FIELDS',
                timestamp: new Date().toISOString()
            });
        }
        if (!/^\d{19,20}$/.test(ICCID)) {
            return res.status(400).json({
                success: false,
                error: 'ICCID must be 19-20 digits',
                code: 'INVALID_ICCID_FORMAT',
                timestamp: new Date().toISOString()
            });
        }
        const intuneService = new intuneService_1.IntuneService(req.authProvider);
        const result = await intuneService.configureeSIMProfile(deviceId, profileConfig);
        if (!result) {
            return res.status(500).json({
                success: false,
                error: 'Failed to configure eSIM profile',
                code: 'ESIM_CONFIG_FAILED',
                timestamp: new Date().toISOString()
            });
        }
        res.status(201).json({
            success: true,
            message: 'eSIM profile configured successfully',
            data: { deviceId, ICCID },
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: error.message || 'Failed to configure eSIM profile',
            code: 'ESIM_CONFIG_ERROR',
            timestamp: new Date().toISOString()
        });
    }
}));
// Reset eSIM to factory state
router.post('/devices/:deviceId/esim/:eUICCId/reset', auth_1.authenticateToken, (0, auth_1.requireRole)(['admin']), (0, validation_1.validateUUID)('deviceId'), (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const { deviceId, eUICCId } = req.params;
        if (!eUICCId || typeof eUICCId !== 'string') {
            return res.status(400).json({
                success: false,
                error: 'Valid eUICC ID is required',
                code: 'INVALID_EUICC_ID',
                timestamp: new Date().toISOString()
            });
        }
        const intuneService = new intuneService_1.IntuneService(req.authProvider);
        const result = await intuneService.reseteSIMToFactory(deviceId, eUICCId);
        if (!result) {
            return res.status(500).json({
                success: false,
                error: 'Failed to reset eSIM to factory state',
                code: 'ESIM_RESET_FAILED',
                timestamp: new Date().toISOString()
            });
        }
        res.json({
            success: true,
            message: 'eSIM reset to factory state successfully',
            data: { deviceId, eUICCId },
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: error.message || 'Failed to reset eSIM',
            code: 'ESIM_RESET_ERROR',
            timestamp: new Date().toISOString()
        });
    }
}));
// Get eSIM profile status
router.get('/devices/:deviceId/esim/:ICCID/status', auth_1.authenticateToken, (0, validation_1.validateUUID)('deviceId'), (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const { deviceId, ICCID } = req.params;
        if (!ICCID || !/^\d{19,20}$/.test(ICCID)) {
            return res.status(400).json({
                success: false,
                error: 'Valid ICCID is required (19-20 digits)',
                code: 'INVALID_ICCID',
                timestamp: new Date().toISOString()
            });
        }
        const intuneService = new intuneService_1.IntuneService(req.authProvider);
        const status = await intuneService.geteSIMProfileStatus(deviceId, ICCID);
        res.json({
            success: true,
            data: status,
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        const statusCode = error.message.includes('not found') ? 404 : 500;
        res.status(statusCode).json({
            success: false,
            error: error.message || 'Failed to get eSIM profile status',
            code: 'ESIM_STATUS_ERROR',
            timestamp: new Date().toISOString()
        });
    }
}));
// Enable eSIM profile
router.post('/devices/:deviceId/esim/:ICCID/enable', auth_1.authenticateToken, (0, auth_1.requireRole)(['admin', 'it_staff']), (0, validation_1.validateUUID)('deviceId'), (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const { deviceId, ICCID } = req.params;
        if (!ICCID || !/^\d{19,20}$/.test(ICCID)) {
            return res.status(400).json({
                success: false,
                error: 'Valid ICCID is required (19-20 digits)',
                code: 'INVALID_ICCID',
                timestamp: new Date().toISOString()
            });
        }
        const intuneService = new intuneService_1.IntuneService(req.authProvider);
        const result = await intuneService.enableeSIMProfile(deviceId, ICCID);
        if (!result) {
            return res.status(500).json({
                success: false,
                error: 'Failed to enable eSIM profile',
                code: 'ESIM_ENABLE_FAILED',
                timestamp: new Date().toISOString()
            });
        }
        res.json({
            success: true,
            message: 'eSIM profile enabled successfully',
            data: { deviceId, ICCID },
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: error.message || 'Failed to enable eSIM profile',
            code: 'ESIM_ENABLE_ERROR',
            timestamp: new Date().toISOString()
        });
    }
}));
// Disable eSIM profile
router.post('/devices/:deviceId/esim/:ICCID/disable', auth_1.authenticateToken, (0, auth_1.requireRole)(['admin', 'it_staff']), (0, validation_1.validateUUID)('deviceId'), (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const { deviceId, ICCID } = req.params;
        if (!ICCID || !/^\d{19,20}$/.test(ICCID)) {
            return res.status(400).json({
                success: false,
                error: 'Valid ICCID is required (19-20 digits)',
                code: 'INVALID_ICCID',
                timestamp: new Date().toISOString()
            });
        }
        const intuneService = new intuneService_1.IntuneService(req.authProvider);
        const result = await intuneService.disableeSIMProfile(deviceId, ICCID);
        if (!result) {
            return res.status(500).json({
                success: false,
                error: 'Failed to disable eSIM profile',
                code: 'ESIM_DISABLE_FAILED',
                timestamp: new Date().toISOString()
            });
        }
        res.json({
            success: true,
            message: 'eSIM profile disabled successfully',
            data: { deviceId, ICCID },
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: error.message || 'Failed to disable eSIM profile',
            code: 'ESIM_DISABLE_ERROR',
            timestamp: new Date().toISOString()
        });
    }
}));
// Get device compliance status
router.get('/devices/:deviceId/compliance', auth_1.authenticateToken, (0, validation_1.validateUUID)('deviceId'), (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const { deviceId } = req.params;
        const intuneService = new intuneService_1.IntuneService(req.authProvider);
        const compliance = await intuneService.getComplianceStatus(deviceId);
        res.json({
            success: true,
            data: compliance,
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: error.message || 'Failed to get compliance status',
            code: 'COMPLIANCE_STATUS_ERROR',
            timestamp: new Date().toISOString()
        });
    }
}));
// Sync device with Intune
router.post('/devices/:deviceId/sync', auth_1.authenticateToken, (0, auth_1.requireRole)(['admin', 'it_staff']), (0, validation_1.validateUUID)('deviceId'), (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const { deviceId } = req.params;
        const intuneService = new intuneService_1.IntuneService(req.authProvider);
        const result = await intuneService.syncDeviceWithIntune(deviceId);
        if (!result) {
            return res.status(500).json({
                success: false,
                error: 'Failed to sync device with Intune',
                code: 'DEVICE_SYNC_FAILED',
                timestamp: new Date().toISOString()
            });
        }
        res.json({
            success: true,
            message: 'Device sync initiated successfully',
            data: { deviceId },
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: error.message || 'Failed to sync device',
            code: 'DEVICE_SYNC_ERROR',
            timestamp: new Date().toISOString()
        });
    }
}));
// Get device actions
router.get('/devices/:deviceId/actions', auth_1.authenticateToken, (0, validation_1.validateUUID)('deviceId'), (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const { deviceId } = req.params;
        const intuneService = new intuneService_1.IntuneService(req.authProvider);
        const actions = await intuneService.getDeviceActions(deviceId);
        res.json({
            success: true,
            data: {
                actions,
                count: actions.length
            },
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: error.message || 'Failed to get device actions',
            code: 'DEVICE_ACTIONS_ERROR',
            timestamp: new Date().toISOString()
        });
    }
}));
exports.default = router;
//# sourceMappingURL=intune.js.map