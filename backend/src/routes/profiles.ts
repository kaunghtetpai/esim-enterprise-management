import express from 'express';
import { query } from '../config/database';
import { authenticateToken, requireRole } from '../middleware/auth';
import { validateProfile } from '../middleware/validation';

const router = express.Router();

// Get all profiles
router.get('/', authenticateToken, async (req: any, res) => {
  try {
    const { organizationId } = req.user;
    
    if (!organizationId) {
      return res.status(400).json({
        success: false,
        error: 'Organization ID is required',
        code: 'MISSING_ORGANIZATION_ID'
      });
    }
    
    const { page = 1, limit = 20, status, carrier } = req.query;
    
    // Validate pagination parameters
    const pageNum = parseInt(page as string);
    const limitNum = parseInt(limit as string);
    
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
    
    // Validate status parameter
    const validStatuses = ['active', 'inactive', 'suspended', 'expired'];
    if (status && !validStatuses.includes(status as string)) {
      return res.status(400).json({
        success: false,
        error: `Status must be one of: ${validStatuses.join(', ')}`,
        code: 'INVALID_STATUS_PARAMETER'
      });
    }
    
    // Validate carrier parameter
    const validCarriers = ['MPT', 'ATOM', 'U9', 'MYTEL'];
    if (carrier && !validCarriers.includes(carrier as string)) {
      return res.status(400).json({
        success: false,
        error: `Carrier must be one of: ${validCarriers.join(', ')}`,
        code: 'INVALID_CARRIER_PARAMETER'
      });
    }
    
    let queryText = `
      SELECT p.*, d.name as department_name 
      FROM esim_profiles p 
      LEFT JOIN departments d ON p.department_id = d.id 
      WHERE p.organization_id = $1
    `;
    const params = [organizationId];
    let paramCount = 1;

    if (status) {
      queryText += ` AND p.status = $${++paramCount}`;
      params.push(status);
    }

    if (carrier) {
      queryText += ` AND p.carrier = $${++paramCount}`;
      params.push(carrier);
    }

    queryText += ` ORDER BY p.created_at DESC LIMIT $${++paramCount} OFFSET $${++paramCount}`;
    params.push(limitNum, (pageNum - 1) * limitNum);

    const result = await query(queryText, params);
    
    // Get total count with same filters
    let countQuery = 'SELECT COUNT(*) FROM esim_profiles WHERE organization_id = $1';
    const countParams = [organizationId];
    let countParamCount = 1;
    
    if (status) {
      countQuery += ` AND status = $${++countParamCount}`;
      countParams.push(status);
    }
    
    if (carrier) {
      countQuery += ` AND carrier = $${++countParamCount}`;
      countParams.push(carrier);
    }
    
    const countResult = await query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: {
        profiles: result.rows,
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
  } catch (error) {
    console.error('Error fetching profiles:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch profiles',
      code: 'PROFILES_FETCH_ERROR',
      timestamp: new Date().toISOString()
    });
  }
});

// Create new profile
router.post('/', authenticateToken, requireRole(['admin', 'it_staff']), validateProfile, async (req: any, res) => {
  try {
    const { organizationId, userId } = req.user;
    
    if (!organizationId || !userId) {
      return res.status(400).json({
        success: false,
        error: 'User authentication data is incomplete',
        code: 'INCOMPLETE_AUTH_DATA'
      });
    }
    
    const {
      iccid,
      profile_name,
      carrier,
      carrier_code,
      msisdn,
      plan_name,
      data_allowance_mb,
      validity_days,
      department_id,
      cost_center,
      monthly_cost
    } = req.body;

    // Validate required fields
    const requiredFields = ['iccid', 'profile_name', 'carrier', 'carrier_code'];
    const missingFields = requiredFields.filter(field => !req.body[field]);
    
    if (missingFields.length > 0) {
      return res.status(400).json({
        success: false,
        error: `Missing required fields: ${missingFields.join(', ')}`,
        code: 'MISSING_REQUIRED_FIELDS',
        missingFields
      });
    }
    
    // Validate ICCID format (19-20 digits)
    if (!/^\d{19,20}$/.test(iccid)) {
      return res.status(400).json({
        success: false,
        error: 'ICCID must be 19-20 digits',
        code: 'INVALID_ICCID_FORMAT'
      });
    }
    
    // Validate carrier
    const validCarriers = ['MPT', 'ATOM', 'U9', 'MYTEL'];
    if (!validCarriers.includes(carrier)) {
      return res.status(400).json({
        success: false,
        error: `Carrier must be one of: ${validCarriers.join(', ')}`,
        code: 'INVALID_CARRIER'
      });
    }
    
    // Validate numeric fields
    if (data_allowance_mb && (isNaN(data_allowance_mb) || data_allowance_mb < 0)) {
      return res.status(400).json({
        success: false,
        error: 'Data allowance must be a positive number',
        code: 'INVALID_DATA_ALLOWANCE'
      });
    }
    
    if (validity_days && (isNaN(validity_days) || validity_days < 1)) {
      return res.status(400).json({
        success: false,
        error: 'Validity days must be a positive integer',
        code: 'INVALID_VALIDITY_DAYS'
      });
    }
    
    if (monthly_cost && (isNaN(monthly_cost) || monthly_cost < 0)) {
      return res.status(400).json({
        success: false,
        error: 'Monthly cost must be a positive number',
        code: 'INVALID_MONTHLY_COST'
      });
    }

    const result = await query(`
      INSERT INTO esim_profiles (
        organization_id, iccid, profile_name, carrier, carrier_code,
        msisdn, plan_name, data_allowance_mb, validity_days,
        department_id, cost_center, monthly_cost
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      RETURNING *
    `, [
      organizationId, iccid, profile_name, carrier, carrier_code,
      msisdn, plan_name, data_allowance_mb, validity_days,
      department_id, cost_center, monthly_cost
    ]);

    // Log audit trail
    try {
      await query(`
        INSERT INTO audit_logs (organization_id, user_id, action, resource_type, resource_id, new_values)
        VALUES ($1, $2, 'CREATE_PROFILE', 'profile', $3, $4)
      `, [organizationId, userId, result.rows[0].id, JSON.stringify(req.body)]);
    } catch (auditError) {
      console.error('Audit log failed:', auditError);
    }

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'Profile created successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error creating profile:', error);
    
    if (error.code === '23505') {
      return res.status(409).json({ 
        success: false,
        error: 'Profile with this ICCID already exists',
        code: 'DUPLICATE_ICCID',
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
      error: 'Failed to create profile',
      code: 'PROFILE_CREATE_ERROR',
      timestamp: new Date().toISOString()
    });
  }
});

// Get profile by ID
router.get('/:id', authenticateToken, async (req: any, res) => {
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
    
    // Validate ID format (UUID)
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(id)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid profile ID format',
        code: 'INVALID_ID_FORMAT'
      });
    }

    const result = await query(`
      SELECT p.*, d.name as department_name 
      FROM esim_profiles p 
      LEFT JOIN departments d ON p.department_id = d.id 
      WHERE p.id = $1 AND p.organization_id = $2
    `, [id, organizationId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Profile not found',
        code: 'PROFILE_NOT_FOUND',
        timestamp: new Date().toISOString()
      });
    }

    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch profile',
      code: 'PROFILE_FETCH_ERROR',
      timestamp: new Date().toISOString()
    });
  }
});

// Update profile
router.put('/:id', authenticateToken, requireRole(['admin', 'it_staff']), async (req: any, res) => {
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
        error: 'Invalid profile ID format',
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
      'profile_name', 'carrier', 'carrier_code', 'msisdn', 'plan_name',
      'data_allowance_mb', 'validity_days', 'department_id', 'cost_center',
      'monthly_cost', 'status'
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
    
    // Validate field values
    if (updates.carrier && !['MPT', 'ATOM', 'U9', 'MYTEL'].includes(updates.carrier)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid carrier value',
        code: 'INVALID_CARRIER_VALUE'
      });
    }
    
    if (updates.status && !['active', 'inactive', 'suspended', 'expired'].includes(updates.status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status value',
        code: 'INVALID_STATUS_VALUE'
      });
    }
    
    if (updates.data_allowance_mb && (isNaN(updates.data_allowance_mb) || updates.data_allowance_mb < 0)) {
      return res.status(400).json({
        success: false,
        error: 'Data allowance must be a positive number',
        code: 'INVALID_DATA_ALLOWANCE'
      });
    }

    // Get current profile for audit
    const currentResult = await query(
      'SELECT * FROM esim_profiles WHERE id = $1 AND organization_id = $2',
      [id, organizationId]
    );

    if (currentResult.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Profile not found',
        code: 'PROFILE_NOT_FOUND',
        timestamp: new Date().toISOString()
      });
    }

    const updateFields = Object.keys(updates).map((key, index) => `${key} = $${index + 3}`).join(', ');
    const updateValues = Object.values(updates);

    const result = await query(`
      UPDATE esim_profiles 
      SET ${updateFields}, updated_at = NOW()
      WHERE id = $1 AND organization_id = $2
      RETURNING *
    `, [id, organizationId, ...updateValues]);

    // Log audit trail
    try {
      await query(`
        INSERT INTO audit_logs (organization_id, user_id, action, resource_type, resource_id, old_values, new_values)
        VALUES ($1, $2, 'UPDATE_PROFILE', 'profile', $3, $4, $5)
      `, [organizationId, userId, id, JSON.stringify(currentResult.rows[0]), JSON.stringify(updates)]);
    } catch (auditError) {
      console.error('Audit log failed:', auditError);
    }

    res.json({
      success: true,
      data: result.rows[0],
      message: 'Profile updated successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error updating profile:', error);
    
    if (error.code === '23505') {
      return res.status(409).json({
        success: false,
        error: 'Duplicate value for unique field',
        code: 'DUPLICATE_VALUE',
        timestamp: new Date().toISOString()
      });
    }
    
    if (error.code === '23503') {
      return res.status(400).json({
        success: false,
        error: 'Invalid reference to related data',
        code: 'INVALID_REFERENCE',
        timestamp: new Date().toISOString()
      });
    }
    
    res.status(500).json({ 
      success: false,
      error: 'Failed to update profile',
      code: 'PROFILE_UPDATE_ERROR',
      timestamp: new Date().toISOString()
    });
  }
});

// Delete profile
router.delete('/:id', authenticateToken, requireRole(['admin']), async (req: any, res) => {
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
        error: 'Invalid profile ID format',
        code: 'INVALID_ID_FORMAT'
      });
    }

    // Check if profile exists first
    const profileCheck = await query(
      'SELECT * FROM esim_profiles WHERE id = $1 AND organization_id = $2',
      [id, organizationId]
    );
    
    if (profileCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Profile not found',
        code: 'PROFILE_NOT_FOUND',
        timestamp: new Date().toISOString()
      });
    }

    // Check if profile has active assignments
    const assignmentCheck = await query(
      'SELECT COUNT(*) FROM device_profile_assignments WHERE profile_id = $1 AND status = $2',
      [id, 'active']
    );

    if (parseInt(assignmentCheck.rows[0].count) > 0) {
      return res.status(409).json({ 
        success: false,
        error: 'Cannot delete profile with active assignments',
        code: 'PROFILE_HAS_ACTIVE_ASSIGNMENTS',
        activeAssignments: parseInt(assignmentCheck.rows[0].count),
        timestamp: new Date().toISOString()
      });
    }

    const result = await query(
      'DELETE FROM esim_profiles WHERE id = $1 AND organization_id = $2 RETURNING *',
      [id, organizationId]
    );

    // Log audit trail
    try {
      await query(`
        INSERT INTO audit_logs (organization_id, user_id, action, resource_type, resource_id, old_values)
        VALUES ($1, $2, 'DELETE_PROFILE', 'profile', $3, $4)
      `, [organizationId, userId, id, JSON.stringify(result.rows[0])]);
    } catch (auditError) {
      console.error('Audit log failed:', auditError);
    }

    res.status(200).json({
      success: true,
      message: 'Profile deleted successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error deleting profile:', error);
    
    if (error.code === '23503') {
      return res.status(409).json({
        success: false,
        error: 'Cannot delete profile due to existing references',
        code: 'PROFILE_HAS_REFERENCES',
        timestamp: new Date().toISOString()
      });
    }
    
    res.status(500).json({ 
      success: false,
      error: 'Failed to delete profile',
      code: 'PROFILE_DELETE_ERROR',
      timestamp: new Date().toISOString()
    });
  }
});

export default router;