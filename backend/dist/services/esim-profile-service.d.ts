export declare class ESimProfileService {
    createProfile(data: any): Promise<{
        success: boolean;
        data: any;
    }>;
    getProfiles(): Promise<{
        success: boolean;
        data: any[];
    }>;
    updateProfile(id: string, data: any): Promise<{
        success: boolean;
        data: any;
    }>;
    deleteProfile(id: string): Promise<{
        success: boolean;
    }>;
}
//# sourceMappingURL=esim-profile-service.d.ts.map