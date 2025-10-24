"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.systemErrorService = exports.SystemErrorService = void 0;
const supabase_js_1 = require("@supabase/supabase-js");
const child_process_1 = require("child_process");
const util_1 = require("util");
const execAsync = (0, util_1.promisify)(child_process_1.exec);
class SystemErrorService {
    constructor() {
        this.supabase = (0, supabase_js_1.createClient)(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
        this.errors = [];
    }
    async checkSystemHealth() {
        const health = {
            overall: 'healthy',
            database: false,
            api: false,
            auth: false,
            network: false,
            disk: 0,
            memory: 0,
            errors: []
        };
        try {
            // Database check
            health.database = await this.checkDatabase();
            // API endpoints check
            health.api = await this.checkAPIEndpoints();
            // Authentication check
            health.auth = await this.checkAuthentication();
            // Network connectivity
            health.network = await this.checkNetworkConnectivity();
            // System resources
            const resources = await this.checkSystemResources();
            health.disk = resources.disk;
            health.memory = resources.memory;
            // Get recent errors
            health.errors = this.errors.filter(e => !e.resolved);
            // Determine overall health
            health.overall = this.calculateOverallHealth(health);
            return health;
        }
        catch (error) {
            this.logError('system', 'critical', 'System health check failed', error);
            health.overall = 'critical';
            return health;
        }
    }
    async checkDatabase() {
        try {
            const { data, error } = await this.supabase
                .from('organizations')
                .select('id')
                .limit(1);
            if (error)
                throw error;
            return true;
        }
        catch (error) {
            this.logError('database', 'high', 'Database connection failed', error);
            await this.attemptDatabaseFix();
            return false;
        }
    }
    async checkAPIEndpoints() {
        const endpoints = [
            '/api/v1/health',
            '/api/v1/profiles',
            '/api/v1/devices',
            '/api/v1/activation-codes'
        ];
        try {
            for (const endpoint of endpoints) {
                const response = await fetch(`http://localhost:8000${endpoint}`, {
                    method: 'GET',
                    timeout: 5000
                });
                if (!response.ok) {
                    throw new Error(`Endpoint ${endpoint} returned ${response.status}`);
                }
            }
            return true;
        }
        catch (error) {
            this.logError('api', 'medium', 'API endpoint check failed', error);
            return false;
        }
    }
    async checkAuthentication() {
        try {
            // Check Azure AD connection
            const { stdout } = await execAsync('powershell -Command "Get-MgContext | ConvertTo-Json"');
            const context = JSON.parse(stdout);
            if (!context || !context.Account) {
                throw new Error('No active Microsoft Graph session');
            }
            return true;
        }
        catch (error) {
            this.logError('auth', 'high', 'Authentication check failed', error);
            await this.attemptAuthFix();
            return false;
        }
    }
    async checkNetworkConnectivity() {
        const hosts = [
            'graph.microsoft.com',
            'login.microsoftonline.com',
            'supabase.com'
        ];
        try {
            for (const host of hosts) {
                await execAsync(`ping -n 1 ${host}`);
            }
            return true;
        }
        catch (error) {
            this.logError('network', 'medium', 'Network connectivity failed', error);
            return false;
        }
    }
    async checkSystemResources() {
        try {
            // Check disk space
            const { stdout: diskOutput } = await execAsync('powershell -Command "Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Select-Object Size,FreeSpace | ConvertTo-Json"');
            const diskInfo = JSON.parse(diskOutput);
            const diskUsage = ((diskInfo.Size - diskInfo.FreeSpace) / diskInfo.Size) * 100;
            // Check memory usage
            const { stdout: memOutput } = await execAsync('powershell -Command "Get-WmiObject -Class Win32_OperatingSystem | Select-Object TotalVisibleMemorySize,FreePhysicalMemory | ConvertTo-Json"');
            const memInfo = JSON.parse(memOutput);
            const memUsage = ((memInfo.TotalVisibleMemorySize - memInfo.FreePhysicalMemory) / memInfo.TotalVisibleMemorySize) * 100;
            if (diskUsage > 90) {
                this.logError('disk', 'high', `Disk usage critical: ${diskUsage.toFixed(1)}%`, { usage: diskUsage });
            }
            if (memUsage > 85) {
                this.logError('memory', 'medium', `Memory usage high: ${memUsage.toFixed(1)}%`, { usage: memUsage });
            }
            return { disk: diskUsage, memory: memUsage };
        }
        catch (error) {
            this.logError('system', 'medium', 'Resource check failed', error);
            return { disk: 0, memory: 0 };
        }
    }
    calculateOverallHealth(health) {
        const criticalErrors = health.errors.filter(e => e.severity === 'critical').length;
        const highErrors = health.errors.filter(e => e.severity === 'high').length;
        if (criticalErrors > 0 || !health.database || !health.auth) {
            return 'critical';
        }
        if (highErrors > 0 || !health.api || !health.network || health.disk > 90 || health.memory > 90) {
            return 'warning';
        }
        return 'healthy';
    }
    logError(type, severity, message, details) {
        const error = {
            id: `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
            type,
            severity,
            message,
            details,
            timestamp: new Date(),
            resolved: false,
            autoFixAttempted: false
        };
        this.errors.push(error);
        console.error(`[${severity.toUpperCase()}] ${type}: ${message}`, details);
        // Store in database
        this.supabase
            .from('system_errors')
            .insert(error)
            .catch(console.error);
    }
    async attemptDatabaseFix() {
        try {
            // Restart database connection
            this.supabase = (0, supabase_js_1.createClient)(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
            // Test connection
            const { error } = await this.supabase.from('organizations').select('id').limit(1);
            return !error;
        }
        catch {
            return false;
        }
    }
    async attemptAuthFix() {
        try {
            await execAsync('powershell -Command "Connect-MgGraph -Scopes DeviceManagementManagedDevices.ReadWrite.All"');
            return true;
        }
        catch {
            return false;
        }
    }
    async autoFixErrors() {
        let fixed = 0;
        let failed = 0;
        const unfixedErrors = this.errors.filter(e => !e.resolved && !e.autoFixAttempted);
        for (const error of unfixedErrors) {
            error.autoFixAttempted = true;
            try {
                let success = false;
                switch (error.type) {
                    case 'database':
                        success = await this.attemptDatabaseFix();
                        break;
                    case 'auth':
                        success = await this.attemptAuthFix();
                        break;
                    case 'disk':
                        success = await this.cleanupDiskSpace();
                        break;
                    case 'memory':
                        success = await this.freeMemory();
                        break;
                }
                if (success) {
                    error.resolved = true;
                    fixed++;
                }
                else {
                    failed++;
                }
            }
            catch {
                failed++;
            }
        }
        return { fixed, failed };
    }
    async cleanupDiskSpace() {
        try {
            // Clean temp files
            await execAsync('powershell -Command "Get-ChildItem -Path $env:TEMP -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue"');
            // Clean logs older than 30 days
            await execAsync('forfiles /p "logs" /s /m *.log /d -30 /c "cmd /c del @path" 2>nul');
            return true;
        }
        catch {
            return false;
        }
    }
    async freeMemory() {
        try {
            // Force garbage collection
            if (global.gc) {
                global.gc();
            }
            // Clear Node.js cache
            Object.keys(require.cache).forEach(key => {
                if (key.includes('node_modules')) {
                    delete require.cache[key];
                }
            });
            return true;
        }
        catch {
            return false;
        }
    }
    async getErrorReport() {
        return this.errors.slice(-100); // Last 100 errors
    }
    async clearResolvedErrors() {
        this.errors = this.errors.filter(e => !e.resolved);
    }
}
exports.SystemErrorService = SystemErrorService;
exports.systemErrorService = new SystemErrorService();
