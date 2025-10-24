import { Pool } from 'pg';
export declare const supabase: import("@supabase/supabase-js").SupabaseClient<any, "public", "public", any, any>;
declare const pool: Pool;
export declare const query: (text: string, params?: any[]) => Promise<import("pg").QueryResult<any>>;
export declare const getClient: () => Promise<import("pg").PoolClient>;
export default pool;
//# sourceMappingURL=database.d.ts.map