-- Migration: Deprecate macroevent field
-- Strategy: Keep column for historical data but stop collecting new entries
-- Existing data (20 records) will be preserved

-- Add a comment to document deprecation
COMMENT ON COLUMN protests.macroevent IS 'DEPRECATED: No longer collected as of 2025-09-25. Historical data preserved.';

-- Update submit_protest function to ignore macroevent in new submissions
CREATE OR REPLACE FUNCTION submit_protest(
  protest_json JSONB
)
RETURNS UUID
AS $$
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
  -- ID 2 is "data correction" -> 'correction'
  -- ID 1 is "new record" -> NULL
  derived_reference_type := NULL;
  IF protest_json->'submission_types_data' IS NOT NULL AND jsonb_array_length(protest_json->'submission_types_data') > 0 THEN
    FOR submission_type_item IN SELECT * FROM jsonb_array_elements(protest_json->'submission_types_data')
    LOOP
      IF (submission_type_item->>'id')::integer = 2 THEN
        derived_reference_type := 'correction';
        EXIT; -- Stop on first match
      END IF;
    END LOOP;
  END IF;

  -- Insert the main protest record
  -- NOTE: macroevent is intentionally omitted - field deprecated
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
    -- macroevent, -- DEPRECATED: No longer collected
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
    reference_type  -- Derived from submission_types_data
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
    -- protest_json->>'macroevent', -- DEPRECATED: No longer collected
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

  -- Process submission_types (junction table)
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

  -- Process participant_types
  IF protest_json->'participant_types_data' IS NOT NULL AND jsonb_array_length(protest_json->'participant_types_data') > 0 THEN
    FOR participant_type_item IN SELECT * FROM jsonb_array_elements(protest_json->'participant_types_data')
    LOOP
      INSERT INTO protest_participant_types (protest_id, participant_type_id)
      VALUES (
        new_protest_id,
        (participant_type_item->>'id')::integer
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

  -- Return the new protest id wrapped in a JSON object
  RETURN new_protest_id;
END;
$$ LANGUAGE plpgsql;