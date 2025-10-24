import { Request, Response, NextFunction } from 'express';
export declare const validateRequest: (schema: any) => (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>>;
export declare const validateProfile: (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>>;
export declare const validateDevice: (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>>;
export declare const validateUser: (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>>;
export declare const validateUUID: (paramName?: string) => (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>>;
export declare const validatePagination: (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>>;
export declare const validateDateRange: (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>>;
export declare const sanitizeInput: (req: Request, res: Response, next: NextFunction) => void;
//# sourceMappingURL=validation.d.ts.map