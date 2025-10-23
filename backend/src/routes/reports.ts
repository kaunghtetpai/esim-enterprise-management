import express from 'express';
import { query } from '../config/database';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

router.get('/usage', authenticateToken, async (req: any, res) => {
  try {
    const { organizationId } = req.user;
    
    if (!organizationId) {
      return res.status(400).json({
        success: false,
        error: 'Organization ID is required',
        code: 'MISSING_ORGANIZATION_ID'
      });
    }
    
    const { start_date, end_date, carrier, department_id } = req.query;
    
    // Validate date format if provided
    if (start_date && !/^\d{4}-\d{2}-\d{2}$/.test(start_date as string)) {
      return res.status(400).json({
        success: false,
        error: 'Start date must be in YYYY-MM-DD format',
        code: 'INVALID_START_DATE_FORMAT'
      });
    }
    
    if (end_date && !/^\d{4}-\d{2}-\d{2}$/.test(end_date as string)) {
      return res.status(400).json({
        success: false,
        error: 'End date must be in YYYY-MM-DD format',
        code: 'INVALID_END_DATE_FORMAT'
      });
    }
    
    let queryText = `
      SELECT 
        carrier,
        COUNT(*) as total_profiles,
        SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_profiles,
        SUM(data_allowance_mb) as total_data_mb,
        SUM(monthly_cost) as total_cost
      FROM esim_profiles 
      WHERE organization_id = $1
    `;
    const params = [organizationId];
    let paramCount = 1;
    
    if (start_date) {
      queryText += ` AND created_at >= $${++paramCount}`;
      params.push(start_date);
    }
    
    if (end_date) {
      queryText += ` AND created_at <= $${++paramCount}`;
      params.push(end_date);
    }
    
    if (carrier) {
      queryText += ` AND carrier = $${++paramCount}`;
      params.push(carrier);
    }
    
    if (department_id) {
      queryText += ` AND department_id = $${++paramCount}`;
      params.push(department_id);
    }
    
    queryText += ' GROUP BY carrier ORDER BY carrier';
    
    const result = await query(queryText, params);
    
    res.json({
      success: true,
      data: {
        usage: result.rows,
        filters: {
          start_date: start_date || null,
          end_date: end_date || null,
          carrier: carrier || null,
          department_id: department_id || null
        },
        summary: {
          total_carriers: result.rows.length,
          grand_total_profiles: result.rows.reduce((sum, row) => sum + parseInt(row.total_profiles), 0),
          grand_total_cost: result.rows.reduce((sum, row) => sum + parseFloat(row.total_cost || 0), 0)
        }
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error generating usage report:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to generate usage report',
      code: 'USAGE_REPORT_ERROR',
      timestamp: new Date().toISOString()
    });
  }
});

router.get('/compliance', authenticateToken, async (req: any, res) => {
  try {
    const { organizationId } = req.user;
    
    if (!organizationId) {
      return res.status(400).json({
        success: false,
        error: 'Organization ID is required',
        code: 'MISSING_ORGANIZATION_ID'
      });
    }
    
    const { department_id, device_type } = req.query;
    
    let queryText = `
      SELECT 
        d.compliance_state,
        COUNT(*) as device_count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
      FROM devices d
      WHERE d.organization_id = $1
    `;
    const params = [organizationId];
    let paramCount = 1;
    
    if (department_id) {
      queryText += ` AND EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = d.user_id AND u.department_id = $${++paramCount}
      )`;
      params.push(department_id);
    }
    
    if (device_type) {
      queryText += ` AND d.model ILIKE $${++paramCount}`;
      params.push(`%${device_type}%`);
    }
    
    queryText += ' GROUP BY d.compliance_state ORDER BY d.compliance_state';
    
    const result = await query(queryText, params);
    
    // Get additional compliance metrics
    const metricsQuery = `
      SELECT 
        COUNT(*) as total_devices,
        SUM(CASE WHEN compliance_state = 'compliant' THEN 1 ELSE 0 END) as compliant_devices,
        SUM(CASE WHEN compliance_state = 'non_compliant' THEN 1 ELSE 0 END) as non_compliant_devices,
        SUM(CASE WHEN compliance_state = 'unknown' THEN 1 ELSE 0 END) as unknown_devices
      FROM devices 
      WHERE organization_id = $1
    `;
    
    const metricsResult = await query(metricsQuery, [organizationId]);
    const metrics = metricsResult.rows[0];
    
    res.json({
      success: true,
      data: {
        compliance: result.rows,
        metrics: {
          total_devices: parseInt(metrics.total_devices),
          compliant_devices: parseInt(metrics.compliant_devices),
          non_compliant_devices: parseInt(metrics.non_compliant_devices),
          unknown_devices: parseInt(metrics.unknown_devices),
          compliance_rate: metrics.total_devices > 0 
            ? Math.round((metrics.compliant_devices / metrics.total_devices) * 100)
            : 0
        },
        filters: {
          department_id: department_id || null,
          device_type: device_type || null
        }
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error generating compliance report:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to generate compliance report',
      code: 'COMPLIANCE_REPORT_ERROR',
      timestamp: new Date().toISOString()
    });
  }
});

export default router;