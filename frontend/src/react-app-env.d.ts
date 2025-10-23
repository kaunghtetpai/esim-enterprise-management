/// <reference types="react-scripts" />

declare namespace NodeJS {
  interface ProcessEnv {
    REACT_APP_API_URL: string;
    REACT_APP_AZURE_CLIENT_ID: string;
    REACT_APP_AZURE_TENANT_ID: string;
    REACT_APP_VERSION: string;
  }
}