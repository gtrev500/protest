-- Migration: Remove unused submission types
-- Remove "Other" (id=0) and "updated or additional source for existing record" (id=3)

-- Step 1: Update any protests that use submission_type_id=3 to use id=2 (data correction)
-- This applies if there are any protests using the junction table with these types
UPDATE protest_submission_types
SET submission_type_id = 2
WHERE submission_type_id = 3;

-- Step 2: Remove any junction table entries for "Other" (id=0)
DELETE FROM protest_submission_types
WHERE submission_type_id = 0;

-- Step 3: Delete the unwanted submission types
DELETE FROM submission_types
WHERE id IN (0, 3);

-- Step 4: Update the reference_type logic to only use 'correction' (not 'update_source')
-- The submit_protest function will handle this through the junction table
-- reference_type column stays as-is for backward compatibility

-- Note: The frontend will now only show:
-- id=1: "new record"
-- id=2: "data correction" (requires referenced_protest_id)