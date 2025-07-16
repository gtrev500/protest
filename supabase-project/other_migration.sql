BEGIN;

-- Reserve id=0 for "Other" in each lookup table
INSERT INTO event_types (id, name) VALUES (0, 'Other');
INSERT INTO participant_measures (id, name) VALUES (0, 'Other');  
INSERT INTO police_measures (id, name) VALUES (0, 'Other');
INSERT INTO notes_options (id, name) VALUES (0, 'Other');

-- Ensure sequences start at 1 (not 0) for future auto-generated ids
SELECT setval('event_types_id_seq', 1, false);
SELECT setval('participant_measures_id_seq', 1, false); 
SELECT setval('police_measures_id_seq', 1, false);
SELECT setval('notes_options_id_seq', 1, false);

COMMIT;
