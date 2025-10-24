const axios = require('axios');
const logger = require('../utils/logger');

class CarrierIntegration {
  constructor() {
    this.carriers = {
      MPT: {
        name: 'Myanmar Posts and Telecommunications',
        mcc: '414',
        mnc: '01',
        apiUrl: process.env.MPT_API_URL,
        apiKey: process.env.MPT_API_KEY
      },
      ATOM: {
        name: 'Atom Myanmar',
        mcc: '414',
        mnc: '06',
        apiUrl: process.env.ATOM_API_URL,
        apiKey: process.env.ATOM_API_KEY
      },
      U9: {
        name: 'U9 Networks',
        mcc: '414',
        mnc: '07',
        apiUrl: process.env.U9_API_URL,
        apiKey: process.env.U9_API_KEY
      },
      MYTEL: {
        name: 'MyTel Myanmar',
        mcc: '414',
        mnc: '09',
        apiUrl: process.env.MYTEL_API_URL,
        apiKey: process.env.MYTEL_API_KEY
      }
    };
  }

  async createProfile(carrier, profileData) {
    try {
      const carrierConfig = this.carriers[carrier];
      if (!carrierConfig) {
        throw new Error(`Unsupported carrier: ${carrier}`);
      }

      const response = await axios.post(
        `${carrierConfig.apiUrl}/profiles`,
        {
          ...profileData,
          mcc: carrierConfig.mcc,
          mnc: carrierConfig.mnc
        },
        {
          headers: {
            'Authorization': `Bearer ${carrierConfig.apiKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return response.data;
    } catch (error) {
      logger.error(`${carrier} create profile error:`, error);
      throw error;
    }
  }

  async generateActivationCode(carrier, profileId, quantity = 1) {
    try {
      const carrierConfig = this.carriers[carrier];
      if (!carrierConfig) {
        throw new Error(`Unsupported carrier: ${carrier}`);
      }

      const response = await axios.post(
        `${carrierConfig.apiUrl}/activation-codes`,
        {
          profileId,
          quantity
        },
        {
          headers: {
            'Authorization': `Bearer ${carrierConfig.apiKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return response.data;
    } catch (error) {
      logger.error(`${carrier} generate AC error:`, error);
      throw error;
    }
  }

  async getProfileStatus(carrier, profileId) {
    try {
      const carrierConfig = this.carriers[carrier];
      if (!carrierConfig) {
        throw new Error(`Unsupported carrier: ${carrier}`);
      }

      const response = await axios.get(
        `${carrierConfig.apiUrl}/profiles/${profileId}/status`,
        {
          headers: {
            'Authorization': `Bearer ${carrierConfig.apiKey}`
          }
        }
      );

      return response.data;
    } catch (error) {
      logger.error(`${carrier} get profile status error:`, error);
      throw error;
    }
  }

  async activateProfile(carrier, profileId, deviceId) {
    try {
      const carrierConfig = this.carriers[carrier];
      if (!carrierConfig) {
        throw new Error(`Unsupported carrier: ${carrier}`);
      }

      const response = await axios.post(
        `${carrierConfig.apiUrl}/profiles/${profileId}/activate`,
        { deviceId },
        {
          headers: {
            'Authorization': `Bearer ${carrierConfig.apiKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return response.data;
    } catch (error) {
      logger.error(`${carrier} activate profile error:`, error);
      throw error;
    }
  }

  async deactivateProfile(carrier, profileId) {
    try {
      const carrierConfig = this.carriers[carrier];
      if (!carrierConfig) {
        throw new Error(`Unsupported carrier: ${carrier}`);
      }

      const response = await axios.post(
        `${carrierConfig.apiUrl}/profiles/${profileId}/deactivate`,
        {},
        {
          headers: {
            'Authorization': `Bearer ${carrierConfig.apiKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return response.data;
    } catch (error) {
      logger.error(`${carrier} deactivate profile error:`, error);
      throw error;
    }
  }

  async deleteProfile(carrier, profileId) {
    try {
      const carrierConfig = this.carriers[carrier];
      if (!carrierConfig) {
        throw new Error(`Unsupported carrier: ${carrier}`);
      }

      const response = await axios.delete(
        `${carrierConfig.apiUrl}/profiles/${profileId}`,
        {
          headers: {
            'Authorization': `Bearer ${carrierConfig.apiKey}`
          }
        }
      );

      return response.data;
    } catch (error) {
      logger.error(`${carrier} delete profile error:`, error);
      throw error;
    }
  }

  async getDeviceProfiles(carrier, deviceId) {
    try {
      const carrierConfig = this.carriers[carrier];
      if (!carrierConfig) {
        throw new Error(`Unsupported carrier: ${carrier}`);
      }

      const response = await axios.get(
        `${carrierConfig.apiUrl}/devices/${deviceId}/profiles`,
        {
          headers: {
            'Authorization': `Bearer ${carrierConfig.apiKey}`
          }
        }
      );

      return response.data;
    } catch (error) {
      logger.error(`${carrier} get device profiles error:`, error);
      throw error;
    }
  }

  getSupportedCarriers() {
    return Object.keys(this.carriers).map(key => ({
      code: key,
      ...this.carriers[key]
    }));
  }
}

module.exports = new CarrierIntegration();