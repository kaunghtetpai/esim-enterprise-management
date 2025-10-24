"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ESIMController = void 0;
class ESIMController {
    constructor(esimService, intuneService, auditService) {
        this.esimService = esimService;
        this.intuneService = intuneService;
        this.auditService = auditService;
    }
    // Profile Management
    async getProfiles(req, res) {
        try {
            const { organizationId } = req.user;
            const { page = 1, limit = 20, status, carrier, department } = req.query;
            const filters = {
                status: status,
                carrier: carrier,
                departmentId: department
            };
            const profiles = await this.esimService.getProfiles(organizationId, parseInt(page), parseInt(limit), filters);
            res.json(profiles);
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
    async createProfile(req, res) {
        try {
            const { organizationId, userId } = req.user;
            const profileData = req.body;
            const profile = await this.esimService.createProfile(organizationId, profileData);
            await this.auditService.log({
                organizationId,
                userId,
                action: 'CREATE_PROFILE',
                resourceType: 'profile',
                resourceId: profile.id,
                newValues: profileData,
                ipAddress: req.ip,
                userAgent: req.get('User-Agent')
            });
            res.status(201).json(profile);
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
    async updateProfile(req, res) {
        try {
            const { organizationId, userId } = req.user;
            const { profileId } = req.params;
            const updates = req.body;
            const oldProfile = await this.esimService.getProfile(profileId);
            const updatedProfile = await this.esimService.updateProfile(profileId, updates);
            await this.auditService.log({
                organizationId,
                userId,
                action: 'UPDATE_PROFILE',
                resourceType: 'profile',
                resourceId: profileId,
                oldValues: oldProfile,
                newValues: updates,
                ipAddress: req.ip,
                userAgent: req.get('User-Agent')
            });
            res.json(updatedProfile);
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
    async deleteProfile(req, res) {
        try {
            const { organizationId, userId } = req.user;
            const { profileId } = req.params;
            const profile = await this.esimService.getProfile(profileId);
            await this.esimService.deleteProfile(profileId);
            await this.auditService.log({
                organizationId,
                userId,
                action: 'DELETE_PROFILE',
                resourceType: 'profile',
                resourceId: profileId,
                oldValues: profile,
                ipAddress: req.ip,
                userAgent: req.get('User-Agent')
            });
            res.status(204).send();
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
    // Device Assignment
    async assignProfileToDevice(req, res) {
        try {
            const { organizationId, userId } = req.user;
            const { deviceId, profileId } = req.params;
            const { assignmentType = 'manual', notes } = req.body;
            // Create assignment record
            const assignment = await this.esimService.assignProfileToDevice({
                deviceId,
                profileId,
                assignedBy: userId,
                assignmentType,
                notes
            });
            // Get profile and device details
            const profile = await this.esimService.getProfile(profileId);
            const device = await this.intuneService.getDevice(deviceId);
            // Send eSIM profile to device via Intune
            const commandId = await this.intuneService.assignESIMProfile(deviceId, {
                iccid: profile.iccid,
                activationCode: profile.activationCode,
                carrierName: profile.carrier,
                planName: profile.planName
            });
            // Create activation task
            await this.esimService.createActivationTask({
                assignmentId: assignment.id,
                taskType: 'activation',
                initiatedBy: userId,
                intuneCommandId: commandId,
                organizationId
            });
            await this.auditService.log({
                organizationId,
                userId,
                action: 'ASSIGN_PROFILE',
                resourceType: 'assignment',
                resourceId: assignment.id,
                newValues: { deviceId, profileId, assignmentType },
                ipAddress: req.ip,
                userAgent: req.get('User-Agent')
            });
            res.status(201).json({ assignment, commandId });
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
    async removeProfileFromDevice(req, res) {
        try {
            const { organizationId, userId } = req.user;
            const { assignmentId } = req.params;
            const assignment = await this.esimService.getAssignment(assignmentId);
            const profile = await this.esimService.getProfile(assignment.profileId);
            // Remove eSIM profile from device via Intune
            const commandId = await this.intuneService.removeESIMProfile(assignment.deviceId, profile.iccid);
            // Update assignment status
            await this.esimService.updateAssignment(assignmentId, {
                status: 'removed',
                removedAt: new Date()
            });
            await this.auditService.log({
                organizationId,
                userId,
                action: 'REMOVE_PROFILE',
                resourceType: 'assignment',
                resourceId: assignmentId,
                oldValues: assignment,
                ipAddress: req.ip,
                userAgent: req.get('User-Agent')
            });
            res.json({ commandId });
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
    // Migration
    async migrateProfile(req, res) {
        try {
            const { organizationId, userId } = req.user;
            const { deviceId } = req.params;
            const { fromProfileId, toProfileId, migrationType, reason } = req.body;
            // Create migration record
            const migration = await this.esimService.createMigration({
                deviceId,
                fromProfileId,
                toProfileId,
                migrationType,
                initiatedBy: userId,
                migrationReason: reason
            });
            // If migrating from existing eSIM, remove it first
            if (fromProfileId) {
                const fromProfile = await this.esimService.getProfile(fromProfileId);
                await this.intuneService.removeESIMProfile(deviceId, fromProfile.iccid);
            }
            // Assign new eSIM profile
            const toProfile = await this.esimService.getProfile(toProfileId);
            const commandId = await this.intuneService.assignESIMProfile(deviceId, {
                iccid: toProfile.iccid,
                activationCode: toProfile.activationCode,
                carrierName: toProfile.carrier,
                planName: toProfile.planName
            });
            await this.auditService.log({
                organizationId,
                userId,
                action: 'MIGRATE_PROFILE',
                resourceType: 'migration',
                resourceId: migration.id,
                newValues: { deviceId, fromProfileId, toProfileId, migrationType },
                ipAddress: req.ip,
                userAgent: req.get('User-Agent')
            });
            res.status(201).json({ migration, commandId });
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
    // Bulk Operations
    async bulkActivation(req, res) {
        try {
            const { organizationId, userId } = req.user;
            const { assignments } = req.body; // Array of {deviceId, profileId}
            const results = [];
            for (const assignment of assignments) {
                try {
                    const profile = await this.esimService.getProfile(assignment.profileId);
                    const commandId = await this.intuneService.assignESIMProfile(assignment.deviceId, {
                        iccid: profile.iccid,
                        activationCode: profile.activationCode,
                        carrierName: profile.carrier,
                        planName: profile.planName
                    });
                    const assignmentRecord = await this.esimService.assignProfileToDevice({
                        deviceId: assignment.deviceId,
                        profileId: assignment.profileId,
                        assignedBy: userId,
                        assignmentType: 'bulk'
                    });
                    results.push({
                        deviceId: assignment.deviceId,
                        profileId: assignment.profileId,
                        status: 'success',
                        commandId,
                        assignmentId: assignmentRecord.id
                    });
                }
                catch (error) {
                    results.push({
                        deviceId: assignment.deviceId,
                        profileId: assignment.profileId,
                        status: 'failed',
                        error: error.message
                    });
                }
            }
            await this.auditService.log({
                organizationId,
                userId,
                action: 'BULK_ACTIVATION',
                resourceType: 'bulk_operation',
                newValues: { assignments, results },
                ipAddress: req.ip,
                userAgent: req.get('User-Agent')
            });
            res.json({ results });
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
    // Status and Monitoring
    async getActivationStatus(req, res) {
        try {
            const { taskId } = req.params;
            const task = await this.esimService.getActivationTask(taskId);
            // Check Intune command status if available
            if (task.intuneCommandId) {
                const device = await this.esimService.getDeviceByAssignment(task.assignmentId);
                const actions = await this.intuneService.getDeviceActions(device.intuneDeviceId);
                const command = actions.find(a => a.id === task.intuneCommandId);
                if (command) {
                    task.intuneStatus = command.status;
                }
            }
            res.json(task);
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
    async getDashboardStats(req, res) {
        try {
            const { organizationId } = req.user;
            const stats = await this.esimService.getDashboardStats(organizationId);
            res.json(stats);
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
}
exports.ESIMController = ESIMController;
//# sourceMappingURL=esim-controller.js.map