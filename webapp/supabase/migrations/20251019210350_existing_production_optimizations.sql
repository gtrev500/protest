-- Migration to document existing production optimizations
-- These changes were already manually applied to production for emergency performance fixes
-- This migration ensures they're tracked in version control and applied to dev/staging

-- ============================================================================
-- 1. Add index on protests.date_of_event
-- ============================================================================
-- This index helps with ORDER BY date_of_event queries (common in the dashboard)
CREATE INDEX IF NOT EXISTS idx_protests_date_of_event
ON protests(date_of_event);

-- ============================================================================
-- 2. Optimized get_protest_stats function
-- ============================================================================
-- This function is called by the ProtestDashboard to show aggregate statistics
-- Optimizations:
-- - Uses CTE for better query planning
-- - CROSS JOIN with bounds for efficient date filtering
-- - Single pass aggregation for all metrics

CREATE OR REPLACE FUNCTION get_protest_stats(
  start_date date DEFAULT NULL,
  end_date   date DEFAULT NULL
) RETURNS jsonb
LANGUAGE sql STABLE AS
$$
WITH bounds AS (
  SELECT
    COALESCE(start_date, '-infinity'::date) AS s,
    COALESCE(end_date,   'infinity'::date)  AS e
),
filtered AS (
  SELECT p.*
  FROM protests p
  CROSS JOIN bounds b
  WHERE p.date_of_event >= b.s
    AND p.date_of_event <= b.e
),
totals AS (
  SELECT
    COUNT(*)                         AS total_protests,
    SUM(crowd_size_low)              AS total_participants_low,
    SUM(crowd_size_high)             AS total_participants_high,
    COUNT(DISTINCT state_code)       AS states_count
  FROM filtered
),
by_state AS (
  SELECT jsonb_object_agg(state_code, cnt) AS protests_by_state
  FROM (
    SELECT state_code, COUNT(*) AS cnt
    FROM filtered
    WHERE state_code IS NOT NULL
    GROUP BY state_code
  ) s
),
by_month AS (
  SELECT jsonb_agg(
           jsonb_build_object('month', to_char(month, 'YYYY-MM'), 'count', cnt)
           ORDER BY month
         ) AS protests_by_month
  FROM (
    SELECT date_trunc('month', date_of_event)::date AS month,
           COUNT(*) AS cnt
    FROM filtered
    GROUP BY 1
    ORDER BY 1
  ) m
)
SELECT jsonb_build_object(
  'total_protests',         t.total_protests,
  'total_participants_low', t.total_participants_low,
  'total_participants_high',t.total_participants_high,
  'states_count',           t.states_count,
  'protests_by_state',      s.protests_by_state,
  'protests_by_month',      m.protests_by_month
)
FROM totals t, by_state s, by_month m;
$$;

-- ============================================================================
-- 3. Increase statement timeout to prevent query timeouts
-- ============================================================================
-- The /log route was timing out due to slow queries on protest_details view
-- This emergency fix allowed the page to load while we work on proper optimization
-- Default timeout was too aggressive for the complex view queries

ALTER ROLE anon SET statement_timeout = '30s';
ALTER ROLE authenticated SET statement_timeout = '30s';

-- Reload PostgREST configuration to pick up the new settings
NOTIFY pgrst, 'reload config';

-- ============================================================================
-- NOTES
-- ============================================================================
-- These were emergency fixes applied directly to production.
-- The proper long-term fixes are in subsequent migrations:
-- - 20251019210355: Add junction table indexes
-- - 20251019210356: Optimize protest_details view with LATERAL subqueries
--
-- After applying the view optimization, the timeout increase may no longer be
-- necessary, but we're keeping it as a safety margin.
