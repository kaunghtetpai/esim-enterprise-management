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
        const { page = 1, limit = 20, role, department_id } = req.query;
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
      SELECT u.*, d.name as department_name 
      FROM users u 
      LEFT JOIN departments d ON u.department_id = d.id 
      WHERE u.organization_id = $1
    `;
        const params = [organizationId];
        let paramCount = 1;
        if (role) {
            queryText += ` AND u.role = $${++paramCount}`;
            params.push(role);
        }
        if (department_id) {
            queryText += ` AND u.department_id = $${++paramCount}`;
            params.push(department_id);
        }
        queryText += ` ORDER BY u.display_name LIMIT $${++paramCount} OFFSET $${++paramCount}`;
        params.push(limitNum, (pageNum - 1) * limitNum);
        const result = await (0, database_1.query)(queryText, params);
        // Get total count
        let countQuery = 'SELECT COUNT(*) FROM users WHERE organization_id = $1';
        const countParams = [organizationId];
        let countParamCount = 1;
        if (role) {
            countQuery += ` AND role = $${++countParamCount}`;
            countParams.push(role);
        }
        if (department_id) {
            countQuery += ` AND department_id = $${++countParamCount}`;
            countParams.push(department_id);
        }
        const countResult = await (0, database_1.query)(countQuery, countParams);
        const total = parseInt(countResult.rows[0].count);
        res.json({
            success: true,
            data: {
                users: result.rows,
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
        console.error('Error fetching users:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch users',
            code: 'USERS_FETCH_ERROR',
            timestamp: new Date().toISOString()
        });
    }
});
router.post('/', auth_1.authenticateToken, (0, auth_1.requireRole)(['admin']), async (req, res) => {
    try {
        const { organizationId, userId } = req.user;
        if (!organizationId || !userId) {
            return res.status(400).json({
                success: false,
                error: 'User authentication data is incomplete',
                code: 'INCOMPLETE_AUTH_DATA'
            });
        }
        const { azure_user_id, email, display_name, job_title, phone, role, department_id } = req.body;
        // Validate required fields
        const requiredFields = ['azure_user_id', 'email', 'display_name', 'role'];
        const missingFields = requiredFields.filter(field => !req.body[field]);
        if (missingFields.length > 0) {
            return res.status(400).json({
                success: false,
                error: `Missing required fields: ${missingFields.join(', ')}`,
                code: 'MISSING_REQUIRED_FIELDS',
                missingFields
            });
        }
        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid email format',
                code: 'INVALID_EMAIL_FORMAT'
            });
        }
        // Validate role
        const validRoles = ['admin', 'it_staff', 'end_user'];
        if (!validRoles.includes(role)) {
            return res.status(400).json({
                success: false,
                error: `Role must be one of: ${validRoles.join(', ')}`,
                code: 'INVALID_ROLE'
            });
        }
        // Validate phone format if provided
        if (phone && !/^\+?[1-9]\d{1,14}$/.test(phone.replace(/[\s-]/g, ''))) {
            return res.status(400).json({
                success: false,
                error: 'Invalid phone number format',
                code: 'INVALID_PHONE_FORMAT'
            });
        }
        const result = await (0, database_1.query)(`
      INSERT INTO users (organization_id, azure_user_id, email, display_name, job_title, phone, role, department_id)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *
    `, [organizationId, azure_user_id, email, display_name, job_title, phone, role, department_id]);
        // Log audit trail
        try {
            await (0, database_1.query)(`
        INSERT INTO audit_logs (organization_id, user_id, action, resource_type, resource_id, new_values)
        VALUES ($1, $2, 'CREATE_USER', 'user', $3, $4)
      `, [organizationId, userId, result.rows[0].id, JSON.stringify(req.body)]);
        }
        catch (auditError) {
            console.error('Audit log failed:', auditError);
        }
        res.status(201).json({
            success: true,
            data: result.rows[0],
            message: 'User created successfully',
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        console.error('Error creating user:', error);
        if (error.code === '23505') {
            return res.status(409).json({
                success: false,
                error: 'User with this email or Azure ID already exists',
                code: 'DUPLICATE_USER',
                timestamp: new Date().toISOString()
            });
        }
        if (error.code === '23503') {
            return res.status(400).json({
                success: false,
                error: 'Invalid department or organization reference',
                code: 'INVALID_REFERENCE',
                timestamp: new Date().toISOString()
            });
        }
        res.status(500).json({
            success: false,
            error: 'Failed to create user',
            code: 'USER_CREATE_ERROR',
            timestamp: new Date().toISOString()
        });
    }
});
exports.default = router;
//# sourceMappingURL=users.js.map