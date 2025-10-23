import express from 'express';
import { query } from '../config/database';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

router.get('/usage', authenticateToken, async (req: any, res) => {
  try {
    const { organizationId } = req.user;
    const result = await query(`
      SELECT 
        carrier,
        COUNT(*) as total_profiles,
        SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_profiles,
        SUM(data_allowance_mb) as total_data_mb,
        SUM(monthly_cost) as total_cost
      FROM esim_profiles 
      WHERE organization_id = $1 
      GROUP BY carrier
    `, [organizationId]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate usage report' });
  }
});

router.get('/compliance', authenticateToken, async (req: any, res) => {
  try {
    const { organizationId } = req.user;
    const result = await query(`
      SELECT 
        d.compliance_state,
        COUNT(*) as device_count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
      FROM devices d
      WHERE d.organization_id = $1 
      GROUP BY d.compliance_state
    `, [organizationId]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate compliance report' });
  }
});

export default router;