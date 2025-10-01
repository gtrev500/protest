-- Fix protest_details view to show other_value for all junction tables when present
-- When a user selects "Other" (id=0) and enters custom text,
-- that text is stored in the junction table's other_value field
-- This migration updates the view to display that custom text instead of just the lookup table name
-- Applies to: event_types, participant_types, participant_measures, police_measures, notes

CREATE OR REPLACE VIEW "public"."protest_details" AS
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
    "p"."count_method",
    -- Updated to include other_value when present for all junction tables
    -- Custom "other" values are wrapped in quotes to differentiate from lookup values
    "array_agg"(DISTINCT COALESCE('"' || "pet"."other_value" || '"', "et"."name"))
      FILTER (WHERE (COALESCE("pet"."other_value", "et"."name") IS NOT NULL)) AS "event_types",
    "array_agg"(DISTINCT COALESCE('"' || "ppt"."other_value" || '"', "pt"."name"))
      FILTER (WHERE (COALESCE("ppt"."other_value", "pt"."name") IS NOT NULL)) AS "participant_types",
    "array_agg"(DISTINCT COALESCE('"' || "ppm"."other_value" || '"', "pm"."name"))
      FILTER (WHERE (COALESCE("ppm"."other_value", "pm"."name") IS NOT NULL)) AS "participant_measures_list",
    "array_agg"(DISTINCT COALESCE('"' || "pplm"."other_value" || '"', "plm"."name"))
      FILTER (WHERE (COALESCE("pplm"."other_value", "plm"."name") IS NOT NULL)) AS "police_measures_list",
    "array_agg"(DISTINCT COALESCE('"' || "pn"."other_value" || '"', "no"."name"))
      FILTER (WHERE (COALESCE("pn"."other_value", "no"."name") IS NOT NULL)) AS "notes_list"
   FROM (((((((((("public"."protests" "p"
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
  GROUP BY "p"."id";

COMMENT ON VIEW "public"."protest_details" IS
'Denormalized view of protests with all related lookup data.
All junction tables (event_types, participant_types, participant_measures, police_measures, notes)
include custom other_value text when provided instead of lookup table names.
Custom "other" values are wrapped in quotes to differentiate from predefined lookup values.';