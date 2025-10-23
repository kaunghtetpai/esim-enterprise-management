import { Request, Response } from 'express';
import { vercelGitHubSyncService } from '../services/vercelGitHubSyncService';
import { completeSystemService } from '../services/completeSystemService';

export class SyncController {
  async checkSyncStatus(req: Request, res: Response) {
    try {
      const status = await vercelGitHubSyncService.checkSyncStatus();
      res.json({
        success: true,
        data: status,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to check sync status',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async updateAllData(req: Request, res: Response) {
    try {
      const result = await vercelGitHubSyncService.updateAllData();
      res.json({
        success: result.errors.length === 0,
        data: result,
        message: `Updated ${result.updated.length} services, ${result.errors.length} errors`,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to update data',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async validateAPIs(req: Request, res: Response) {
    try {
      const validation = await vercelGitHubSyncService.validateAPIs();
      res.json({
        success: validation.invalid.length === 0,
        data: validation,
        message: `${validation.valid.length} APIs valid, ${validation.invalid.length} invalid`,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to validate APIs',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async fixSyncIssues(req: Request, res: Response) {
    try {
      const result = await vercelGitHubSyncService.fixSyncIssues();
      res.json({
        success: result.failed.length === 0,
        data: result,
        message: `Fixed ${result.fixed.length} issues, ${result.failed.length} failed`,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to fix sync issues',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async checkAllSystems(req: Request, res: Response) {
    try {
      const status = await completeSystemService.checkAllSystems();
      res.json({
        success: status.errors.length === 0,
        data: status,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'System check failed',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async updateAllSystems(req: Request, res: Response) {
    try {
      const result = await completeSystemService.updateAllData();
      res.json({
        success: result.errors.length === 0,
        data: result,
        message: `Updated ${result.updated.length} systems, ${result.errors.length} errors`,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'System update failed',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async createBackup(req: Request, res: Response) {
    try {
      const result = await completeSystemService.createSystemBackup();
      res.json({
        success: result.success,
        data: result,
        message: result.success ? 'Backup created successfully' : 'Backup creation failed',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Backup creation failed',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async deleteOldData(req: Request, res: Response) {
    try {
      const { days = 30 } = req.body;
      const result = await completeSystemService.deleteOldData(days);
      res.json({
        success: true,
        data: result,
        message: `Deleted ${result.deleted} old records`,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Data deletion failed',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async clearErrors(req: Request, res: Response) {
    try {
      const result = await completeSystemService.clearAllErrors();
      res.json({
        success: true,
        data: result,
        message: `Cleared ${result.cleared} resolved errors`,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Error clearing failed',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }
}

export const syncController = new SyncController();