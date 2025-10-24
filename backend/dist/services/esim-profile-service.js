"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ESimProfileService = void 0;
class ESimProfileService {
    async createProfile(data) {
        return { success: true, data };
    }
    async getProfiles() {
        return { success: true, data: [] };
    }
    async updateProfile(id, data) {
        return { success: true, data };
    }
    async deleteProfile(id) {
        return { success: true };
    }
}
exports.ESimProfileService = ESimProfileService;
