"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuditService = void 0;
class AuditService {
    async log(action, userId, details) {
        console.log('Audit:', { action, userId, details, timestamp: new Date() });
        return { success: true };
    }
}
exports.AuditService = AuditService;
