-- Drop the old function first (with the old signature)
DROP FUNCTION IF EXISTS submit_protest(jsonb, jsonb, jsonb, jsonb, jsonb, jsonb);

-- Updated function to submit a complete protest with all related data including submission types
CREATE OR REPLACE FUNCTION submit_protest(
  protest_data jsonb,
  submission_types_data jsonb DEFAULT '[]'::jsonb,
  event_types_data jsonb DEFAULT '[]'::jsonb,
  participant_types_data jsonb DEFAULT '[]'::jsonb,
  participant_measures_data jsonb DEFAULT '[]'::jsonb,
  police_measures_data jsonb DEFAULT '[]'::jsonb,
  notes_data jsonb DEFAULT '[]'::jsonb
) RETURNS jsonb AS $$
DECLARE
  new_protest_id uuid;
  result jsonb;
BEGIN
  -- Insert the main protest record
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
    count_method
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
    protest_data->>'count_method'
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to anon and authenticated roles
GRANT EXECUTE ON FUNCTION submit_protest TO anon, authenticated;