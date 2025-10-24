import { PublicClientApplication, Configuration, AuthenticationResult } from '@azure/msal-browser';

const msalConfig: Configuration = {
  auth: {
    clientId: process.env.REACT_APP_AZURE_CLIENT_ID || '',
    authority: `https://login.microsoftonline.com/${process.env.REACT_APP_AZURE_TENANT_ID}`,
    redirectUri: window.location.origin
  },
  cache: {
    cacheLocation: 'localStorage',
    storeAuthStateInCookie: false
  }
};

const loginRequest = {
  scopes: ['User.Read', 'DeviceManagementManagedDevices.ReadWrite.All', 'DeviceManagementConfiguration.ReadWrite.All']
};

class AuthService {
  private msalInstance: PublicClientApplication;

  constructor() {
    this.msalInstance = new PublicClientApplication(msalConfig);
  }

  async initialize(): Promise<void> {
    await this.msalInstance.initialize();
  }

  async login(): Promise<AuthenticationResult> {
    try {
      return await this.msalInstance.loginPopup(loginRequest);
    } catch (error) {
      throw new Error(`Login failed: ${error.message}`);
    }
  }

  async getToken(): Promise<string> {
    try {
      const accounts = this.msalInstance.getAllAccounts();
      if (accounts.length === 0) throw new Error('No accounts found');

      const response = await this.msalInstance.acquireTokenSilent({
        ...loginRequest,
        account: accounts[0]
      });
      return response.accessToken;
    } catch (error) {
      const response = await this.msalInstance.acquireTokenPopup(loginRequest);
      return response.accessToken;
    }
  }

  async logout(): Promise<void> {
    await this.msalInstance.logoutPopup();
  }

  isAuthenticated(): boolean {
    return this.msalInstance.getAllAccounts().length > 0;
  }

  getCurrentUser() {
    const accounts = this.msalInstance.getAllAccounts();
    return accounts[0] || null;
  }
}

export const authService = new AuthService();