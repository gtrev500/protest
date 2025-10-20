-- Optimize protest_details view to prevent Cartesian product explosion
--
-- PROBLEM: The old view did 6 LEFT JOINs which created 413,435 intermediate rows
-- from just 330 protests, then used GROUP BY to collapse back to 330 rows.
-- This caused massive memory usage, disk spills, and 16+ second query times.
--
-- SOLUTION: Use LATERAL subqueries to compute each array independently.
-- Each subquery only processes rows for one protest at a time, avoiding the
-- Cartesian product entirely.
--
-- Expected improvement: ~16 seconds → <100ms

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
    count_methods_agg.count_methods

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
) count_methods_agg;
