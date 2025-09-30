-- Migration: Fix submit_protest function and cleanup
-- 1. Remove macroevent from 7-parameter function (field deprecated)
-- 2. Remove submission_type_id=3 check (type deleted from database)
-- 3. Tighten reference_type constraint (remove 'update_source')
-- 4. Delete unused 1-parameter function

-- Step 1: Drop and recreate the 7-parameter function with fixes
DROP FUNCTION IF EXISTS submit_protest(jsonb, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb);

CREATE FUNCTION submit_protest(
  protest_data jsonb,
  submission_types_data jsonb,
  event_types_data jsonb,
  participant_types_data jsonb,
  participant_measures_data jsonb,
  police_measures_data jsonb,
  notes_data jsonb
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_protest_id uuid;
  result jsonb;
  submission_type_id integer;
  referenced_id uuid;
BEGIN
  -- Extract reference data if present
  referenced_id := NULLIF(protest_data->>'referenced_protest_id', '')::uuid;

  -- Extract first submission type (for determining reference type)
  IF jsonb_array_length(submission_types_data) > 0 THEN
    submission_type_id := (submission_types_data->0->>'id')::integer;
  END IF;

  -- Insert the main protest record (macroevent REMOVED - deprecated)
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
    -- macroevent field removed (deprecated as of 2025-09-25)
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
    -- macroevent value removed
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
      -- Only submission_type_id=2 sets reference_type
      -- submission_type_id=3 was deleted in migration 20250925230000
      WHEN submission_type_id = 2 THEN 'correction'
      ELSE NULL
    END
  ) RETURNING id INTO new_protest_id;

  -- Insert submission types
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

  -- Insert participant types with other_value support
  IF jsonb_array_length(participant_types_data) > 0 THEN
    INSERT INTO protest_participant_types (protest_id, participant_type_id, other_value)
    SELECT
      new_protest_id,
      CASE
        WHEN (item->>'id') IS NOT NULL THEN (item->>'id')::integer
        ELSE NULL
      END,
      item->>'other'
    FROM jsonb_array_elements(participant_types_data) AS item
    WHERE (item->>'id') IS NOT NULL OR (item->>'other') IS NOT NULL;
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
$$ LANGUAGE plpgsql;

-- Step 2: Restore permissions for 7-parameter function
GRANT EXECUTE ON FUNCTION submit_protest(jsonb, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb) TO anon;

-- Update comment
COMMENT ON FUNCTION submit_protest(jsonb, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb) IS
'Public form submission function for protests. Runs with SECURITY DEFINER to bypass RLS for inserts.
This is the only way public users should insert protest data. Handles participant_types with other_value support.
Updated 2025-09-30: Removed deprecated macroevent field and fixed reference_type logic.';

-- Step 3: Delete unused 1-parameter function
-- This function was never used by the frontend (confirmed via codebase analysis)
DROP FUNCTION IF EXISTS submit_protest(jsonb);

-- Step 4: Tighten reference_type constraint
-- Remove 'update_source' since submission_type_id=3 was deleted
ALTER TABLE protests DROP CONSTRAINT IF EXISTS check_reference_type;
ALTER TABLE protests ADD CONSTRAINT check_reference_type
  CHECK (reference_type = 'correction' OR reference_type IS NULL);

-- Step 5: Update column comment to reflect constraint change
COMMENT ON COLUMN protests.reference_type IS
'Type of reference relationship to another protest. Only "correction" is currently supported.
Set automatically by submit_protest() when submission_type_id=2.';