"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.connectToGraph = exports.graphClient = void 0;
const microsoft_graph_client_1 = require("@microsoft/microsoft-graph-client");
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
class GraphAuthProvider {
    async getAccessToken() {
        return process.env.AZURE_ACCESS_TOKEN || 'mock-token';
    }
}
exports.graphClient = microsoft_graph_client_1.Client.initWithMiddleware({
    authProvider: new GraphAuthProvider()
});
const connectToGraph = async () => {
    try {
        const user = await exports.graphClient.api('/me').get();
        console.log('Connected to Microsoft Graph as:', user.displayName);
        return true;
    }
    catch (error) {
        console.error('Graph connection failed:', error);
        return false;
    }
};
exports.connectToGraph = connectToGraph;
exports.default = exports.graphClient;
//# sourceMappingURL=graph.js.map