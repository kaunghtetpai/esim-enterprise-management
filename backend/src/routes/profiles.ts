import express from 'express';
import { query } from '../config/database';
import { authenticateToken, requireRole } from '../middleware/auth';
import { validateProfile } from '../middleware/validation';

const router = express.Router();

// Get all profiles
router.get('/', authenticateToken, async (req: any, res) => {
  try {
    const { organizationId } = req.user;
    const { page = 1, limit = 20, status, carrier } = req.query;
    
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
    params.push(limit, (page - 1) * limit);

    const result = await query(queryText, params);
    
    // Get total count
    const countResult = await query(
      'SELECT COUNT(*) FROM esim_profiles WHERE organization_id = $1',
      [organizationId]
    );

    res.json({
      profiles: result.rows,
      total: parseInt(countResult.rows[0].count),
      page: parseInt(page),
      limit: parseInt(limit)
    });
  } catch (error) {
    console.error('Error fetching profiles:', error);
    res.status(500).json({ error: 'Failed to fetch profiles' });
  }
});

// Create new profile
router.post('/', authenticateToken, requireRole(['admin', 'it_staff']), validateProfile, async (req: any, res) => {
  try {
    const { organizationId, userId } = req.user;
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
    await query(`
      INSERT INTO audit_logs (organization_id, user_id, action, resource_type, resource_id, new_values)
      VALUES ($1, $2, 'CREATE_PROFILE', 'profile', $3, $4)
    `, [organizationId, userId, result.rows[0].id, JSON.stringify(req.body)]);

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating profile:', error);
    if (error.code === '23505') {
      res.status(409).json({ error: 'Profile with this ICCID already exists' });
    } else {
      res.status(500).json({ error: 'Failed to create profile' });
    }
  }
});

// Get profile by ID
router.get('/:id', authenticateToken, async (req: any, res) => {
  try {
    const { organizationId } = req.user;
    const { id } = req.params;

    const result = await query(`
      SELECT p.*, d.name as department_name 
      FROM esim_profiles p 
      LEFT JOIN departments d ON p.department_id = d.id 
      WHERE p.id = $1 AND p.organization_id = $2
    `, [id, organizationId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Profile not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// Update profile
router.put('/:id', authenticateToken, requireRole(['admin', 'it_staff']), async (req: any, res) => {
  try {
    const { organizationId, userId } = req.user;
    const { id } = req.params;
    const updates = req.body;

    // Get current profile for audit
    const currentResult = await query(
      'SELECT * FROM esim_profiles WHERE id = $1 AND organization_id = $2',
      [id, organizationId]
    );

    if (currentResult.rows.length === 0) {
      return res.status(404).json({ error: 'Profile not found' });
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
    await query(`
      INSERT INTO audit_logs (organization_id, user_id, action, resource_type, resource_id, old_values, new_values)
      VALUES ($1, $2, 'UPDATE_PROFILE', 'profile', $3, $4, $5)
    `, [organizationId, userId, id, JSON.stringify(currentResult.rows[0]), JSON.stringify(updates)]);

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// Delete profile
router.delete('/:id', authenticateToken, requireRole(['admin']), async (req: any, res) => {
  try {
    const { organizationId, userId } = req.user;
    const { id } = req.params;

    // Check if profile has active assignments
    const assignmentCheck = await query(
      'SELECT COUNT(*) FROM device_profile_assignments WHERE profile_id = $1 AND status = $2',
      [id, 'active']
    );

    if (parseInt(assignmentCheck.rows[0].count) > 0) {
      return res.status(409).json({ error: 'Cannot delete profile with active assignments' });
    }

    const result = await query(
      'DELETE FROM esim_profiles WHERE id = $1 AND organization_id = $2 RETURNING *',
      [id, organizationId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Profile not found' });
    }

    // Log audit trail
    await query(`
      INSERT INTO audit_logs (organization_id, user_id, action, resource_type, resource_id, old_values)
      VALUES ($1, $2, 'DELETE_PROFILE', 'profile', $3, $4)
    `, [organizationId, userId, id, JSON.stringify(result.rows[0])]);

    res.status(204).send();
  } catch (error) {
    console.error('Error deleting profile:', error);
    res.status(500).json({ error: 'Failed to delete profile' });
  }
});

export default router;