-- Migration: Add reference tracking for corrections and updates
-- This adds support for single submission type selection and protest references

-- Step 1: Add reference tracking columns to protests table
ALTER TABLE protests
ADD COLUMN IF NOT EXISTS referenced_protest_id UUID REFERENCES protests(id),
ADD COLUMN IF NOT EXISTS reference_type TEXT;

-- Step 2: Create index for reference lookups
CREATE INDEX IF NOT EXISTS idx_protests_referenced
ON protests(referenced_protest_id)
WHERE referenced_protest_id IS NOT NULL;

-- Step 3: Create search function for finding protests to reference
CREATE OR REPLACE FUNCTION search_protests_for_reference(
  query_text TEXT,
  limit_count INT DEFAULT 10,
  offset_count INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  date_of_event DATE,
  locality TEXT,
  state_code TEXT,
  claims_summary TEXT,
  organization_name TEXT,
  rank REAL,
  submission_date TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Return empty result for short queries
  IF LENGTH(query_text) < 3 THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    COALESCE(p.title, 'Untitled Event') as title,
    p.date_of_event,
    p.locality,
    p.state_code,
    CASE
      WHEN LENGTH(p.claims_summary) > 150
      THEN LEFT(p.claims_summary, 147) || '...'
      ELSE p.claims_summary
    END as claims_summary,
    p.organization_name,
    ts_rank(p.search_vector, plainto_tsquery('english', query_text)) as rank,
    p.created_at::timestamp as submission_date
  FROM protests p
  WHERE
    -- Full text search using existing search vector
    p.search_vector @@ plainto_tsquery('english', query_text)
    -- Fallback to ILIKE for direct matches
    OR p.locality ILIKE '%' || query_text || '%'
    OR p.organization_name ILIKE '%' || query_text || '%'
    OR p.title ILIKE '%' || query_text || '%'
    -- Date search if query looks like a date
    OR (query_text ~ '^\d{4}-\d{2}-\d{2}$' AND p.date_of_event::text = query_text)
  ORDER BY
    rank DESC,
    p.date_of_event DESC
  LIMIT limit_count
  OFFSET offset_count;
END;
$$;

-- Step 4: Grant necessary permissions
GRANT EXECUTE ON FUNCTION search_protests_for_reference(TEXT, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION search_protests_for_reference(TEXT, INT, INT) TO anon;

-- Step 5: Add constraint for reference types
ALTER TABLE protests ADD CONSTRAINT check_reference_type
  CHECK (reference_type IN ('correction', 'update_source') OR reference_type IS NULL);