/* ----------  WIPE USER-SUBMITTED DATA  ---------- */

BEGIN;

-- Temporarily disable RLS so the wipe works even if you run it
-- through the PostgREST / Supabase service account.
ALTER TABLE protests                  DISABLE ROW LEVEL SECURITY;
ALTER TABLE protest_event_types       DISABLE ROW LEVEL SECURITY;
ALTER TABLE protest_participant_types DISABLE ROW LEVEL SECURITY;
ALTER TABLE protest_participant_measures DISABLE ROW LEVEL SECURITY;
ALTER TABLE protest_police_measures   DISABLE ROW LEVEL SECURITY;
ALTER TABLE protest_notes             DISABLE ROW LEVEL SECURITY;

-- One command does it all:
--   • TRUNCATE is faster than DELETE
--   • CASCADE removes the child rows automatically
--   • Lookup tables are *not* affected
TRUNCATE TABLE protests CASCADE;

-- (Optional) vacuum the tables for immediate space reclaim
-- VACUUM (VERBOSE, ANALYZE) protests;

-- Re-enable RLS
ALTER TABLE protests                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE protest_event_types       ENABLE ROW LEVEL SECURITY;
ALTER TABLE protest_participant_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE protest_participant_measures ENABLE ROW LEVEL SECURITY;
ALTER TABLE protest_police_measures   ENABLE ROW LEVEL SECURITY;
ALTER TABLE protest_notes             ENABLE ROW LEVEL SECURITY;

COMMIT;
