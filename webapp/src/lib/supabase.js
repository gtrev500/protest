import { createClient } from '@supabase/supabase-js';

// Get these values from your Supabase dashboard
// For self-hosted, they're in your .env file
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'http://localhost:8000';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'your-anon-key-here';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);