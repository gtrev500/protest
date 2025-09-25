-- Migration: Add reference tracking for corrections and updates
-- Date: 2024-01-24
-- Description: Adds support for single submission type selection and protest references

-- Step 1: Add reference tracking columns to protests table
ALTER TABLE protests
ADD COLUMN IF NOT EXISTS referenced_protest_id UUID REFERENCES protests(id),
ADD COLUMN IF NOT EXISTS reference_type TEXT;

-- Step 2: Create index for reference lookups
CREATE INDEX IF NOT EXISTS idx_protests_referenced
ON protests(referenced_protest_id)
WHERE referenced_protest_id IS NOT NULL;

-- Step 3: Create search function for finding protests to reference
CREATE OR REPLACE FUNCTION search_protests_for_reference(
  query_text TEXT,
  limit_count INT DEFAULT 10,
  offset_count INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  date_of_event DATE,
  locality TEXT,
  state_code TEXT,
  claims_summary TEXT,
  organization_name TEXT,
  rank REAL,
  submission_date TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Return empty result for short queries
  IF LENGTH(query_text) < 3 THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    COALESCE(p.title, 'Untitled Event') as title,
    p.date_of_event,
    p.locality,
    p.state_code,
    CASE
      WHEN LENGTH(p.claims_summary) > 150
      THEN LEFT(p.claims_summary, 147) || '...'
      ELSE p.claims_summary
    END as claims_summary,
    p.organization_name,
    ts_rank(p.search_vector, plainto_tsquery('english', query_text)) as rank,
    p.created_at as submission_date
  FROM protests p
  WHERE
    -- Full text search using existing search vector
    p.search_vector @@ plainto_tsquery('english', query_text)
    -- Fallback to ILIKE for direct matches
    OR p.locality ILIKE '%' || query_text || '%'
    OR p.organization_name ILIKE '%' || query_text || '%'
    OR p.title ILIKE '%' || query_text || '%'
    -- Date search if query looks like a date
    OR (query_text ~ '^\d{4}-\d{2}-\d{2}$' AND p.date_of_event::text = query_text)
  ORDER BY
    rank DESC,
    p.date_of_event DESC
  LIMIT limit_count
  OFFSET offset_count;
END;
$$;

-- Step 4: Modified submit_protest function to handle single submission type
CREATE OR REPLACE FUNCTION submit_protest(
  protest_data jsonb,
  submission_types_data jsonb,
  event_types_data jsonb,
  participant_types_data jsonb,
  participant_measures_data jsonb,
  police_measures_data jsonb,
  notes_data jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  new_protest_id uuid;
  result jsonb;
  submission_type_id integer;
  submission_type_other text;
  referenced_id uuid;
BEGIN
  -- Extract reference data if present
  referenced_id := NULLIF(protest_data->>'referenced_protest_id', '')::uuid;

  -- Extract first submission type (for backward compatibility and new single-select)
  IF jsonb_array_length(submission_types_data) > 0 THEN
    submission_type_id := (submission_types_data->0->>'id')::integer;
    submission_type_other := submission_types_data->0->>'other';
  END IF;

  -- Insert the main protest record with reference data
  INSERT INTO protests (
    date_of_event,
    locality,
    state_code,
    location_name,
    title,
    organization_name,
    notable_participants,
    targets,
    claims_summary,
    claims_verbatim,
    macroevent,
    is_online,
    crowd_size_low,
    crowd_size_high,
    participant_injury,
    participant_injury_details,
    police_injury,
    police_injury_details,
    arrests,
    arrests_details,
    property_damage,
    property_damage_details,
    participant_casualties,
    participant_casualties_details,
    police_casualties,
    police_casualties_details,
    sources,
    count_method,
    referenced_protest_id,
    reference_type
  ) VALUES (
    (protest_data->>'date_of_event')::date,
    protest_data->>'locality',
    protest_data->>'state_code',
    protest_data->>'location_name',
    protest_data->>'title',
    protest_data->>'organization_name',
    protest_data->>'notable_participants',
    protest_data->>'targets',
    protest_data->>'claims_summary',
    protest_data->>'claims_verbatim',
    protest_data->>'macroevent',
    COALESCE((protest_data->>'is_online')::boolean, false),
    (protest_data->>'crowd_size_low')::integer,
    (protest_data->>'crowd_size_high')::integer,
    protest_data->>'participant_injury',
    protest_data->>'participant_injury_details',
    protest_data->>'police_injury',
    protest_data->>'police_injury_details',
    protest_data->>'arrests',
    protest_data->>'arrests_details',
    protest_data->>'property_damage',
    protest_data->>'property_damage_details',
    protest_data->>'participant_casualties',
    protest_data->>'participant_casualties_details',
    protest_data->>'police_casualties',
    protest_data->>'police_casualties_details',
    protest_data->>'sources',
    protest_data->>'count_method',
    referenced_id,
    CASE
      -- Determine reference type based on submission type ID
      -- These IDs should match your submission_types table
      WHEN submission_type_id = 3 THEN 'correction'
      WHEN submission_type_id = 2 THEN 'update_source'
      ELSE NULL
    END
  ) RETURNING id INTO new_protest_id;

  -- Insert submission types (handling both array for compatibility and single value)
  IF jsonb_array_length(submission_types_data) > 0 THEN
    INSERT INTO protest_submission_types (protest_id, submission_type_id, other_value)
    SELECT
      new_protest_id,
      CASE
        WHEN (item->>'id') IS NOT NULL THEN (item->>'id')::integer
        ELSE NULL
      END,
      item->>'other'
    FROM jsonb_array_elements(submission_types_data) AS item
    WHERE (item->>'id') IS NOT NULL OR (item->>'other') IS NOT NULL;
  END IF;

  -- Insert event types
  IF jsonb_array_length(event_types_data) > 0 THEN
    INSERT INTO protest_event_types (protest_id, event_type_id, other_value)
    SELECT
      new_protest_id,
      CASE
        WHEN (item->>'id') IS NOT NULL THEN (item->>'id')::integer
        ELSE NULL
      END,
      item->>'other'
    FROM jsonb_array_elements(event_types_data) AS item
    WHERE (item->>'id') IS NOT NULL OR (item->>'other') IS NOT NULL;
  END IF;

  -- Insert participant types
  IF jsonb_array_length(participant_types_data) > 0 THEN
    INSERT INTO protest_participant_types (protest_id, participant_type_id)
    SELECT
      new_protest_id,
      (item->>'id')::integer
    FROM jsonb_array_elements(participant_types_data) AS item
    WHERE (item->>'id') IS NOT NULL;
  END IF;

  -- Insert participant measures
  IF jsonb_array_length(participant_measures_data) > 0 THEN
    INSERT INTO protest_participant_measures (protest_id, measure_id, other_value)
    SELECT
      new_protest_id,
      CASE
        WHEN (item->>'id') IS NOT NULL THEN (item->>'id')::integer
        ELSE NULL
      END,
      item->>'other'
    FROM jsonb_array_elements(participant_measures_data) AS item
    WHERE (item->>'id') IS NOT NULL OR (item->>'other') IS NOT NULL;
  END IF;

  -- Insert police measures
  IF jsonb_array_length(police_measures_data) > 0 THEN
    INSERT INTO protest_police_measures (protest_id, measure_id, other_value)
    SELECT
      new_protest_id,
      CASE
        WHEN (item->>'id') IS NOT NULL THEN (item->>'id')::integer
        ELSE NULL
      END,
      item->>'other'
    FROM jsonb_array_elements(police_measures_data) AS item
    WHERE (item->>'id') IS NOT NULL OR (item->>'other') IS NOT NULL;
  END IF;

  -- Insert notes
  IF jsonb_array_length(notes_data) > 0 THEN
    INSERT INTO protest_notes (protest_id, note_id, other_value)
    SELECT
      new_protest_id,
      CASE
        WHEN (item->>'id') IS NOT NULL THEN (item->>'id')::integer
        ELSE NULL
      END,
      item->>'other'
    FROM jsonb_array_elements(notes_data) AS item
    WHERE (item->>'id') IS NOT NULL OR (item->>'other') IS NOT NULL;
  END IF;

  -- Return the result
  result := jsonb_build_object(
    'id', new_protest_id,
    'success', true,
    'public_url', '/protest/' || new_protest_id
  );

  RETURN result;
END;
$$;

-- Step 5: Add constraint after data verification (to be run later)
-- ALTER TABLE protests ADD CONSTRAINT check_reference_type
--   CHECK (reference_type IN ('correction', 'update_source', NULL));

-- Step 6: Grant necessary permissions
GRANT EXECUTE ON FUNCTION search_protests_for_reference(TEXT, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION search_protests_for_reference(TEXT, INT, INT) TO anon;