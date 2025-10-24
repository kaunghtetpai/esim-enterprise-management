"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const database_1 = require("../config/database");
const auth_1 = require("../middleware/auth");
const router = express_1.default.Router();
router.get('/', auth_1.authenticateToken, async (req, res) => {
    try {
        const { organizationId } = req.user;
        if (!organizationId) {
            return res.status(400).json({
                success: false,
                error: 'Organization ID is required',
                code: 'MISSING_ORGANIZATION_ID'
            });
        }
        const { page = 1, limit = 20, status, compliance_state } = req.query;
        // Validate pagination
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        if (isNaN(pageNum) || pageNum < 1) {
            return res.status(400).json({
                success: false,
                error: 'Page must be a positive integer',
                code: 'INVALID_PAGE_PARAMETER'
            });
        }
        if (isNaN(limitNum) || limitNum < 1 || limitNum > 100) {
            return res.status(400).json({
                success: false,
                error: 'Limit must be between 1 and 100',
                code: 'INVALID_LIMIT_PARAMETER'
            });
        }
        let queryText = `
      SELECT d.*, u.display_name as user_name 
      FROM devices d 
      LEFT JOIN users u ON d.user_id = u.id 
      WHERE d.organization_id = $1
    `;
        const params = [organizationId];
        let paramCount = 1;
        if (status) {
            queryText += ` AND d.status = $${++paramCount}`;
            params.push(status);
        }
        if (compliance_state) {
            queryText += ` AND d.compliance_state = $${++paramCount}`;
            params.push(compliance_state);
        }
        queryText += ` ORDER BY d.created_at DESC LIMIT $${++paramCount} OFFSET $${++paramCount}`;
        params.push(limitNum, (pageNum - 1) * limitNum);
        const result = await (0, database_1.query)(queryText, params);
        // Get total count
        let countQuery = 'SELECT COUNT(*) FROM devices WHERE organization_id = $1';
        const countParams = [organizationId];
        let countParamCount = 1;
        if (status) {
            countQuery += ` AND status = $${++countParamCount}`;
            countParams.push(status);
        }
        if (compliance_state) {
            countQuery += ` AND compliance_state = $${++countParamCount}`;
            countParams.push(compliance_state);
        }
        const countResult = await (0, database_1.query)(countQuery, countParams);
        const total = parseInt(countResult.rows[0].count);
        res.json({
            success: true,
            data: {
                devices: result.rows,
                pagination: {
                    total,
                    page: pageNum,
                    limit: limitNum,
                    totalPages: Math.ceil(total / limitNum),
                    hasNext: pageNum * limitNum < total,
                    hasPrev: pageNum > 1
                }
            },
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        console.error('Error fetching devices:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch devices',
            code: 'DEVICES_FETCH_ERROR',
            timestamp: new Date().toISOString()
        });
    }
});
router.post('/', auth_1.authenticateToken, (0, auth_1.requireRole)(['admin', 'it_staff']), async (req, res) => {
    try {
        const { organizationId, userId } = req.user;
        if (!organizationId || !userId) {
            return res.status(400).json({
                success: false,
                error: 'User authentication data is incomplete',
                code: 'INCOMPLETE_AUTH_DATA'
            });
        }
        const { device_name, intune_device_id, model, manufacturer, serial_number, imei } = req.body;
        // Validate required fields
        const requiredFields = ['device_name', 'model', 'manufacturer'];
        const missingFields = requiredFields.filter(field => !req.body[field]);
        if (missingFields.length > 0) {
            return res.status(400).json({
                success: false,
                error: `Missing required fields: ${missingFields.join(', ')}`,
                code: 'MISSING_REQUIRED_FIELDS',
                missingFields
            });
        }
        // Validate IMEI format (15 digits)
        if (imei && !/^\d{15}$/.test(imei)) {
            return res.status(400).json({
                success: false,
                error: 'IMEI must be exactly 15 digits',
                code: 'INVALID_IMEI_FORMAT'
            });
        }
        // Validate device name length
        if (device_name.length < 2 || device_name.length > 100) {
            return res.status(400).json({
                success: false,
                error: 'Device name must be between 2 and 100 characters',
                code: 'INVALID_DEVICE_NAME_LENGTH'
            });
        }
        const result = await (0, database_1.query)(`
      INSERT INTO devices (organization_id, device_name, intune_device_id, model, manufacturer, serial_number, imei)
      VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *
    `, [organizationId, device_name, intune_device_id, model, manufacturer, serial_number, imei]);
        // Log audit trail
        try {
            await (0, database_1.query)(`
        INSERT INTO audit_logs (organization_id, user_id, action, resource_type, resource_id, new_values)
        VALUES ($1, $2, 'CREATE_DEVICE', 'device', $3, $4)
      `, [organizationId, userId, result.rows[0].id, JSON.stringify(req.body)]);
        }
        catch (auditError) {
            console.error('Audit log failed:', auditError);
        }
        res.status(201).json({
            success: true,
            data: result.rows[0],
            message: 'Device created successfully',
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        console.error('Error creating device:', error);
        if (error.code === '23505') {
            return res.status(409).json({
                success: false,
                error: 'Device with this identifier already exists',
                code: 'DUPLICATE_DEVICE',
                timestamp: new Date().toISOString()
            });
        }
        if (error.code === '23503') {
            return res.status(400).json({
                success: false,
                error: 'Invalid organization reference',
                code: 'INVALID_REFERENCE',
                timestamp: new Date().toISOString()
            });
        }
        res.status(500).json({
            success: false,
            error: 'Failed to create device',
            code: 'DEVICE_CREATE_ERROR',
            timestamp: new Date().toISOString()
        });
    }
});
// Get device by ID
router.get('/:id', auth_1.authenticateToken, async (req, res) => {
    try {
        const { organizationId } = req.user;
        const { id } = req.params;
        if (!organizationId) {
            return res.status(400).json({
                success: false,
                error: 'Organization ID is required',
                code: 'MISSING_ORGANIZATION_ID'
            });
        }
        // Validate ID format
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
        if (!uuidRegex.test(id)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid device ID format',
                code: 'INVALID_ID_FORMAT'
            });
        }
        const result = await (0, database_1.query)(`
      SELECT d.*, u.display_name as user_name 
      FROM devices d 
      LEFT JOIN users u ON d.user_id = u.id 
      WHERE d.id = $1 AND d.organization_id = $2
    `, [id, organizationId]);
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Device not found',
                code: 'DEVICE_NOT_FOUND',
                timestamp: new Date().toISOString()
            });
        }
        res.json({
            success: true,
            data: result.rows[0],
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        console.error('Error fetching device:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch device',
            code: 'DEVICE_FETCH_ERROR',
            timestamp: new Date().toISOString()
        });
    }
});
// Update device
router.put('/:id', auth_1.authenticateToken, (0, auth_1.requireRole)(['admin', 'it_staff']), async (req, res) => {
    try {
        const { organizationId, userId } = req.user;
        const { id } = req.params;
        const updates = req.body;
        if (!organizationId || !userId) {
            return res.status(400).json({
                success: false,
                error: 'User authentication data is incomplete',
                code: 'INCOMPLETE_AUTH_DATA'
            });
        }
        // Validate ID format
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
        if (!uuidRegex.test(id)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid device ID format',
                code: 'INVALID_ID_FORMAT'
            });
        }
        if (!updates || Object.keys(updates).length === 0) {
            return res.status(400).json({
                success: false,
                error: 'No update data provided',
                code: 'NO_UPDATE_DATA'
            });
        }
        // Validate updatable fields
        const allowedFields = [
            'device_name', 'model', 'manufacturer', 'serial_number', 'imei',
            'status', 'compliance_state', 'user_id'
        ];
        const invalidFields = Object.keys(updates).filter(field => !allowedFields.includes(field));
        if (invalidFields.length > 0) {
            return res.status(400).json({
                success: false,
                error: `Invalid fields: ${invalidFields.join(', ')}`,
                code: 'INVALID_UPDATE_FIELDS',
                allowedFields
            });
        }
        // Validate IMEI if provided
        if (updates.imei && !/^\d{15}$/.test(updates.imei)) {
            return res.status(400).json({
                success: false,
                error: 'IMEI must be exactly 15 digits',
                code: 'INVALID_IMEI_FORMAT'
            });
        }
        // Get current device for audit
        const currentResult = await (0, database_1.query)('SELECT * FROM devices WHERE id = $1 AND organization_id = $2', [id, organizationId]);
        if (currentResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Device not found',
                code: 'DEVICE_NOT_FOUND',
                timestamp: new Date().toISOString()
            });
        }
        const updateFields = Object.keys(updates).map((key, index) => `${key} = $${index + 3}`).join(', ');
        const updateValues = Object.values(updates);
        const result = await (0, database_1.query)(`
      UPDATE devices 
      SET ${updateFields}, updated_at = NOW()
      WHERE id = $1 AND organization_id = $2
      RETURNING *
    `, [id, organizationId, ...updateValues]);
        // Log audit trail
        try {
            await (0, database_1.query)(`
        INSERT INTO audit_logs (organization_id, user_id, action, resource_type, resource_id, old_values, new_values)
        VALUES ($1, $2, 'UPDATE_DEVICE', 'device', $3, $4, $5)
      `, [organizationId, userId, id, JSON.stringify(currentResult.rows[0]), JSON.stringify(updates)]);
        }
        catch (auditError) {
            console.error('Audit log failed:', auditError);
        }
        res.json({
            success: true,
            data: result.rows[0],
            message: 'Device updated successfully',
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        console.error('Error updating device:', error);
        if (error.code === '23505') {
            return res.status(409).json({
                success: false,
                error: 'Duplicate value for unique field',
                code: 'DUPLICATE_VALUE',
                timestamp: new Date().toISOString()
            });
        }
        res.status(500).json({
            success: false,
            error: 'Failed to update device',
            code: 'DEVICE_UPDATE_ERROR',
            timestamp: new Date().toISOString()
        });
    }
});
// Delete device
router.delete('/:id', auth_1.authenticateToken, (0, auth_1.requireRole)(['admin']), async (req, res) => {
    try {
        const { organizationId, userId } = req.user;
        const { id } = req.params;
        if (!organizationId || !userId) {
            return res.status(400).json({
                success: false,
                error: 'User authentication data is incomplete',
                code: 'INCOMPLETE_AUTH_DATA'
            });
        }
        // Validate ID format
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
        if (!uuidRegex.test(id)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid device ID format',
                code: 'INVALID_ID_FORMAT'
            });
        }
        // Check if device has active profile assignments
        const assignmentCheck = await (0, database_1.query)('SELECT COUNT(*) FROM device_profile_assignments WHERE device_id = $1 AND status = $2', [id, 'active']);
        if (parseInt(assignmentCheck.rows[0].count) > 0) {
            return res.status(409).json({
                success: false,
                error: 'Cannot delete device with active profile assignments',
                code: 'DEVICE_HAS_ACTIVE_ASSIGNMENTS',
                activeAssignments: parseInt(assignmentCheck.rows[0].count),
                timestamp: new Date().toISOString()
            });
        }
        const result = await (0, database_1.query)('DELETE FROM devices WHERE id = $1 AND organization_id = $2 RETURNING *', [id, organizationId]);
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Device not found',
                code: 'DEVICE_NOT_FOUND',
                timestamp: new Date().toISOString()
            });
        }
        // Log audit trail
        try {
            await (0, database_1.query)(`
        INSERT INTO audit_logs (organization_id, user_id, action, resource_type, resource_id, old_values)
        VALUES ($1, $2, 'DELETE_DEVICE', 'device', $3, $4)
      `, [organizationId, userId, id, JSON.stringify(result.rows[0])]);
        }
        catch (auditError) {
            console.error('Audit log failed:', auditError);
        }
        res.status(200).json({
            success: true,
            message: 'Device deleted successfully',
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        console.error('Error deleting device:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete device',
            code: 'DEVICE_DELETE_ERROR',
            timestamp: new Date().toISOString()
        });
    }
});
exports.default = router;
