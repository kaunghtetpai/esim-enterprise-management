import express from 'express';
import { query } from '../config/database';
import { authenticateToken, requireRole } from '../middleware/auth';

const router = express.Router();

router.get('/', authenticateToken, async (req: any, res) => {
  try {
    const { organizationId } = req.user;
    const result = await query(`
      SELECT u.*, d.name as department_name 
      FROM users u 
      LEFT JOIN departments d ON u.department_id = d.id 
      WHERE u.organization_id = $1 
      ORDER BY u.display_name
    `, [organizationId]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

router.post('/', authenticateToken, requireRole(['admin']), async (req: any, res) => {
  try {
    const { organizationId } = req.user;
    const { azure_user_id, email, display_name, job_title, phone, role, department_id } = req.body;

    const result = await query(`
      INSERT INTO users (organization_id, azure_user_id, email, display_name, job_title, phone, role, department_id)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *
    `, [organizationId, azure_user_id, email, display_name, job_title, phone, role, department_id]);

    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create user' });
  }
});

export default router;