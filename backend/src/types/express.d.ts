declare namespace Express {
  interface Request {
    user?: any;
    startTime?: number;
    rateLimit?: any;
  }
}