import { Request, Response } from 'express';
import { enterpriseSetupService } from '../services/enterpriseSetupService';

export class EnterpriseController {
  async runCompleteSetup(req: Request, res: Response) {
    try {
      const result = await enterpriseSetupService.runCompleteSetup();
      res.json({
        success: result.success,
        data: result,
        message: result.success ? 'Enterprise setup completed successfully' : 'Enterprise setup completed with errors',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to run enterprise setup',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async validateSetup(req: Request, res: Response) {
    try {
      const result = await enterpriseSetupService.validateCurrentSetup();
      res.json({
        success: true,
        data: result,
        message: result.valid ? 'Setup validation passed' : 'Setup validation found issues',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to validate setup',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async getSetupStatus(req: Request, res: Response) {
    try {
      const phases = await enterpriseSetupService.getSetupStatus();
      res.json({
        success: true,
        data: phases,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to get setup status',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async runPhase(req: Request, res: Response) {
    try {
      const { phaseNumber } = req.params;
      const phase = parseInt(phaseNumber);
      
      if (isNaN(phase) || phase < 1 || phase > 7) {
        return res.status(400).json({
          success: false,
          error: 'Invalid phase number. Must be between 1 and 7.'
        });
      }

      const result = await enterpriseSetupService.runPhase(phase);
      res.json({
        success: result.status === 'completed',
        data: result,
        message: `Phase ${phase} ${result.status}`,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to run phase',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async createCarrierGroups(req: Request, res: Response) {
    try {
      const result = await enterpriseSetupService.createCarrierGroups();
      res.json({
        success: result.errors.length === 0,
        data: result,
        message: `Created ${result.created.length} groups, ${result.existing.length} already existed`,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to create carrier groups',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async createCompliancePolicies(req: Request, res: Response) {
    try {
      const result = await enterpriseSetupService.createCompliancePolicies();
      res.json({
        success: result.errors.length === 0,
        data: result,
        message: `Created ${result.created.length} policies, ${result.existing.length} already existed`,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to create compliance policies',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }

  async configureCompanyPortal(req: Request, res: Response) {
    try {
      const result = await enterpriseSetupService.configureCompanyPortal();
      res.json({
        success: result.success,
        data: result,
        message: result.message,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: 'Failed to configure Company Portal',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }
}

export const enterpriseController = new EnterpriseController();