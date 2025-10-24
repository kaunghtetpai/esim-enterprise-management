import { Request, Response } from 'express';
import { systemErrorService } from '../services/systemErrorService';
import { diagnosticService } from '../services/diagnosticService';

export class SystemController {
  async getSystemHealth(req: Request, res: Response) {
    try {
      const health = await systemErrorService.checkSystemHealth();
      res.json({
        success: true,
        data: health,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to check system health',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async runDiagnostics(req: Request, res: Response) {
    try {
      const diagnostics = await diagnosticService.runFullDiagnostic();
      res.json({
        success: true,
        data: diagnostics,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to run diagnostics',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async autoFixErrors(req: Request, res: Response) {
    try {
      const result = await systemErrorService.autoFixErrors();
      res.json({
        success: true,
        data: result,
        message: `Fixed ${result.fixed} errors, ${result.failed} failed to fix`
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to auto-fix errors',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async getErrorReport(req: Request, res: Response) {
    try {
      const errors = await systemErrorService.getErrorReport();
      res.json({
        success: true,
        data: errors,
        count: errors.length
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to get error report',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async clearErrors(req: Request, res: Response) {
    try {
      await systemErrorService.clearResolvedErrors();
      res.json({
        success: true,
        message: 'Resolved errors cleared'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to clear errors',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async getSystemStatus(req: Request, res: Response) {
    try {
      const [health, diagnostics] = await Promise.all([
        systemErrorService.checkSystemHealth(),
        diagnosticService.runQuickCheck()
      ]);

      const status = {
        health,
        diagnostics,
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        version: process.version,
        platform: process.platform
      };

      res.json({
        success: true,
        data: status,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to get system status',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }
}

export const systemController = new SystemController();