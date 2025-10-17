-- Migration: Convert count_method from text field to checkbox group with "other" support
-- This migration:
-- 1. Creates count_methods lookup table with predefined counting methods
-- 2. Creates protest_count_methods junction table
-- 3. Migrates existing data from count_method text column to junction table
-- 4. Updates submit_protest function to handle count_methods_data parameter
-- 5. Updates protest_details view to include count_methods aggregation
-- 6. Drops the old count_method text column

-- Step 1: Create count_methods lookup table
CREATE TABLE IF NOT EXISTS "public"."count_methods" (
  "id" integer PRIMARY KEY,
  "name" text NOT NULL UNIQUE
);

-- Step 2: Populate count_methods with predefined options
-- Note: id=0 is reserved for "Other" entries (custom counting methods)
INSERT INTO count_methods (id, name) VALUES
  (0, 'Other'),
  (1, 'Sign-ins'),
  (2, 'Visual estimate/count'),
  (3, 'Distributed flyers/handouts'),
ON CONFLICT (id) DO NOTHING;

COMMENT ON TABLE "public"."count_methods" IS
'Lookup table for crowd counting methods. ID 0 is reserved for custom "Other" entries.';

-- Step 3: Create protest_count_methods junction table
CREATE TABLE IF NOT EXISTS "public"."protest_count_methods" (
  "protest_id" uuid NOT NULL REFERENCES protests(id) ON DELETE CASCADE,
  "count_method_id" integer NOT NULL,
  "other_value" text,
  PRIMARY KEY (protest_id, count_method_id)
);

COMMENT ON TABLE "public"."protest_count_methods" IS
'Junction table linking protests to crowd counting methods.
When count_method_id=0, other_value stores the custom counting method text.';

-- Step 4: Migrate existing data from count_method text column to junction table
-- All existing text values will be stored as "Other" (id=0) to preserve data integrity
INSERT INTO protest_count_methods (protest_id, count_method_id, other_value)
SELECT
  id AS protest_id,
  0 AS count_method_id,
  count_method AS other_value
FROM protests
WHERE count_method IS NOT NULL
  AND count_method != ''
  AND count_method != 'NULL'
ON CONFLICT (protest_id, count_method_id) DO NOTHING;

-- Step 5: Update submit_protest function to accept count_methods_data parameter
DROP FUNCTION IF EXISTS submit_protest(jsonb, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb);

CREATE FUNCTION submit_protest(
  protest_data jsonb,
  submission_types_data jsonb,
  event_types_data jsonb,
  participant_types_data jsonb,
  participant_measures_data jsonb,
  police_measures_data jsonb,
  notes_data jsonb,
  count_methods_data jsonb DEFAULT '[]'::jsonb
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

  -- Insert the main protest record (count_method field removed - now in junction table)
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
    referenced_id,
    CASE
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

  -- Insert participant types
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

  -- Insert count methods (NEW)
  IF jsonb_array_length(count_methods_data) > 0 THEN
    INSERT INTO protest_count_methods (protest_id, count_method_id, other_value)
    SELECT
      new_protest_id,
      CASE
        WHEN (item->>'id') IS NOT NULL THEN (item->>'id')::integer
        ELSE NULL
      END,
      item->>'other'
    FROM jsonb_array_elements(count_methods_data) AS item
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

-- Restore permissions
GRANT EXECUTE ON FUNCTION submit_protest(jsonb, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb) TO anon;

-- Update function comment
COMMENT ON FUNCTION submit_protest(jsonb, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb) IS
'Public form submission function for protests. Runs with SECURITY DEFINER to bypass RLS for inserts.
Updated 2025-10-16: Added count_methods_data parameter to support checkbox-based counting methods with "other" option.';

-- Step 6: Update protest_details view to include count_methods
DROP VIEW IF EXISTS "public"."protest_details";

CREATE VIEW "public"."protest_details" AS
 SELECT "p"."id",
    "p"."date_of_event",
    "p"."locality",
    "p"."state_code",
    "p"."location_name",
    "p"."title",
    "p"."organization_name",
    "p"."notable_participants",
    "p"."targets",
    "p"."claims_summary",
    "p"."claims_verbatim",
    "p"."macroevent",
    "p"."is_online",
    "p"."crowd_size_low",
    "p"."crowd_size_high",
    "p"."participant_injury",
    "p"."participant_injury_details",
    "p"."police_injury",
    "p"."police_injury_details",
    "p"."arrests",
    "p"."arrests_details",
    "p"."property_damage",
    "p"."property_damage_details",
    "p"."participant_casualties",
    "p"."participant_casualties_details",
    "p"."police_casualties",
    "p"."police_casualties_details",
    "p"."sources",
    "p"."created_at",
    "p"."updated_at",
    "p"."search_vector",
    -- count_method text field removed, replaced with count_methods array
    "array_agg"(DISTINCT COALESCE('"' || "pet"."other_value" || '"', "et"."name"))
      FILTER (WHERE (COALESCE("pet"."other_value", "et"."name") IS NOT NULL)) AS "event_types",
    "array_agg"(DISTINCT COALESCE('"' || "ppt"."other_value" || '"', "pt"."name"))
      FILTER (WHERE (COALESCE("ppt"."other_value", "pt"."name") IS NOT NULL)) AS "participant_types",
    "array_agg"(DISTINCT COALESCE('"' || "ppm"."other_value" || '"', "pm"."name"))
      FILTER (WHERE (COALESCE("ppm"."other_value", "pm"."name") IS NOT NULL)) AS "participant_measures_list",
    "array_agg"(DISTINCT COALESCE('"' || "pplm"."other_value" || '"', "plm"."name"))
      FILTER (WHERE (COALESCE("pplm"."other_value", "plm"."name") IS NOT NULL)) AS "police_measures_list",
    "array_agg"(DISTINCT COALESCE('"' || "pn"."other_value" || '"', "no"."name"))
      FILTER (WHERE (COALESCE("pn"."other_value", "no"."name") IS NOT NULL)) AS "notes_list",
    "array_agg"(DISTINCT COALESCE('"' || "pcm"."other_value" || '"', "cm"."name"))
      FILTER (WHERE (COALESCE("pcm"."other_value", "cm"."name") IS NOT NULL)) AS "count_methods"
   FROM (((((((((((("public"."protests" "p"
     LEFT JOIN "public"."protest_event_types" "pet" ON (("p"."id" = "pet"."protest_id")))
     LEFT JOIN "public"."event_types" "et" ON (("pet"."event_type_id" = "et"."id")))
     LEFT JOIN "public"."protest_participant_types" "ppt" ON (("p"."id" = "ppt"."protest_id")))
     LEFT JOIN "public"."participant_types" "pt" ON (("ppt"."participant_type_id" = "pt"."id")))
     LEFT JOIN "public"."protest_participant_measures" "ppm" ON (("p"."id" = "ppm"."protest_id")))
     LEFT JOIN "public"."participant_measures" "pm" ON (("ppm"."measure_id" = "pm"."id")))
     LEFT JOIN "public"."protest_police_measures" "pplm" ON (("p"."id" = "pplm"."protest_id")))
     LEFT JOIN "public"."police_measures" "plm" ON (("pplm"."measure_id" = "plm"."id")))
     LEFT JOIN "public"."protest_notes" "pn" ON (("p"."id" = "pn"."protest_id")))
     LEFT JOIN "public"."notes_options" "no" ON (("pn"."note_id" = "no"."id")))
     LEFT JOIN "public"."protest_count_methods" "pcm" ON (("p"."id" = "pcm"."protest_id")))
     LEFT JOIN "public"."count_methods" "cm" ON (("pcm"."count_method_id" = "cm"."id")))
  GROUP BY "p"."id";

COMMENT ON VIEW "public"."protest_details" IS
'Denormalized view of protests with all related lookup data.
All junction tables (event_types, participant_types, participant_measures, police_measures, notes, count_methods)
include custom other_value text when provided instead of lookup table names.
Custom "other" values are wrapped in quotes to differentiate from predefined lookup values.
Updated 2025-10-16: Added count_methods array to replace deprecated count_method text field.';

-- Step 7: Drop the old count_method text column from protests table
-- This is safe because we've migrated all data to the junction table
ALTER TABLE protests DROP COLUMN IF EXISTS count_method;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_protest_count_methods_protest_id
  ON protest_count_methods(protest_id);
CREATE INDEX IF NOT EXISTS idx_protest_count_methods_count_method_id
  ON protest_count_methods(count_method_id);
