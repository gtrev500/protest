-- Create the junction table for protest submission types (many-to-many relationship)
CREATE TABLE IF NOT EXISTS protest_submission_types (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  protest_id uuid NOT NULL REFERENCES protests(id) ON DELETE CASCADE,
  submission_type_id integer REFERENCES submission_types(id),
  other_value text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT unique_protest_submission_type UNIQUE (protest_id, submission_type_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_protest_submission_types_protest_id 
  ON protest_submission_types(protest_id);
CREATE INDEX IF NOT EXISTS idx_protest_submission_types_submission_type_id 
  ON protest_submission_types(submission_type_id);

-- Enable RLS (Row Level Security)
ALTER TABLE protest_submission_types ENABLE ROW LEVEL SECURITY;

-- Create policy to allow public read access
CREATE POLICY "Public can read protest submission types" ON protest_submission_types
  FOR SELECT
  USING (true);

-- Create policy to allow public insert (for form submissions)
CREATE POLICY "Public can insert protest submission types" ON protest_submission_types
  FOR INSERT
  WITH CHECK (true);

COMMENT ON TABLE protest_submission_types IS 'Junction table linking protests to submission types with optional other values';
COMMENT ON COLUMN protest_submission_types.other_value IS 'Used when submission_type_id is 0 (Other) to store custom submission type';