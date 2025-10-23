import express from 'express';
import { query } from '../config/database';
import { authenticateToken, requireRole } from '../middleware/auth';

const router = express.Router();

router.get('/', authenticateToken, async (req: any, res) => {
  try {
    const { organizationId } = req.user;
    const result = await query(`
      SELECT d.*, u.display_name as user_name 
      FROM devices d 
      LEFT JOIN users u ON d.user_id = u.id 
      WHERE d.organization_id = $1 
      ORDER BY d.created_at DESC
    `, [organizationId]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch devices' });
  }
});

router.post('/', authenticateToken, requireRole(['admin', 'it_staff']), async (req: any, res) => {
  try {
    const { organizationId, userId } = req.user;
    const { device_name, intune_device_id, model, manufacturer, serial_number, imei } = req.body;

    const result = await query(`
      INSERT INTO devices (organization_id, device_name, intune_device_id, model, manufacturer, serial_number, imei)
      VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *
    `, [organizationId, device_name, intune_device_id, model, manufacturer, serial_number, imei]);

    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create device' });
  }
});

export default router;