import { Client } from '@microsoft/microsoft-graph-client';
import dotenv from 'dotenv';

dotenv.config();

class GraphAuthProvider {
  async getAccessToken(): Promise<string> {
    return process.env.AZURE_ACCESS_TOKEN || 'mock-token';
  }
}

export const graphClient = Client.initWithMiddleware({
  authProvider: new GraphAuthProvider()
});

export const connectToGraph = async () => {
  try {
    const user = await graphClient.api('/me').get();
    console.log('Connected to Microsoft Graph as:', user.displayName);
    return true;
  } catch (error) {
    console.error('Graph connection failed:', error);
    return false;
  }
};

export default graphClient;