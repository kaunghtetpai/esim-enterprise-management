import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://zsmldhvjvvlscrrckpli.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpzbWxkaHZqdnZsc2NycmNrcGxpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyMjEyMDIsImV4cCI6MjA3Njc5NzIwMn0.GS6tSiJ7kREnTRH7RTL5UChElIl18blRCWj6QdnyJnY';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);