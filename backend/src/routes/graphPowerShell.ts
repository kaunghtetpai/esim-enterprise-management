import express from 'express';
import { GraphPowerShellService } from '../services/graphPowerShellService';
import { authenticateToken, requireRole } from '../middleware/auth';
import { asyncHandler } from '../middleware/errorHandler';

const router = express.Router();
const graphService = new GraphPowerShellService();

router.post('/connect', authenticateToken, requireRole(['admin']), asyncHandler(async (req, res) => {
  try {
    const { tenantId, clientId, clientSecret, interactive, validateOnly } = req.body;

    if (!tenantId || typeof tenantId !== 'string' || tenantId.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Valid Tenant ID is required',
        code: 'MISSING_TENANT_ID',
        timestamp: new Date().toISOString()
      });
    }

    if (!clientId || typeof clientId !== 'string' || clientId.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Valid Client ID is required',
        code: 'MISSING_CLIENT_ID',
        timestamp: new Date().toISOString()
      });
    }

    const guidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    
    if (!guidRegex.test(tenantId)) {
      return res.status(400).json({
        success: false,
        error: 'Tenant ID must be a valid GUID format',
        code: 'INVALID_TENANT_ID_FORMAT',
        timestamp: new Date().toISOString()
      });
    }

    if (!guidRegex.test(clientId)) {
      return res.status(400).json({
        success: false,
        error: 'Client ID must be a valid GUID format',
        code: 'INVALID_CLIENT_ID_FORMAT',
        timestamp: new Date().toISOString()
      });
    }

    if (!interactive && (!clientSecret || clientSecret.length < 8)) {
      return res.status(400).json({
        success: false,
        error: 'Client Secret (minimum 8 characters) is required for non-interactive authentication',
        code: 'INVALID_CLIENT_SECRET',
        timestamp: new Date().toISOString()
      });
    }

    if (validateOnly) {
      const isValid = await graphService.validateConnection();
      return res.json({
        success: true,
        data: {
          isValid,
          message: isValid ? 'Connection is valid' : 'Connection validation failed'
        },
        timestamp: new Date().toISOString()
      });
    }

    const connected = await graphService.connectToGraph(
      tenantId, 
      clientId, 
      interactive ? undefined : clientSecret
    );

    if (!connected) {
      return res.status(401).json({
        success: false,
        error: 'Failed to authenticate with Microsoft Graph. Please check your credentials and permissions.',
        code: 'GRAPH_AUTH_FAILED',
        details: {
          tenantId: tenantId,
          clientId: clientId,
          authMethod: interactive ? 'interactive' : 'client_secret'
        },
        timestamp: new Date().toISOString()
      });
    }

    const connectionStatus = await graphService.getConnectionStatus();

    res.json({
      success: true,
      message: 'Connected to Microsoft Graph successfully',
      data: {
        connected: true,
        tenantId: tenantId,
        authMethod: interactive ? 'interactive' : 'client_secret',
        context: connectionStatus.context,
        portalLinks: {
          entraId: 'https://entra.microsoft.com/',
          intune: 'https://intune.microsoft.com/',
          graphExplorer: 'https://developer.microsoft.com/graph/graph-explorer'
        }
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Graph connection error:', error);
    
    let statusCode = 500;
    let errorCode = 'GRAPH_CONNECTION_ERROR';
    
    if (error.message.includes('authentication') || error.message.includes('credentials')) {
      statusCode = 401;
      errorCode = 'AUTHENTICATION_ERROR';
    } else if (error.message.includes('permission') || error.message.includes('access')) {
      statusCode = 403;
      errorCode = 'PERMISSION_ERROR';
    } else if (error.message.includes('network') || error.message.includes('timeout')) {
      statusCode = 503;
      errorCode = 'NETWORK_ERROR';
    }
    
    res.status(statusCode).json({
      success: false,
      error: error.message || 'Failed to connect to Microsoft Graph',
      code: errorCode,
      timestamp: new Date().toISOString()
    });
  }
}));

router.get('/devices', authenticateToken, asyncHandler(async (req, res) => {
  try {
    const { page = 1, limit = 20, filter, orderBy } = req.query;
    
    const pageNum = parseInt(page as string);
    const limitNum = parseInt(limit as string);
    
    if (isNaN(pageNum) || pageNum < 1) {
      return res.status(400).json({
        success: false,
        error: 'Page must be a positive integer',
        code: 'INVALID_PAGE_PARAMETER',
        timestamp: new Date().toISOString()
      });
    }
    
    if (isNaN(limitNum) || limitNum < 1 || limitNum > 100) {
      return res.status(400).json({
        success: false,
        error: 'Limit must be between 1 and 100',
        code: 'INVALID_LIMIT_PARAMETER',
        timestamp: new Date().toISOString()
      });
    }

    const connectionStatus = await graphService.getConnectionStatus();
    if (!connectionStatus.connected) {
      return res.status(401).json({
        success: false,
        error: 'Not connected to Microsoft Graph. Please connect first.',
        code: 'GRAPH_NOT_CONNECTED',
        timestamp: new Date().toISOString()
      });
    }

    const devices = await graphService.getManagedDevices();
    
    let filteredDevices = devices;
    if (filter) {
      const filterLower = filter.toString().toLowerCase();
      filteredDevices = devices.filter(device => 
        device.deviceName?.toLowerCase().includes(filterLower) ||
        device.operatingSystem?.toLowerCase().includes(filterLower) ||
        device.complianceState?.toLowerCase().includes(filterLower)
      );
    }
    
    if (orderBy) {
      const [field, direction] = orderBy.toString().split(':');
      const isDesc = direction?.toLowerCase() === 'desc';
      
      filteredDevices.sort((a, b) => {
        const aVal = a[field] || '';
        const bVal = b[field] || '';
        const comparison = aVal.localeCompare(bVal);
        return isDesc ? -comparison : comparison;
      });
    }
    
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = startIndex + limitNum;
    const paginatedDevices = filteredDevices.slice(startIndex, endIndex);

    res.json({
      success: true,
      data: {
        devices: paginatedDevices,
        pagination: {
          total: filteredDevices.length,
          page: pageNum,
          limit: limitNum,
          totalPages: Math.ceil(filteredDevices.length / limitNum),
          hasNext: endIndex < filteredDevices.length,
          hasPrev: pageNum > 1
        },
        summary: {
          totalDevices: devices.length,
          filteredDevices: filteredDevices.length,
          complianceStates: devices.reduce((acc, device) => {
            acc[device.complianceState] = (acc[device.complianceState] || 0) + 1;
            return acc;
          }, {})
        }
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Get devices error:', error);
    
    let statusCode = 500;
    let errorCode = 'GRAPH_DEVICES_ERROR';
    
    if (error.message.includes('not connected') || error.message.includes('authentication')) {
      statusCode = 401;
      errorCode = 'GRAPH_NOT_CONNECTED';
    } else if (error.message.includes('permission') || error.message.includes('access')) {
      statusCode = 403;
      errorCode = 'INSUFFICIENT_PERMISSIONS';
    }
    
    res.status(statusCode).json({
      success: false,
      error: error.message || 'Failed to retrieve managed devices',
      code: errorCode,
      timestamp: new Date().toISOString()
    });
  }
}));

router.post('/profiles', authenticateToken, requireRole(['admin', 'it_staff']), asyncHandler(async (req, res) => {
  try {
    const { profileName, iccid, carrier, activationCode } = req.body;

    if (!profileName || !iccid || !carrier) {
      return res.status(400).json({
        success: false,
        error: 'Profile name, ICCID, and carrier are required',
        code: 'MISSING_PROFILE_DATA',
        timestamp: new Date().toISOString()
      });
    }

    if (!/^\d{19,20}$/.test(iccid)) {
      return res.status(400).json({
        success: false,
        error: 'ICCID must be 19-20 digits',
        code: 'INVALID_ICCID_FORMAT',
        timestamp: new Date().toISOString()
      });
    }

    const validCarriers = ['MPT', 'ATOM', 'U9', 'MYTEL'];
    if (!validCarriers.includes(carrier)) {
      return res.status(400).json({
        success: false,
        error: `Carrier must be one of: ${validCarriers.join(', ')}`,
        code: 'INVALID_CARRIER',
        timestamp: new Date().toISOString()
      });
    }

    const profileId = await graphService.createeSIMProfile(
      profileName,
      iccid,
      carrier,
      activationCode
    );

    res.status(201).json({
      success: true,
      data: {
        profileId,
        profileName,
        iccid,
        carrier
      },
      message: 'eSIM profile created successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      code: 'GRAPH_PROFILE_CREATE_ERROR',
      timestamp: new Date().toISOString()
    });
  }
}));

router.post('/install-sdk', authenticateToken, requireRole(['admin']), asyncHandler(async (req, res) => {
  try {
    const { useBeta = false, force = false } = req.body;

    const installed = await graphService.installGraphSDK(useBeta);

    if (!installed) {
      return res.status(500).json({
        success: false,
        error: 'Failed to install Microsoft Graph SDK',
        code: 'SDK_INSTALL_FAILED',
        timestamp: new Date().toISOString()
      });
    }

    res.json({
      success: true,
      message: `Microsoft Graph SDK ${useBeta ? 'Beta' : ''} installed successfully`,
      data: {
        version: useBeta ? 'beta' : 'stable',
        portalLinks: {
          entraId: 'https://entra.microsoft.com/',
          intune: 'https://intune.microsoft.com/#allservices/category/All'
        }
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      code: 'SDK_INSTALL_ERROR',
      timestamp: new Date().toISOString()
    });
  }
}));

router.get('/status', authenticateToken, asyncHandler(async (req, res) => {
  try {
    const connectionStatus = await graphService.getConnectionStatus();
    
    res.json({
      success: true,
      data: {
        ...connectionStatus,
        portalLinks: {
          entraId: 'https://entra.microsoft.com/',
          intune: 'https://intune.microsoft.com/#allservices/category/All',
          graphExplorer: 'https://developer.microsoft.com/graph/graph-explorer'
        }
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      code: 'STATUS_CHECK_ERROR',
      timestamp: new Date().toISOString()
    });
  }
}));

router.post('/disconnect', authenticateToken, requireRole(['admin']), asyncHandler(async (req, res) => {
  try {
    graphService.disconnect();

    res.json({
      success: true,
      message: 'Disconnected from Microsoft Graph',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      code: 'GRAPH_DISCONNECT_ERROR',
      timestamp: new Date().toISOString()
    });
  }
}));

export default router;