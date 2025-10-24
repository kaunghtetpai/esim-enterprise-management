const profileService = require('../services/profileService');
const carrierService = require('../services/carrierService');
const logger = require('../utils/logger');

class ProfileController {
  async createProfile(req, res) {
    try {
      const { carrier, subscriptionPlan, profileData } = req.body;
      
      const profile = await profileService.createProfile({
        carrier,
        subscriptionPlan,
        profileData,
        createdBy: req.user.id
      });

      res.status(201).json({
        success: true,
        data: profile,
        message: 'Profile created successfully'
      });
    } catch (error) {
      logger.error('Create profile error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getProfiles(req, res) {
    try {
      const { page = 1, limit = 10, carrier, status } = req.query;
      
      const profiles = await profileService.getProfiles({
        page: parseInt(page),
        limit: parseInt(limit),
        carrier,
        status
      });

      res.json({
        success: true,
        data: profiles
      });
    } catch (error) {
      logger.error('Get profiles error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getProfileById(req, res) {
    try {
      const { id } = req.params;
      const profile = await profileService.getProfileById(id);

      if (!profile) {
        return res.status(404).json({
          success: false,
          error: 'Profile not found'
        });
      }

      res.json({
        success: true,
        data: profile
      });
    } catch (error) {
      logger.error('Get profile by ID error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async updateProfile(req, res) {
    try {
      const { id } = req.params;
      const updateData = req.body;

      const profile = await profileService.updateProfile(id, {
        ...updateData,
        updatedBy: req.user.id
      });

      res.json({
        success: true,
        data: profile,
        message: 'Profile updated successfully'
      });
    } catch (error) {
      logger.error('Update profile error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async deleteProfile(req, res) {
    try {
      const { id } = req.params;
      
      await profileService.deleteProfile(id, req.user.id);

      res.json({
        success: true,
        message: 'Profile deleted successfully'
      });
    } catch (error) {
      logger.error('Delete profile error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async batchOperations(req, res) {
    try {
      const { operation, profileIds, data } = req.body;
      
      const result = await profileService.batchOperations({
        operation,
        profileIds,
        data,
        userId: req.user.id
      });

      res.json({
        success: true,
        data: result,
        message: `Batch ${operation} completed`
      });
    } catch (error) {
      logger.error('Batch operations error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async uploadProfileSecret(req, res) {
    try {
      const { profileId, secret } = req.body;
      
      await profileService.uploadProfileSecret(profileId, secret, req.user.id);

      res.json({
        success: true,
        message: 'Profile secret uploaded successfully'
      });
    } catch (error) {
      logger.error('Upload profile secret error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getProfileLogs(req, res) {
    try {
      const { id } = req.params;
      const { page = 1, limit = 20 } = req.query;
      
      const logs = await profileService.getProfileLogs(id, {
        page: parseInt(page),
        limit: parseInt(limit)
      });

      res.json({
        success: true,
        data: logs
      });
    } catch (error) {
      logger.error('Get profile logs error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async generateActivationCode(req, res) {
    try {
      const { profileId, carrier, quantity = 1 } = req.body;
      
      const activationCodes = await carrierService.generateActivationCodes({
        profileId,
        carrier,
        quantity,
        userId: req.user.id
      });

      res.json({
        success: true,
        data: activationCodes,
        message: 'Activation codes generated successfully'
      });
    } catch (error) {
      logger.error('Generate activation code error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
}

module.exports = new ProfileController();