-- Add "other" field support for participant_types to match other junction tables
-- This consolidates multiple migrations for cleaner production deployment

-- 1. Add other_value column to protest_participant_types table
ALTER TABLE protest_participant_types
ADD COLUMN other_value text;

-- 2. Update both submit_protest functions to handle participant_types other_value field

-- Drop and recreate the 7-parameter version with SECURITY DEFINER
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
      WHEN submission_type_id = 2 THEN 'correction'
      WHEN submission_type_id = 3 THEN 'update_source'
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

-- Update the JSON-based submit_protest function (for backward compatibility)
DROP FUNCTION IF EXISTS submit_protest(jsonb);

CREATE FUNCTION submit_protest(protest_json jsonb)
RETURNS uuid AS $$
DECLARE
  new_protest_id UUID;
  submission_type_item JSONB;
  event_type_item JSONB;
  participant_type_item JSONB;
  participant_measure_item JSONB;
  police_measure_item JSONB;
  note_item JSONB;
  derived_reference_type TEXT;
BEGIN
  -- Derive reference_type from submission_types_data
  derived_reference_type := NULL;
  IF protest_json->'submission_types_data' IS NOT NULL AND jsonb_array_length(protest_json->'submission_types_data') > 0 THEN
    FOR submission_type_item IN SELECT * FROM jsonb_array_elements(protest_json->'submission_types_data')
    LOOP
      IF (submission_type_item->>'id')::integer = 2 THEN
        derived_reference_type := 'correction';
        EXIT;
      END IF;
    END LOOP;
  END IF;

  -- Insert the main protest record
  INSERT INTO protests (
    title,
    date_of_event,
    locality,
    state_code,
    location_name,
    organization_name,
    notable_participants,
    targets,
    claims_summary,
    claims_verbatim,
    is_online,
    crowd_size_low,
    crowd_size_high,
    count_method,
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
    referenced_protest_id,
    reference_type
  ) VALUES (
    protest_json->>'title',
    (protest_json->>'date_of_event')::date,
    protest_json->>'locality',
    protest_json->>'state_code',
    protest_json->>'location_name',
    protest_json->>'organization_name',
    protest_json->>'notable_participants',
    protest_json->>'targets',
    protest_json->>'claims_summary',
    protest_json->>'claims_verbatim',
    COALESCE((protest_json->>'is_online')::boolean, false),
    NULLIF(protest_json->>'crowd_size_low', '')::integer,
    NULLIF(protest_json->>'crowd_size_high', '')::integer,
    protest_json->>'count_method',
    protest_json->>'participant_injury',
    protest_json->>'participant_injury_details',
    protest_json->>'police_injury',
    protest_json->>'police_injury_details',
    protest_json->>'arrests',
    protest_json->>'arrests_details',
    protest_json->>'property_damage',
    protest_json->>'property_damage_details',
    protest_json->>'participant_casualties',
    protest_json->>'participant_casualties_details',
    protest_json->>'police_casualties',
    protest_json->>'police_casualties_details',
    protest_json->>'sources',
    NULLIF(protest_json->>'referenced_protest_id', '')::uuid,
    derived_reference_type
  ) RETURNING id INTO new_protest_id;

  -- Process submission_types
  IF protest_json->'submission_types_data' IS NOT NULL AND jsonb_array_length(protest_json->'submission_types_data') > 0 THEN
    FOR submission_type_item IN SELECT * FROM jsonb_array_elements(protest_json->'submission_types_data')
    LOOP
      INSERT INTO protest_submission_types (protest_id, submission_type_id)
      VALUES (
        new_protest_id,
        (submission_type_item->>'id')::integer
      );
    END LOOP;
  END IF;

  -- Process event_types
  IF protest_json->'event_types_data' IS NOT NULL AND jsonb_array_length(protest_json->'event_types_data') > 0 THEN
    FOR event_type_item IN SELECT * FROM jsonb_array_elements(protest_json->'event_types_data')
    LOOP
      INSERT INTO protest_event_types (protest_id, event_type_id, other_value)
      VALUES (
        new_protest_id,
        (event_type_item->>'id')::integer,
        event_type_item->>'other_value'
      );
    END LOOP;
  END IF;

  -- Process participant_types with other_value support
  IF protest_json->'participant_types_data' IS NOT NULL AND jsonb_array_length(protest_json->'participant_types_data') > 0 THEN
    FOR participant_type_item IN SELECT * FROM jsonb_array_elements(protest_json->'participant_types_data')
    LOOP
      INSERT INTO protest_participant_types (protest_id, participant_type_id, other_value)
      VALUES (
        new_protest_id,
        (participant_type_item->>'id')::integer,
        participant_type_item->>'other_value'
      );
    END LOOP;
  END IF;

  -- Process participant_measures
  IF protest_json->'participant_measures_data' IS NOT NULL AND jsonb_array_length(protest_json->'participant_measures_data') > 0 THEN
    FOR participant_measure_item IN SELECT * FROM jsonb_array_elements(protest_json->'participant_measures_data')
    LOOP
      INSERT INTO protest_participant_measures (protest_id, measure_id, other_value)
      VALUES (
        new_protest_id,
        (participant_measure_item->>'id')::integer,
        participant_measure_item->>'other_value'
      );
    END LOOP;
  END IF;

  -- Process police_measures
  IF protest_json->'police_measures_data' IS NOT NULL AND jsonb_array_length(protest_json->'police_measures_data') > 0 THEN
    FOR police_measure_item IN SELECT * FROM jsonb_array_elements(protest_json->'police_measures_data')
    LOOP
      INSERT INTO protest_police_measures (protest_id, measure_id, other_value)
      VALUES (
        new_protest_id,
        (police_measure_item->>'id')::integer,
        police_measure_item->>'other_value'
      );
    END LOOP;
  END IF;

  -- Process notes
  IF protest_json->'notes_data' IS NOT NULL AND jsonb_array_length(protest_json->'notes_data') > 0 THEN
    FOR note_item IN SELECT * FROM jsonb_array_elements(protest_json->'notes_data')
    LOOP
      INSERT INTO protest_notes (protest_id, note_id, other_value)
      VALUES (
        new_protest_id,
        (note_item->>'id')::integer,
        note_item->>'other_value'
      );
    END LOOP;
  END IF;

  RETURN new_protest_id;
END;
$$ LANGUAGE plpgsql;

-- 3. Set up proper RLS permissions
-- Revoke direct INSERT permissions (data should flow through functions)
REVOKE INSERT ON protest_participant_types FROM anon, authenticated;
REVOKE INSERT ON protest_event_types FROM anon, authenticated;
REVOKE INSERT ON protest_participant_measures FROM anon, authenticated;
REVOKE INSERT ON protest_police_measures FROM anon, authenticated;
REVOKE INSERT ON protest_notes FROM anon, authenticated;
REVOKE INSERT ON protest_submission_types FROM anon, authenticated;
REVOKE INSERT ON protests FROM anon, authenticated;

-- Ensure SELECT permissions remain for public viewing
GRANT SELECT ON protest_participant_types TO anon, authenticated;
GRANT SELECT ON protest_event_types TO anon, authenticated;
GRANT SELECT ON protest_participant_measures TO anon, authenticated;
GRANT SELECT ON protest_police_measures TO anon, authenticated;
GRANT SELECT ON protest_notes TO anon, authenticated;
GRANT SELECT ON protest_submission_types TO anon, authenticated;
GRANT SELECT ON protests TO anon, authenticated;

-- Grant EXECUTE permission on the submit_protest function
GRANT EXECUTE ON FUNCTION submit_protest(jsonb, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb) TO anon;

-- Add comment explaining the security model
COMMENT ON FUNCTION submit_protest(jsonb, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb) IS
'Public form submission function for protests. Runs with SECURITY DEFINER to bypass RLS for inserts.
This is the only way public users should insert protest data. Handles participant_types with other_value support.';