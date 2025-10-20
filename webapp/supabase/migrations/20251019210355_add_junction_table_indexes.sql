-- Add individual indexes on protest_id for junction tables
-- These will speed up the LEFT JOINs in the protest_details view
--
-- Context: The protest_details view does multiple LEFT JOINs to junction tables.
-- While composite primary keys exist on (protest_id, other_id), individual indexes
-- on protest_id alone will help PostgreSQL optimize the join operations.

-- protest_event_types
CREATE INDEX IF NOT EXISTS idx_protest_event_types_protest_id
ON protest_event_types(protest_id);

-- protest_participant_types
CREATE INDEX IF NOT EXISTS idx_protest_participant_types_protest_id
ON protest_participant_types(protest_id);

-- protest_participant_measures
CREATE INDEX IF NOT EXISTS idx_protest_participant_measures_protest_id
ON protest_participant_measures(protest_id);

-- protest_police_measures
CREATE INDEX IF NOT EXISTS idx_protest_police_measures_protest_id
ON protest_police_measures(protest_id);

-- protest_notes
CREATE INDEX IF NOT EXISTS idx_protest_notes_protest_id
ON protest_notes(protest_id);
