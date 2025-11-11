-- Migration: Add submission types to protest_details view and search function
-- Adds submission_types array to protest_details view and adds submission_type_id filter to search_protest_dashboard

-- Drop the old function first
DROP FUNCTION IF EXISTS search_protest_dashboard(TEXT, TEXT, DATE, DATE, TEXT, TEXT, INT, INT);

-- Update protest_details view to include submission types
CREATE OR REPLACE VIEW protest_details AS
SELECT
    p.id,
    p.date_of_event,
    p.locality,
    p.state_code,
    p.location_name,
    p.title,
    p.organization_name,
    p.notable_participants,
    p.targets,
    p.claims_summary,
    p.claims_verbatim,
    p.macroevent,
    p.is_online,
    p.crowd_size_low,
    p.crowd_size_high,
    p.participant_injury,
    p.participant_injury_details,
    p.police_injury,
    p.police_injury_details,
    p.arrests,
    p.arrests_details,
    p.property_damage,
    p.property_damage_details,
    p.participant_casualties,
    p.participant_casualties_details,
    p.police_casualties,
    p.police_casualties_details,
    p.sources,
    p.created_at,
    p.updated_at,
    p.search_vector,

    -- Event types - using LATERAL subquery
    event_types_agg.event_types,

    -- Participant types - using LATERAL subquery
    participant_types_agg.participant_types,

    -- Participant measures - using LATERAL subquery
    participant_measures_agg.participant_measures_list,

    -- Police measures - using LATERAL subquery
    police_measures_agg.police_measures_list,

    -- Notes - using LATERAL subquery
    notes_agg.notes_list,

    -- Count methods - using LATERAL subquery
    count_methods_agg.count_methods,

    -- Submission types - using LATERAL subquery
    submission_types_agg.submission_types

FROM protests p

-- Event types
CROSS JOIN LATERAL (
    SELECT array_agg(DISTINCT COALESCE('"' || pet.other_value || '"', et.name))
           FILTER (WHERE COALESCE(pet.other_value, et.name) IS NOT NULL) AS event_types
    FROM protest_event_types pet
    LEFT JOIN event_types et ON pet.event_type_id = et.id
    WHERE pet.protest_id = p.id
) event_types_agg

-- Participant types
CROSS JOIN LATERAL (
    SELECT array_agg(DISTINCT COALESCE('"' || ppt.other_value || '"', pt.name))
           FILTER (WHERE COALESCE(ppt.other_value, pt.name) IS NOT NULL) AS participant_types
    FROM protest_participant_types ppt
    LEFT JOIN participant_types pt ON ppt.participant_type_id = pt.id
    WHERE ppt.protest_id = p.id
) participant_types_agg

-- Participant measures
CROSS JOIN LATERAL (
    SELECT array_agg(DISTINCT COALESCE('"' || ppm.other_value || '"', pm.name))
           FILTER (WHERE COALESCE(ppm.other_value, pm.name) IS NOT NULL) AS participant_measures_list
    FROM protest_participant_measures ppm
    LEFT JOIN participant_measures pm ON ppm.measure_id = pm.id
    WHERE ppm.protest_id = p.id
) participant_measures_agg

-- Police measures
CROSS JOIN LATERAL (
    SELECT array_agg(DISTINCT COALESCE('"' || pplm.other_value || '"', plm.name))
           FILTER (WHERE COALESCE(pplm.other_value, plm.name) IS NOT NULL) AS police_measures_list
    FROM protest_police_measures pplm
    LEFT JOIN police_measures plm ON pplm.measure_id = plm.id
    WHERE pplm.protest_id = p.id
) police_measures_agg

-- Notes
CROSS JOIN LATERAL (
    SELECT array_agg(DISTINCT COALESCE('"' || pn.other_value || '"', no.name))
           FILTER (WHERE COALESCE(pn.other_value, no.name) IS NOT NULL) AS notes_list
    FROM protest_notes pn
    LEFT JOIN notes_options no ON pn.note_id = no.id
    WHERE pn.protest_id = p.id
) notes_agg

-- Count methods
CROSS JOIN LATERAL (
    SELECT array_agg(DISTINCT COALESCE('"' || pcm.other_value || '"', cm.name))
           FILTER (WHERE COALESCE(pcm.other_value, cm.name) IS NOT NULL) AS count_methods
    FROM protest_count_methods pcm
    LEFT JOIN count_methods cm ON pcm.count_method_id = cm.id
    WHERE pcm.protest_id = p.id
) count_methods_agg

-- Submission types
CROSS JOIN LATERAL (
    SELECT array_agg(DISTINCT COALESCE('"' || pst.other_value || '"', st.name))
           FILTER (WHERE COALESCE(pst.other_value, st.name) IS NOT NULL) AS submission_types
    FROM protest_submission_types pst
    LEFT JOIN submission_types st ON pst.submission_type_id = st.id
    WHERE pst.protest_id = p.id
) submission_types_agg;

-- Update search_protest_dashboard function to include submission type filter
CREATE OR REPLACE FUNCTION search_protest_dashboard(
  query_text TEXT,
  state_filter TEXT DEFAULT NULL,
  start_date_filter DATE DEFAULT NULL,
  end_date_filter DATE DEFAULT NULL,
  submission_type_filter INT DEFAULT NULL,
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
  submission_types TEXT[],
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

  -- Submission type filter
  -- Use special value -1 for "other" (custom submission types)
  IF submission_type_filter IS NOT NULL THEN
    IF submission_type_filter = -1 THEN
      -- Filter for "other" - entries with other_value populated
      where_clauses := array_append(where_clauses,
        format('EXISTS (
          SELECT 1 FROM protest_submission_types pst
          WHERE pst.protest_id = pd.id
          AND pst.other_value IS NOT NULL
        )')
      );
    ELSE
      -- Filter for specific submission type ID
      where_clauses := array_append(where_clauses,
        format('EXISTS (
          SELECT 1 FROM protest_submission_types pst
          WHERE pst.protest_id = pd.id
          AND pst.submission_type_id = %L
        )', submission_type_filter)
      );
    END IF;
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

-- Update permissions
GRANT EXECUTE ON FUNCTION search_protest_dashboard(TEXT, TEXT, DATE, DATE, INT, TEXT, TEXT, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION search_protest_dashboard(TEXT, TEXT, DATE, DATE, INT, TEXT, TEXT, INT, INT) TO anon;

COMMENT ON FUNCTION search_protest_dashboard IS
'Comprehensive search function for protest dashboard with submission type filtering. Uses websearch_to_tsquery for proper text search conversion, with ILIKE fallbacks for direct matches. Supports filtering by state, date range, and submission type (use -1 for "other"/custom types), with customizable sorting.';
