import { Request, Response } from 'express';
import { DeploymentErrorService } from '../services/deploymentErrorService';

const deploymentService = new DeploymentErrorService();

export const deploymentController = {
  async checkAllDeployments(req: Request, res: Response) {
    try {
      const deploymentStatus = await deploymentService.checkAllDeployments();
      
      res.json({
        success: true,
        data: deploymentStatus,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to check deployments',
        error: error.message
      });
    }
  },

  async getActiveErrors(req: Request, res: Response) {
    try {
      const errors = await deploymentService.getActiveErrors();
      
      res.json({
        success: true,
        data: errors,
        count: errors.length
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to get active errors',
        error: error.message
      });
    }
  },

  async resolveError(req: Request, res: Response) {
    try {
      const { errorId } = req.params;
      await deploymentService.resolveError(errorId);
      
      res.json({
        success: true,
        message: 'Error resolved successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to resolve error',
        error: error.message
      });
    }
  },

  async syncAllPlatforms(req: Request, res: Response) {
    try {
      const result = await deploymentService.syncAllPlatforms();
      
      res.json({
        success: result.success,
        message: result.message,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to sync platforms',
        error: error.message
      });
    }
  },

  async logError(req: Request, res: Response) {
    try {
      const { platform, errorType, message } = req.body;
      await deploymentService.logError(platform, errorType, message);
      
      res.json({
        success: true,
        message: 'Error logged successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to log error',
        error: error.message
      });
    }
  }
};