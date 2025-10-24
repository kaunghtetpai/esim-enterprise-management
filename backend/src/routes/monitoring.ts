import express from 'express';
import { query } from '../config/database';
import { authenticateToken, requireRole } from '../middleware/auth';
import { ComprehensiveErrorHandler } from '../middleware/comprehensiveErrorHandler';

const router = express.Router();

router.get('/health/detailed', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const [
      errorMetrics,
      healthMetrics,
      apiMetrics,
      systemConfig
    ] = await Promise.all([
      query(`
        SELECT 
          COUNT(*) as total_errors,
          COUNT(CASE WHEN timestamp >= NOW() - INTERVAL '1 hour' THEN 1 END) as errors_last_hour,
          COUNT(CASE WHEN timestamp >= NOW() - INTERVAL '24 hours' THEN 1 END) as errors_last_day,
          COUNT(DISTINCT url) as affected_endpoints
        FROM system_error_logs
      `),
      query(`
        SELECT metric_name, AVG(metric_value) as avg_value, MAX(metric_value) as max_value
        FROM system_health_metrics 
        WHERE timestamp >= NOW() - INTERVAL '1 hour'
        GROUP BY metric_name
      `),
      query(`
        SELECT 
          AVG(response_time_ms) as avg_response_time,
          COUNT(*) as total_requests,
          COUNT(CASE WHEN status_code >= 400 THEN 1 END) as error_requests,
          COUNT(CASE WHEN status_code >= 500 THEN 1 END) as server_errors
        FROM api_request_logs 
        WHERE timestamp >= NOW() - INTERVAL '1 hour'
      `),
      query('SELECT config_key, config_value FROM system_configuration')
    ]);

    const errorHandler = ComprehensiveErrorHandler.getMetrics();

    res.json({
      success: true,
      data: {
        timestamp: new Date().toISOString(),
        database: {
          errors: errorMetrics.rows[0],
          health: healthMetrics.rows,
          api: apiMetrics.rows[0]
        },
        runtime: {
          errorMetrics: errorHandler,
          uptime: process.uptime(),
          memory: process.memoryUsage(),
          cpu: process.cpuUsage()
        },
        configuration: systemConfig.rows.reduce((acc, row) => {
          acc[row.config_key] = row.config_value;
          return acc;
        }, {})
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch monitoring data',
      code: 'MONITORING_ERROR',
      timestamp: new Date().toISOString()
    });
  }
});

router.get('/errors/recent', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { limit = 50, severity, hours = 24 } = req.query;
    
    let queryText = `
      SELECT timestamp, method, url, error_details, user_id, severity
      FROM system_error_logs 
      WHERE timestamp >= NOW() - INTERVAL '${hours} hours'
    `;
    
    const params = [];
    let paramCount = 0;
    
    if (severity) {
      queryText += ` AND severity = $${++paramCount}`;
      params.push(severity);
    }
    
    queryText += ` ORDER BY timestamp DESC LIMIT $${++paramCount}`;
    params.push(limit);
    
    const result = await query(queryText, params);
    
    res.json({
      success: true,
      data: {
        errors: result.rows,
        total: result.rows.length,
        timeRange: `${hours} hours`,
        severity: severity || 'all'
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch error logs',
      code: 'ERROR_LOGS_FETCH_ERROR',
      timestamp: new Date().toISOString()
    });
  }
});

router.get('/performance/metrics', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { hours = 1 } = req.query;
    
    const [responseTimeMetrics, errorRateMetrics, throughputMetrics] = await Promise.all([
      query(`
        SELECT 
          DATE_TRUNC('minute', timestamp) as minute,
          AVG(response_time_ms) as avg_response_time,
          MAX(response_time_ms) as max_response_time,
          MIN(response_time_ms) as min_response_time
        FROM api_request_logs 
        WHERE timestamp >= NOW() - INTERVAL '${hours} hours'
        GROUP BY DATE_TRUNC('minute', timestamp)
        ORDER BY minute DESC
      `),
      query(`
        SELECT 
          DATE_TRUNC('minute', timestamp) as minute,
          COUNT(*) as total_requests,
          COUNT(CASE WHEN status_code >= 400 THEN 1 END) as error_requests,
          ROUND(COUNT(CASE WHEN status_code >= 400 THEN 1 END) * 100.0 / COUNT(*), 2) as error_rate
        FROM api_request_logs 
        WHERE timestamp >= NOW() - INTERVAL '${hours} hours'
        GROUP BY DATE_TRUNC('minute', timestamp)
        ORDER BY minute DESC
      `),
      query(`
        SELECT 
          url,
          COUNT(*) as request_count,
          AVG(response_time_ms) as avg_response_time,
          COUNT(CASE WHEN status_code >= 400 THEN 1 END) as error_count
        FROM api_request_logs 
        WHERE timestamp >= NOW() - INTERVAL '${hours} hours'
        GROUP BY url
        ORDER BY request_count DESC
        LIMIT 20
      `)
    ]);

    res.json({
      success: true,
      data: {
        responseTime: responseTimeMetrics.rows,
        errorRate: errorRateMetrics.rows,
        throughput: throughputMetrics.rows,
        timeRange: `${hours} hours`
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch performance metrics',
      code: 'PERFORMANCE_METRICS_ERROR',
      timestamp: new Date().toISOString()
    });
  }
});

router.post('/alerts/configure', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { alertType, threshold, enabled, notificationMethod } = req.body;
    
    if (!alertType || threshold === undefined) {
      return res.status(400).json({
        success: false,
        error: 'Alert type and threshold are required',
        code: 'MISSING_ALERT_CONFIG',
        timestamp: new Date().toISOString()
      });
    }

    const alertConfig = {
      alertType,
      threshold,
      enabled: enabled !== false,
      notificationMethod: notificationMethod || 'email',
      createdBy: req.user.userId,
      createdAt: new Date().toISOString()
    };

    await query(`
      INSERT INTO system_configuration (config_key, config_value, config_type, description, updated_by)
      VALUES ($1, $2, 'json', $3, $4)
      ON CONFLICT (config_key) 
      DO UPDATE SET config_value = $2, updated_at = NOW(), updated_by = $4
    `, [
      `alert_${alertType}`,
      JSON.stringify(alertConfig),
      `Alert configuration for ${alertType}`,
      req.user.userId
    ]);

    res.json({
      success: true,
      data: alertConfig,
      message: 'Alert configuration saved successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to configure alert',
      code: 'ALERT_CONFIG_ERROR',
      timestamp: new Date().toISOString()
    });
  }
});

router.get('/system/status', async (req, res) => {
  try {
    const systemStatus = {
      status: 'operational',
      timestamp: new Date().toISOString(),
      services: {
        api: 'operational',
        database: 'operational',
        authentication: 'operational',
        intune: 'operational'
      },
      metrics: {
        uptime: process.uptime(),
        memoryUsage: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
        activeConnections: 0 // Would be tracked in production
      }
    };

    // Quick database check
    try {
      await query('SELECT 1');
    } catch (dbError) {
      systemStatus.status = 'degraded';
      systemStatus.services.database = 'error';
    }

    // Check recent error rate
    try {
      const errorCheck = await query(`
        SELECT COUNT(*) as error_count
        FROM system_error_logs 
        WHERE timestamp >= NOW() - INTERVAL '5 minutes'
      `);
      
      if (parseInt(errorCheck.rows[0].error_count) > 10) {
        systemStatus.status = 'degraded';
      }
    } catch (error) {
      // Ignore error check failure
    }

    res.json({
      success: true,
      data: systemStatus
    });
  } catch (error) {
    res.status(503).json({
      success: false,
      error: 'System status check failed',
      code: 'STATUS_CHECK_ERROR',
      timestamp: new Date().toISOString()
    });
  }
});

export default router;