import { Request, Response } from 'express';
import { cicdService } from '../services/cicdService';

export class CICDController {
  async getDeploymentStatus(req: Request, res: Response) {
    try {
      const deployments = await cicdService.getDeploymentStatus();
      res.json({
        success: true,
        data: deployments,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to get deployment status',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async triggerDeployment(req: Request, res: Response) {
    try {
      const { branch = 'main' } = req.body;
      const result = await cicdService.triggerDeployment(branch);
      
      res.json({
        success: result.success,
        data: result,
        message: result.success ? 'Deployment triggered successfully' : 'Failed to trigger deployment'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to trigger deployment',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async rollbackDeployment(req: Request, res: Response) {
    try {
      const { deploymentId } = req.body;
      const result = await cicdService.rollbackDeployment(deploymentId);
      
      res.json({
        success: result.success,
        message: result.message,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to rollback deployment',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async getCICDMetrics(req: Request, res: Response) {
    try {
      const metrics = await cicdService.getCICDMetrics();
      res.json({
        success: true,
        data: metrics,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to get CI/CD metrics',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async validateDeployment(req: Request, res: Response) {
    try {
      const { url = 'https://esim-enterprise-management.vercel.app' } = req.body;
      const validation = await cicdService.validateDeployment(url);
      
      res.json({
        success: validation.healthy,
        data: validation,
        message: validation.healthy ? 'Deployment is healthy' : 'Deployment validation failed'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to validate deployment',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async syncGitHubVercel(req: Request, res: Response) {
    try {
      const sync = await cicdService.syncGitHubVercel();
      res.json({
        success: sync.synced,
        data: sync,
        message: sync.synced ? 'GitHub and Vercel are synchronized' : 'Synchronization issues detected'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to check synchronization',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }
}

export const cicdController = new CICDController();