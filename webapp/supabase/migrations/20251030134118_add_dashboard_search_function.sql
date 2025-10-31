-- Migration: Add comprehensive search function for protest dashboard
-- Replaces the broken textSearch implementation that caused tsquery syntax errors.
--
-- This function uses websearch_to_tsquery() to properly convert plain text searches
-- into valid tsquery format, with multiple ILIKE fallback searches for better coverage.
-- Supports filtering by state and date range, with relevance-based ranking.

CREATE FUNCTION search_protest_dashboard(
  query_text TEXT,
  state_filter TEXT DEFAULT NULL,
  start_date_filter DATE DEFAULT NULL,
  end_date_filter DATE DEFAULT NULL,
  sort_field TEXT DEFAULT 'date_of_event',
  sort_order TEXT DEFAULT 'desc',
  limit_count INT DEFAULT 20,
  offset_count INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  date_of_event DATE,
  locality TEXT,
  state_code TEXT,
  location_name TEXT,
  title TEXT,
  organization_name TEXT,
  notable_participants TEXT,
  targets TEXT,
  claims_summary TEXT,
  claims_verbatim TEXT,
  macroevent TEXT,
  is_online BOOLEAN,
  crowd_size_low INT,
  crowd_size_high INT,
  participant_injury TEXT,
  participant_injury_details TEXT,
  police_injury TEXT,
  police_injury_details TEXT,
  arrests TEXT,
  arrests_details TEXT,
  property_damage TEXT,
  property_damage_details TEXT,
  participant_casualties TEXT,
  participant_casualties_details TEXT,
  police_casualties TEXT,
  police_casualties_details TEXT,
  sources TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  search_vector TSVECTOR,
  event_types TEXT[],
  participant_types TEXT[],
  participant_measures_list TEXT[],
  police_measures_list TEXT[],
  notes_list TEXT[],
  count_methods TEXT[],
  rank REAL,
  total_count BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
  base_query TEXT;
  where_clauses TEXT[] := ARRAY[]::TEXT[];
  order_clause TEXT;
  final_query TEXT;
BEGIN
  -- Build WHERE clauses

  -- Search filter (if provided)
  IF query_text IS NOT NULL AND LENGTH(TRIM(query_text)) >= 1 THEN
    -- Use websearch_to_tsquery for more flexible search (supports "quoted phrases", -exclusions, OR)
    -- Falls back to multiple ILIKE searches for better coverage
    where_clauses := array_append(where_clauses,
      format('(
        search_vector @@ websearch_to_tsquery(''english'', %L)
        OR locality ILIKE %L
        OR organization_name ILIKE %L
        OR title ILIKE %L
        OR claims_summary ILIKE %L
        OR state_code ILIKE %L
        OR (targets IS NOT NULL AND targets ILIKE %L)
        OR (notable_participants IS NOT NULL AND notable_participants ILIKE %L)
      )',
      query_text,
      '%' || query_text || '%',
      '%' || query_text || '%',
      '%' || query_text || '%',
      '%' || query_text || '%',
      '%' || query_text || '%',
      '%' || query_text || '%',
      '%' || query_text || '%'
      )
    );
  END IF;

  -- State filter
  IF state_filter IS NOT NULL AND LENGTH(state_filter) > 0 THEN
    where_clauses := array_append(where_clauses, format('state_code = %L', state_filter));
  END IF;

  -- Date filters
  IF start_date_filter IS NOT NULL THEN
    where_clauses := array_append(where_clauses, format('date_of_event >= %L', start_date_filter));
  END IF;

  IF end_date_filter IS NOT NULL THEN
    where_clauses := array_append(where_clauses, format('date_of_event <= %L', end_date_filter));
  END IF;

  -- Build ORDER BY clause
  -- Validate sort_field to prevent SQL injection
  IF sort_field NOT IN ('date_of_event', 'created_at', 'title', 'locality', 'state_code', 'crowd_size_low', 'crowd_size_high') THEN
    sort_field := 'date_of_event';
  END IF;

  IF sort_order NOT IN ('asc', 'desc') THEN
    sort_order := 'desc';
  END IF;

  -- If searching, order by relevance first
  IF query_text IS NOT NULL AND LENGTH(TRIM(query_text)) >= 1 THEN
    order_clause := format('ts_rank(search_vector, websearch_to_tsquery(''english'', %L)) DESC, %I %s',
      query_text, sort_field, sort_order);
  ELSE
    order_clause := format('%I %s', sort_field, sort_order);
  END IF;

  -- Build final query
  base_query := 'SELECT
    pd.*,
    ts_rank(pd.search_vector, websearch_to_tsquery(''english'', COALESCE($1, ''''))) as rank,
    COUNT(*) OVER() as total_count
  FROM protest_details pd';

  IF array_length(where_clauses, 1) > 0 THEN
    base_query := base_query || ' WHERE ' || array_to_string(where_clauses, ' AND ');
  END IF;

  base_query := base_query || ' ORDER BY ' || order_clause;
  base_query := base_query || format(' LIMIT %s OFFSET %s', limit_count, offset_count);

  -- Execute and return
  RETURN QUERY EXECUTE base_query USING query_text;
END;
$$;

-- Re-grant permissions
GRANT EXECUTE ON FUNCTION search_protest_dashboard(TEXT, TEXT, DATE, DATE, TEXT, TEXT, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION search_protest_dashboard(TEXT, TEXT, DATE, DATE, TEXT, TEXT, INT, INT) TO anon;

COMMENT ON FUNCTION search_protest_dashboard IS
'Comprehensive search function for protest dashboard. Uses websearch_to_tsquery for proper text search conversion, with ILIKE fallbacks for direct matches. Supports filtering by state and date range, with customizable sorting. Fixes tsquery syntax errors from the old .textSearch() implementation.';
