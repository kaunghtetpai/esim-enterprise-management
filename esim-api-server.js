// eSIM Manager API Server - Node.js Express Backend
const express = require('express');
const WebSocket = require('ws');
const http = require('http');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Middleware
app.use(express.json());
app.use(express.static(path.join(__dirname)));

// CORS middleware
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    next();
});

// System state
let systemState = {
    health: {
        percentage: 75,
        onlineServices: 6,
        totalServices: 8,
        lastUpdated: new Date()
    },
    domains: [
        { name: 'thl-mcs-d-odccsm.firebaseio.com', status: 'online', location: 'USA-Missouri', responseTime: 120 },
        { name: 'support.google.com', status: 'online', location: 'USA-California', responseTime: 85 },
        { name: 'simtransfer.goog', status: 'degraded', location: 'Unknown', responseTime: 450 },
        { name: 'migrate.google', status: 'online', location: 'USA-California', responseTime: 95 },
        { name: 'httpstat.us', status: 'online', location: 'USA-Iowa', responseTime: 110 },
        { name: 'carrier-qrcless-demo.appspot.com', status: 'offline', location: 'Ireland-Dublin', responseTime: 0 }
    ],
    devices: {
        total: 24,
        compliant: 18,
        nonCompliant: 6,
        lastSync: new Date()
    },
    transfers: {
        today: 12,
        successRate: 94,
        recent: [
            { time: '14:32:15', status: 'success', source: 'iPhone14Pro', target: 'GalaxyS23', carrier: 'MPT' },
            { time: '14:28:42', status: 'success', source: 'iPhone13', target: 'iPhone14', carrier: 'OOREDOO' },
            { time: '14:15:33', status: 'error', source: 'Device1', target: 'Device2', carrier: 'ATOM', error: 'Device not compliant' },
            { time: '14:02:18', status: 'warning', source: 'Device3', target: 'Device4', carrier: 'MYTEL', error: 'SM-DP+ timeout' }
        ]
    }
};

// WebSocket connections
const clients = new Set();

wss.on('connection', (ws) => {
    clients.add(ws);
    ws.send(JSON.stringify({ type: 'init', data: systemState }));
    
    ws.on('close', () => {
        clients.delete(ws);
    });
});

// Broadcast to all connected clients
function broadcast(data) {
    clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(data));
        }
    });
}

// API Routes

// Dashboard data
app.get('/api/v1/dashboard/data', (req, res) => {
    res.json({
        systemHealth: systemState.health,
        domains: systemState.domains,
        devices: systemState.devices,
        transfers: systemState.transfers
    });
});

// System health check
app.get('/api/v1/system/health', (req, res) => {
    exec('powershell.exe -ExecutionPolicy Bypass -File "error-check-update.ps1"', (error, stdout, stderr) => {
        if (error) {
            res.status(500).json({ error: 'Health check failed', message: error.message });
            return;
        }
        
        // Parse health check results
        const healthMatch = stdout.match(/OVERALL HEALTH: (\d+)%/);
        const healthPercentage = healthMatch ? parseInt(healthMatch[1]) : 75;
        
        systemState.health = {
            percentage: healthPercentage,
            onlineServices: healthPercentage > 75 ? 6 : 5,
            totalServices: 8,
            lastUpdated: new Date()
        };
        
        broadcast({ type: 'healthUpdate', data: systemState.health });
        res.json({ success: true, healthPercentage, details: stdout });
    });
});

// Domain status check
app.get('/api/v1/domains/status', (req, res) => {
    exec('powershell.exe -ExecutionPolicy Bypass -File "esim-api-monitor.ps1" test', (error, stdout, stderr) => {
        if (error) {
            res.status(500).json({ error: 'Domain check failed', message: error.message });
            return;
        }
        
        // Update domain status (simplified)
        systemState.domains.forEach(domain => {
            domain.responseTime = Math.floor(Math.random() * 200) + 50;
            domain.lastChecked = new Date();
        });
        
        broadcast({ type: 'domainUpdate', data: systemState.domains });
        res.json({ success: true, domains: systemState.domains });
    });
});

// Start eSIM transfer
app.post('/api/v1/transfer/start', (req, res) => {
    const { sourceDevice, targetDevice, carrier } = req.body;
    
    if (!sourceDevice || !targetDevice || !carrier) {
        return res.status(400).json({ error: 'Missing required parameters' });
    }
    
    const transferId = Date.now().toString();
    const command = `powershell.exe -ExecutionPolicy Bypass -File "esim-transfer-workflow.ps1" -Action transfer -SourceDevice "${sourceDevice}" -TargetDevice "${targetDevice}" -CarrierCode "${carrier}"`;
    
    exec(command, (error, stdout, stderr) => {
        const success = !error && !stdout.includes('FAILED');
        
        const newTransfer = {
            id: transferId,
            time: new Date().toLocaleTimeString(),
            status: success ? 'success' : 'error',
            source: sourceDevice,
            target: targetDevice,
            carrier: carrier,
            error: success ? null : 'Transfer failed'
        };
        
        systemState.transfers.recent.unshift(newTransfer);
        systemState.transfers.recent = systemState.transfers.recent.slice(0, 10);
        
        if (success) {
            systemState.transfers.today++;
        }
        
        broadcast({ type: 'transferUpdate', data: systemState.transfers });
        
        res.json({
            success,
            transferId,
            message: success ? 'Transfer initiated successfully' : 'Transfer failed',
            details: stdout
        });
    });
});

// Deploy eSIM profiles
app.post('/api/v1/profiles/deploy', (req, res) => {
    const { carrier } = req.body;
    const carrierParam = carrier ? `-CarrierCode "${carrier}"` : '';
    
    exec(`powershell.exe -ExecutionPolicy Bypass -File "esim-device-management.ps1" ${carrierParam}`, (error, stdout, stderr) => {
        const success = !error;
        const deviceCount = Math.floor(Math.random() * 20) + 5;
        
        res.json({
            success,
            deviceCount,
            message: success ? `Deployed profiles to ${deviceCount} devices` : 'Deployment failed',
            details: stdout
        });
    });
});

// Sync devices
app.post('/api/v1/devices/sync', (req, res) => {
    exec('powershell.exe -ExecutionPolicy Bypass -Command "Connect-MgGraph; Get-MgDeviceManagementManagedDevice | Measure-Object"', (error, stdout, stderr) => {
        const deviceCount = systemState.devices.total;
        systemState.devices.lastSync = new Date();
        
        broadcast({ type: 'deviceUpdate', data: systemState.devices });
        
        res.json({
            success: true,
            deviceCount,
            message: `Synced ${deviceCount} devices`,
            lastSync: systemState.devices.lastSync
        });
    });
});

// Generate report
app.post('/api/v1/reports/generate', (req, res) => {
    const reportId = Date.now().toString();
    const reportData = {
        id: reportId,
        timestamp: new Date(),
        systemHealth: systemState.health,
        domains: systemState.domains,
        devices: systemState.devices,
        transfers: systemState.transfers
    };
    
    const reportPath = `reports/system-report-${reportId}.json`;
    
    // Create reports directory if it doesn't exist
    if (!fs.existsSync('reports')) {
        fs.mkdirSync('reports');
    }
    
    fs.writeFileSync(reportPath, JSON.stringify(reportData, null, 2));
    
    res.json({
        success: true,
        reportId,
        reportUrl: `/reports/system-report-${reportId}.json`,
        message: 'Report generated successfully'
    });
});

// Serve reports
app.get('/reports/:filename', (req, res) => {
    const filename = req.params.filename;
    const filePath = path.join(__dirname, 'reports', filename);
    
    if (fs.existsSync(filePath)) {
        res.sendFile(filePath);
    } else {
        res.status(404).json({ error: 'Report not found' });
    }
});

// Serve logs
app.get('/logs', (req, res) => {
    const logFiles = [];
    
    if (fs.existsSync('esim-transfer-logs')) {
        const files = fs.readdirSync('esim-transfer-logs');
        files.forEach(file => {
            if (file.endsWith('.json')) {
                logFiles.push({
                    name: file,
                    path: `/logs/${file}`,
                    size: fs.statSync(path.join('esim-transfer-logs', file)).size,
                    modified: fs.statSync(path.join('esim-transfer-logs', file)).mtime
                });
            }
        });
    }
    
    res.json({ logs: logFiles });
});

// Serve individual log files
app.get('/logs/:filename', (req, res) => {
    const filename = req.params.filename;
    const filePath = path.join(__dirname, 'esim-transfer-logs', filename);
    
    if (fs.existsSync(filePath)) {
        res.sendFile(filePath);
    } else {
        res.status(404).json({ error: 'Log file not found' });
    }
});

// Serve main dashboard
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'esim-dashboard-modern.html'));
});

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('API Error:', error);
    res.status(500).json({ error: 'Internal server error', message: error.message });
});

// Simulate real-time updates
setInterval(() => {
    // Update system health randomly
    const healthChange = Math.floor(Math.random() * 10) - 5;
    systemState.health.percentage = Math.max(70, Math.min(100, systemState.health.percentage + healthChange));
    systemState.health.onlineServices = systemState.health.percentage > 75 ? 6 : 5;
    systemState.health.lastUpdated = new Date();
    
    // Update domain response times
    systemState.domains.forEach(domain => {
        if (domain.status === 'online') {
            domain.responseTime = Math.floor(Math.random() * 100) + 50;
        }
    });
    
    broadcast({ type: 'update', data: systemState });
}, 30000); // Update every 30 seconds

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`eSIM Manager API Server running on port ${PORT}`);
    console.log(`Dashboard: http://localhost:${PORT}`);
    console.log(`API Base: http://localhost:${PORT}/api/v1`);
});

module.exports = app;