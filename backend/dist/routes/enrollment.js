"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const auth_1 = require("../middleware/auth");
const errorHandler_1 = require("../middleware/errorHandler");
const router = express_1.default.Router();
router.post('/devices/enroll', auth_1.authenticateToken, (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const { deviceName, platform, userAgent } = req.body;
        if (!deviceName || !platform) {
            return res.status(400).json({
                success: false,
                error: 'Device name and platform are required',
                code: 'MISSING_DEVICE_INFO'
            });
        }
        const enrollmentData = {
            deviceName,
            platform,
            userAgent,
            enrolledBy: req.user.userId,
            enrollmentDate: new Date().toISOString(),
            status: 'pending'
        };
        res.status(201).json({
            success: true,
            data: enrollmentData,
            message: 'Device enrollment initiated'
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: 'Enrollment failed',
            code: 'ENROLLMENT_ERROR'
        });
    }
}));
router.post('/policies/esim', auth_1.authenticateToken, (0, auth_1.requireRole)(['admin']), (0, errorHandler_1.asyncHandler)(async (req, res) => {
    try {
        const { carrier, autoEnable, localUIEnabled, PPR1Allowed, maxAttempts } = req.body;
        if (!carrier) {
            return res.status(400).json({
                success: false,
                error: 'Carrier is required',
                code: 'MISSING_CARRIER'
            });
        }
        const policyData = {
            carrier,
            autoEnable: autoEnable || false,
            localUIEnabled: localUIEnabled || false,
            PPR1Allowed: PPR1Allowed || true,
            maxAttempts: maxAttempts || 3,
            createdBy: req.user.userId,
            createdAt: new Date().toISOString()
        };
        res.status(201).json({
            success: true,
            data: policyData,
            message: 'eSIM policy configured'
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: 'Policy configuration failed',
            code: 'POLICY_CONFIG_ERROR'
        });
    }
}));
exports.default = router;
