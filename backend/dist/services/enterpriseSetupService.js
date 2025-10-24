"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.enterpriseSetupService = exports.EnterpriseSetupService = void 0;
const child_process_1 = require("child_process");
const util_1 = require("util");
const supabase_js_1 = require("@supabase/supabase-js");
const execAsync = (0, util_1.promisify)(child_process_1.exec);
class EnterpriseSetupService {
    constructor() {
        this.supabase = (0, supabase_js_1.createClient)(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
        this.config = {
            tenantId: 'mdm.esim.com.mm',
            adminAccount: 'admin@mdm.esim.com.mm',
            carriers: [
                { name: 'MPT', mcc: '414', mnc: '01', displayName: 'Myanmar Posts and Telecommunications' },
                { name: 'ATOM', mcc: '414', mnc: '06', displayName: 'Atom Myanmar' },
                { name: 'MYTEL', mcc: '414', mnc: '09', displayName: 'MyTel Myanmar' }
            ]
        };
        this.phases = [
            { phase: 'Phase1_EntraID', status: 'pending', errors: [], fixed: [] },
            { phase: 'Phase2_Intune', status: 'pending', errors: [], fixed: [] },
            { phase: 'Phase3_eSIM', status: 'pending', errors: [], fixed: [] },
            { phase: 'Phase4_Policies', status: 'pending', errors: [], fixed: [] },
            { phase: 'Phase5_Verification', status: 'pending', errors: [], fixed: [] },
            { phase: 'Phase6_CompanyPortal', status: 'pending', errors: [], fixed: [] },
            { phase: 'Phase7_FinalValidation', status: 'pending', errors: [], fixed: [] }
        ];
    }
    async runCompleteSetup() {
        try {
            // Execute PowerShell setup script
            const scriptPath = 'scripts\\Complete-eSIM-Enterprise-Setup.ps1';
            const command = `powershell -ExecutionPolicy Bypass -File "${scriptPath}" -FullSetup -TenantId "${this.config.tenantId}" -AdminAccount "${this.config.adminAccount}"`;
            const { stdout, stderr } = await execAsync(command);
            // Parse results from PowerShell output
            const results = this.parseSetupResults(stdout);
            // Store results in database
            await this.storeSetupResults(results);
            return {
                success: results.success,
                phases: this.phases,
                summary: results.summary
            };
        }
        catch (error) {
            console.error('Enterprise setup failed:', error);
            return {
                success: false,
                phases: this.phases,
                summary: { error: error instanceof Error ? error.message : 'Unknown error' }
            };
        }
    }
    async validateCurrentSetup() {
        try {
            const scriptPath = 'scripts\\Complete-eSIM-Enterprise-Setup.ps1';
            const command = `powershell -ExecutionPolicy Bypass -File "${scriptPath}" -ValidateOnly`;
            const { stdout } = await execAsync(command);
            return this.parseValidationResults(stdout);
        }
        catch (error) {
            return {
                valid: false,
                issues: [error instanceof Error ? error.message : 'Validation failed'],
                recommendations: ['Run complete setup to resolve issues']
            };
        }
    }
    async getSetupStatus() {
        return this.phases;
    }
    async runPhase(phaseNumber) {
        if (phaseNumber < 1 || phaseNumber > 7) {
            throw new Error('Invalid phase number. Must be between 1 and 7.');
        }
        const phase = this.phases[phaseNumber - 1];
        phase.status = 'running';
        phase.startTime = new Date();
        try {
            const scriptPath = 'scripts\\Complete-eSIM-Enterprise-Setup.ps1';
            const command = `powershell -ExecutionPolicy Bypass -File "${scriptPath}" -Phase${phaseNumber}`;
            const { stdout, stderr } = await execAsync(command);
            if (stderr) {
                phase.errors.push(stderr);
                phase.status = 'failed';
            }
            else {
                phase.status = 'completed';
            }
            phase.endTime = new Date();
            return phase;
        }
        catch (error) {
            phase.errors.push(error instanceof Error ? error.message : 'Unknown error');
            phase.status = 'failed';
            phase.endTime = new Date();
            return phase;
        }
    }
    async createCarrierGroups() {
        const results = { created: [], existing: [], errors: [] };
        try {
            for (const carrier of this.config.carriers) {
                const groupName = `Group_${carrier.name}_eSIM`;
                try {
                    // Check if group exists via PowerShell
                    const checkCommand = `powershell -Command "Get-MgGroup -Filter \\"displayName eq '${groupName}'\\" | ConvertTo-Json"`;
                    const { stdout } = await execAsync(checkCommand);
                    if (stdout.trim() && stdout !== 'null') {
                        results.existing.push(groupName);
                    }
                    else {
                        // Create group
                        const createCommand = `powershell -Command "New-MgGroup -DisplayName '${groupName}' -Description 'eSIM devices for ${carrier.displayName}' -MailEnabled:$false -SecurityEnabled:$true"`;
                        await execAsync(createCommand);
                        results.created.push(groupName);
                    }
                }
                catch (error) {
                    results.errors.push(`Failed to process group ${groupName}: ${error instanceof Error ? error.message : 'Unknown error'}`);
                }
            }
            return results;
        }
        catch (error) {
            results.errors.push(`Carrier group creation failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
            return results;
        }
    }
    async createCompliancePolicies() {
        const results = { created: [], existing: [], errors: [] };
        try {
            const policyName = 'eSIM Enterprise Compliance Policy';
            // Check if policy exists
            const checkCommand = `powershell -Command "Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies' -Method GET | ConvertTo-Json"`;
            const { stdout } = await execAsync(checkCommand);
            const policies = JSON.parse(stdout);
            const existingPolicy = policies.value?.find((p) => p.displayName === policyName);
            if (existingPolicy) {
                results.existing.push(policyName);
            }
            else {
                // Create compliance policy via PowerShell
                const createScript = `
          $policy = @{
            '@odata.type' = '#microsoft.graph.windows10CompliancePolicy'
            displayName = '${policyName}'
            description = 'Compliance policy for eSIM enterprise devices'
            passwordRequired = $true
            passwordMinimumLength = 6
            requireHealthyDeviceReport = $true
            osMinimumVersion = '10.0.19041'
          }
          Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies' -Method POST -Body ($policy | ConvertTo-Json -Depth 10)
        `;
                await execAsync(`powershell -Command "${createScript}"`);
                results.created.push(policyName);
            }
            return results;
        }
        catch (error) {
            results.errors.push(`Compliance policy creation failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
            return results;
        }
    }
    async configureCompanyPortal() {
        try {
            const brandingScript = `
        $branding = @{
          displayName = 'eSIM Enterprise Management'
          contactITName = 'IT Support'
          contactITEmailAddress = 'support@mdm.esim.com.mm'
          contactITPhoneNumber = '+95-1-234-5678'
          showDisplayNameNextToLogo = $true
        }
        Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/intuneBrand' -Method PATCH -Body ($branding | ConvertTo-Json -Depth 10)
      `;
            await execAsync(`powershell -Command "${brandingScript}"`);
            return {
                success: true,
                message: 'Company Portal branding configured successfully'
            };
        }
        catch (error) {
            return {
                success: false,
                message: `Company Portal configuration failed: ${error instanceof Error ? error.message : 'Unknown error'}`
            };
        }
    }
    parseSetupResults(output) {
        // Parse PowerShell output to extract setup results
        const lines = output.split('\n');
        let success = true;
        const summary = {
            completedPhases: 0,
            totalPhases: 7,
            errors: [],
            warnings: []
        };
        for (const line of lines) {
            if (line.includes('✓')) {
                // Success line
                const phase = this.extractPhaseFromLine(line);
                if (phase) {
                    phase.status = 'completed';
                    summary.completedPhases++;
                }
            }
            else if (line.includes('✗')) {
                // Error line
                success = false;
                summary.errors.push(line.trim());
                const phase = this.extractPhaseFromLine(line);
                if (phase) {
                    phase.status = 'failed';
                    phase.errors.push(line.trim());
                }
            }
            else if (line.includes('⚠')) {
                // Warning line
                summary.warnings.push(line.trim());
            }
        }
        return { success, summary };
    }
    parseValidationResults(output) {
        const lines = output.split('\n');
        const issues = [];
        const recommendations = [];
        let valid = true;
        for (const line of lines) {
            if (line.includes('✗')) {
                valid = false;
                issues.push(line.trim());
            }
            else if (line.includes('⚠')) {
                issues.push(line.trim());
            }
        }
        if (!valid) {
            recommendations.push('Run complete setup to resolve critical issues');
            recommendations.push('Check Microsoft Graph permissions');
            recommendations.push('Verify Intune licensing');
        }
        return { valid, issues, recommendations };
    }
    extractPhaseFromLine(line) {
        for (const phase of this.phases) {
            if (line.toLowerCase().includes(phase.phase.toLowerCase())) {
                return phase;
            }
        }
        return null;
    }
    async storeSetupResults(results) {
        try {
            await this.supabase
                .from('enterprise_setup_logs')
                .insert({
                tenant_id: this.config.tenantId,
                admin_account: this.config.adminAccount,
                setup_results: results,
                phases: this.phases,
                created_at: new Date().toISOString()
            });
        }
        catch (error) {
            console.error('Failed to store setup results:', error);
        }
    }
}
exports.EnterpriseSetupService = EnterpriseSetupService;
exports.enterpriseSetupService = new EnterpriseSetupService();
//# sourceMappingURL=enterpriseSetupService.js.map