import { query } from '../config/database';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

interface DiagnosticResult {
  component: string;
  status: 'healthy' | 'warning' | 'error';
  message: string;
  details?: any;
  timestamp: string;
}

export class DiagnosticService {
  async runFullDiagnostic(): Promise<DiagnosticResult[]> {
    const results: DiagnosticResult[] = [];
    
    const checks = [
      this.checkDatabase(),
      this.checkGraphConnection(),
      this.checkSystemResources(),
      this.checkNetworkConnectivity(),
      this.checkPowerShellModules(),
      this.checkErrorRates(),
      this.checkDiskSpace(),
      this.checkServices()
    ];

    const diagnosticResults = await Promise.allSettled(checks);
    
    diagnosticResults.forEach((result, index) => {
      if (result.status === 'fulfilled') {
        results.push(result.value);
      } else {
        results.push({
          component: `check_${index}`,
          status: 'error',
          message: `Diagnostic check failed: ${result.reason}`,
          timestamp: new Date().toISOString()
        });
      }
    });

    return results;
  }

  private async checkDatabase(): Promise<DiagnosticResult> {
    try {
      const start = Date.now();
      await query('SELECT 1');
      const responseTime = Date.now() - start;

      const status = responseTime > 1000 ? 'warning' : 'healthy';
      
      return {
        component: 'database',
        status,
        message: `Database connection ${status}`,
        details: { responseTime: `${responseTime}ms` },
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        component: 'database',
        status: 'error',
        message: `Database connection failed: ${error.message}`,
        timestamp: new Date().toISOString()
      };
    }
  }

  private async checkGraphConnection(): Promise<DiagnosticResult> {
    try {
      const { stdout } = await execAsync('powershell.exe -Command "Get-MgContext | Select-Object TenantId"', { timeout: 5000 });
      
      if (stdout.includes('TenantId')) {
        return {
          component: 'graph_connection',
          status: 'healthy',
          message: 'Microsoft Graph connection active',
          timestamp: new Date().toISOString()
        };
      } else {
        return {
          component: 'graph_connection',
          status: 'warning',
          message: 'Microsoft Graph not connected',
          timestamp: new Date().toISOString()
        };
      }
    } catch (error) {
      return {
        component: 'graph_connection',
        status: 'error',
        message: `Graph connection check failed: ${error.message}`,
        timestamp: new Date().toISOString()
      };
    }
  }

  private async checkSystemResources(): Promise<DiagnosticResult> {
    const memUsage = process.memoryUsage();
    const cpuUsage = process.cpuUsage();
    const uptime = process.uptime();

    const memoryMB = Math.round(memUsage.heapUsed / 1024 / 1024);
    const status = memoryMB > 512 ? 'warning' : 'healthy';

    return {
      component: 'system_resources',
      status,
      message: `System resources ${status}`,
      details: {
        memory: `${memoryMB}MB`,
        uptime: `${Math.round(uptime / 3600)}h`,
        cpu: cpuUsage
      },
      timestamp: new Date().toISOString()
    };
  }

  private async checkNetworkConnectivity(): Promise<DiagnosticResult> {
    try {
      const endpoints = [
        'https://graph.microsoft.com',
        'https://login.microsoftonline.com',
        'https://entra.microsoft.com'
      ];

      const checks = endpoints.map(async (url) => {
        const response = await fetch(url, { method: 'HEAD', signal: AbortSignal.timeout(5000) });
        return { url, status: response.status };
      });

      const results = await Promise.allSettled(checks);
      const failures = results.filter(r => r.status === 'rejected').length;

      const status = failures > 0 ? (failures === endpoints.length ? 'error' : 'warning') : 'healthy';

      return {
        component: 'network_connectivity',
        status,
        message: `Network connectivity ${status}`,
        details: { endpoints: endpoints.length, failures },
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        component: 'network_connectivity',
        status: 'error',
        message: `Network check failed: ${error.message}`,
        timestamp: new Date().toISOString()
      };
    }
  }

  private async checkPowerShellModules(): Promise<DiagnosticResult> {
    try {
      const { stdout } = await execAsync('powershell.exe -Command "Get-Module Microsoft.Graph* -ListAvailable | Measure-Object | Select-Object Count"', { timeout: 10000 });
      
      const moduleCount = parseInt(stdout.match(/\d+/)?.[0] || '0');
      const status = moduleCount > 0 ? 'healthy' : 'warning';

      return {
        component: 'powershell_modules',
        status,
        message: `PowerShell modules ${status}`,
        details: { moduleCount },
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        component: 'powershell_modules',
        status: 'error',
        message: `PowerShell module check failed: ${error.message}`,
        timestamp: new Date().toISOString()
      };
    }
  }

  private async checkErrorRates(): Promise<DiagnosticResult> {
    try {
      const result = await query(`
        SELECT 
          COUNT(*) as total_errors,
          COUNT(CASE WHEN timestamp >= NOW() - INTERVAL '1 hour' THEN 1 END) as recent_errors
        FROM system_error_logs
        WHERE timestamp >= NOW() - INTERVAL '24 hours'
      `);

      const { total_errors, recent_errors } = result.rows[0];
      const status = recent_errors > 10 ? 'warning' : (recent_errors > 50 ? 'error' : 'healthy');

      return {
        component: 'error_rates',
        status,
        message: `Error rates ${status}`,
        details: { total_errors, recent_errors },
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        component: 'error_rates',
        status: 'error',
        message: `Error rate check failed: ${error.message}`,
        timestamp: new Date().toISOString()
      };
    }
  }

  private async checkDiskSpace(): Promise<DiagnosticResult> {
    try {
      const { stdout } = await execAsync('powershell.exe -Command "Get-PSDrive C | Select-Object Used,Free"', { timeout: 5000 });
      
      const freeMatch = stdout.match(/Free\s+:\s+(\d+)/);
      const freeBytes = freeMatch ? parseInt(freeMatch[1]) : 0;
      const freeGB = Math.round(freeBytes / 1024 / 1024 / 1024);

      const status = freeGB < 1 ? 'error' : (freeGB < 5 ? 'warning' : 'healthy');

      return {
        component: 'disk_space',
        status,
        message: `Disk space ${status}`,
        details: { freeGB },
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        component: 'disk_space',
        status: 'warning',
        message: `Disk space check failed: ${error.message}`,
        timestamp: new Date().toISOString()
      };
    }
  }

  private async checkServices(): Promise<DiagnosticResult> {
    try {
      const services = ['Winmgmt', 'BITS', 'Themes'];
      const { stdout } = await execAsync(`powershell.exe -Command "Get-Service ${services.join(',')} | Select-Object Name,Status"`, { timeout: 10000 });
      
      const runningServices = (stdout.match(/Running/g) || []).length;
      const status = runningServices === services.length ? 'healthy' : 'warning';

      return {
        component: 'windows_services',
        status,
        message: `Windows services ${status}`,
        details: { running: runningServices, total: services.length },
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        component: 'windows_services',
        status: 'error',
        message: `Service check failed: ${error.message}`,
        timestamp: new Date().toISOString()
      };
    }
  }

  async solveProblem(component: string, issue: string): Promise<{ success: boolean; message: string; actions: string[] }> {
    const solutions = {
      database: this.solveDatabaseIssues,
      graph_connection: this.solveGraphIssues,
      system_resources: this.solveResourceIssues,
      network_connectivity: this.solveNetworkIssues,
      powershell_modules: this.solvePowerShellIssues,
      error_rates: this.solveErrorRateIssues,
      disk_space: this.solveDiskSpaceIssues,
      windows_services: this.solveServiceIssues
    };

    const solver = solutions[component];
    if (!solver) {
      return {
        success: false,
        message: 'No solution available for this component',
        actions: []
      };
    }

    return await solver.call(this, issue);
  }

  private async solveDatabaseIssues(issue: string) {
    const actions = [
      'Check database connection string',
      'Verify database server is running',
      'Test network connectivity to database',
      'Check database user permissions'
    ];

    try {
      await query('SELECT 1');
      return {
        success: true,
        message: 'Database connection restored',
        actions
      };
    } catch (error) {
      return {
        success: false,
        message: `Database issue persists: ${error.message}`,
        actions
      };
    }
  }

  private async solveGraphIssues(issue: string) {
    const actions = [
      'Reconnect to Microsoft Graph',
      'Check Azure AD app permissions',
      'Verify client credentials',
      'Test network connectivity to Microsoft services'
    ];

    try {
      await execAsync('powershell.exe -Command "Connect-MgGraph -Scopes User.Read"', { timeout: 30000 });
      return {
        success: true,
        message: 'Graph connection restored',
        actions
      };
    } catch (error) {
      return {
        success: false,
        message: `Graph connection issue persists: ${error.message}`,
        actions
      };
    }
  }

  private async solveResourceIssues(issue: string) {
    const actions = [
      'Restart Node.js process',
      'Clear application cache',
      'Check for memory leaks',
      'Monitor resource usage'
    ];

    if (global.gc) {
      global.gc();
    }

    return {
      success: true,
      message: 'Garbage collection triggered',
      actions
    };
  }

  private async solveNetworkIssues(issue: string) {
    const actions = [
      'Check internet connectivity',
      'Verify firewall settings',
      'Test DNS resolution',
      'Check proxy configuration'
    ];

    return {
      success: false,
      message: 'Manual network troubleshooting required',
      actions
    };
  }

  private async solvePowerShellIssues(issue: string) {
    const actions = [
      'Install Microsoft Graph PowerShell modules',
      'Update PowerShell execution policy',
      'Check PowerShell version',
      'Verify module installation'
    ];

    try {
      await execAsync('powershell.exe -Command "Install-Module Microsoft.Graph -Force -Scope CurrentUser"', { timeout: 60000 });
      return {
        success: true,
        message: 'PowerShell modules installation initiated',
        actions
      };
    } catch (error) {
      return {
        success: false,
        message: `PowerShell module installation failed: ${error.message}`,
        actions
      };
    }
  }

  private async solveErrorRateIssues(issue: string) {
    const actions = [
      'Review recent error logs',
      'Identify error patterns',
      'Apply error-specific fixes',
      'Monitor error trends'
    ];

    try {
      await query('DELETE FROM system_error_logs WHERE timestamp < NOW() - INTERVAL \'7 days\'');
      return {
        success: true,
        message: 'Old error logs cleaned up',
        actions
      };
    } catch (error) {
      return {
        success: false,
        message: 'Error log cleanup failed',
        actions
      };
    }
  }

  private async solveDiskSpaceIssues(issue: string) {
    const actions = [
      'Clean temporary files',
      'Clear application logs',
      'Remove old backup files',
      'Check disk usage by directory'
    ];

    try {
      await execAsync('powershell.exe -Command "Get-ChildItem $env:TEMP -Recurse | Remove-Item -Force -Recurse"', { timeout: 30000 });
      return {
        success: true,
        message: 'Temporary files cleaned',
        actions
      };
    } catch (error) {
      return {
        success: false,
        message: 'Disk cleanup failed',
        actions
      };
    }
  }

  private async solveServiceIssues(issue: string) {
    const actions = [
      'Restart required Windows services',
      'Check service dependencies',
      'Verify service permissions',
      'Review Windows event logs'
    ];

    try {
      await execAsync('powershell.exe -Command "Restart-Service Winmgmt -Force"', { timeout: 15000 });
      return {
        success: true,
        message: 'Windows services restarted',
        actions
      };
    } catch (error) {
      return {
        success: false,
        message: 'Service restart failed',
        actions
      };
    }
  }
}