export class ESimProfileService {
  async createProfile(data: any) {
    return { success: true, data };
  }
  
  async getProfiles() {
    return { success: true, data: [] };
  }
  
  async updateProfile(id: string, data: any) {
    return { success: true, data };
  }
  
  async deleteProfile(id: string) {
    return { success: true };
  }
}