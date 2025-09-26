-- Seed file for local development
-- This file seeds the database with essential lookup data and sample protests

-- Clear existing data (in reverse order of dependencies)
TRUNCATE TABLE protest_submission_types CASCADE;
TRUNCATE TABLE protest_notes CASCADE;
TRUNCATE TABLE protest_police_measures CASCADE;
TRUNCATE TABLE protest_participant_measures CASCADE;
TRUNCATE TABLE protest_participant_types CASCADE;
TRUNCATE TABLE protest_event_types CASCADE;
TRUNCATE TABLE protests CASCADE;
TRUNCATE TABLE submission_types CASCADE;
TRUNCATE TABLE notes_options CASCADE;
TRUNCATE TABLE police_measures CASCADE;
TRUNCATE TABLE participant_measures CASCADE;
TRUNCATE TABLE participant_types CASCADE;
TRUNCATE TABLE event_types CASCADE;
TRUNCATE TABLE states CASCADE;

-- Insert states
INSERT INTO states (code, name) VALUES
('AK', 'ALASKA'),
('AL', 'ALABAMA'),
('AR', 'ARKANSAS'),
('AS', 'AMERICAN SAMOA'),
('AZ', 'ARIZONA'),
('CA', 'CALIFORNIA'),
('CO', 'COLORADO'),
('CT', 'CONNECTICUT'),
('DC', 'DISTRICT OF COLUMBIA'),
('DE', 'DELAWARE'),
('FL', 'FLORIDA'),
('GA', 'GEORGIA'),
('GU', 'GUAM'),
('HI', 'HAWAII'),
('IA', 'IOWA'),
('ID', 'IDAHO'),
('IL', 'ILLINOIS'),
('IN', 'INDIANA'),
('KS', 'KANSAS'),
('KY', 'KENTUCKY'),
('LA', 'LOUISIANA'),
('MA', 'MASSACHUSETTS'),
('MD', 'MARYLAND'),
('ME', 'MAINE'),
('MI', 'MICHIGAN'),
('MN', 'MINNESOTA'),
('MO', 'MISSOURI'),
('MP', 'NORTHERN MARIANA IS'),
('MS', 'MISSISSIPPI'),
('MT', 'MONTANA'),
('NC', 'NORTH CAROLINA'),
('ND', 'NORTH DAKOTA'),
('NE', 'NEBRASKA'),
('NH', 'NEW HAMPSHIRE'),
('NJ', 'NEW JERSEY'),
('NM', 'NEW MEXICO'),
('NV', 'NEVADA'),
('NY', 'NEW YORK'),
('OH', 'OHIO'),
('OK', 'OKLAHOMA'),
('OR', 'OREGON'),
('PA', 'PENNSYLVANIA'),
('PR', 'PUERTO RICO'),
('RI', 'RHODE ISLAND'),
('SC', 'SOUTH CAROLINA'),
('SD', 'SOUTH DAKOTA'),
('TN', 'TENNESSEE'),
('TX', 'TEXAS'),
('UT', 'UTAH'),
('VA', 'VIRGINIA'),
('VI', 'VIRGIN ISLANDS'),
('VT', 'VERMONT'),
('WA', 'WASHINGTON'),
('WI', 'WISCONSIN'),
('WV', 'WEST VIRGINIA'),
('WY', 'WYOMING');

-- Insert submission types (CRITICAL for the new feature)
INSERT INTO submission_types (id, name) VALUES
(1, 'new record'),
(2, 'data correction');

-- Insert event types
INSERT INTO event_types (id, name) VALUES
(0, 'Other'),
(1, 'Wear Coordinated Colors'),
(2, 'Walk-Out'),
(3, 'Vigil*'),
(4, 'Silent Protest'),
(5, 'Parade*'),
(6, 'Rally'),
(7, 'Disrupt Public Comment / Meeting'),
(8, 'Commemorative Gathering*'),
(9, 'Sit-In'),
(10, 'Go-Slow'),
(11, 'Protest'),
(12, 'Coordinated Non-Compliance'),
(13, 'Direct Action'),
(14, 'Banner Drop'),
(15, 'Car Caravan'),
(16, 'Demonstration'),
(17, 'Die-In'),
(18, 'Memorial*'),
(19, 'Strike'),
(20, 'Picket'),
(21, 'Boat parade'),
(22, 'Motorcycle ride'),
(23, 'Bicycle ride'),
(24, 'Run'),
(25, 'Walk'),
(26, 'Counter-protest');

-- Insert participant types (sample data - you can expand this)
INSERT INTO participant_types (id, name) VALUES
(0, 'Other'),
(1, 'Workers/Labor'),
(2, 'Students'),
(3, 'Environmental activists'),
(4, 'Healthcare workers'),
(5, 'Teachers'),
(6, 'Parents'),
(7, 'Youth'),
(8, 'Seniors'),
(9, 'Veterans'),
(10, 'Religious groups'),
(11, 'Community organizations'),
(12, 'Union members'),
(13, 'Scientists'),
(14, 'Artists'),
(15, 'Indigenous groups');

-- Insert participant measures (sample data)
INSERT INTO participant_measures (id, name) VALUES
(0, 'Other'),
(1, 'Marching'),
(2, 'Chanting'),
(3, 'Holding signs'),
(4, 'Blocking traffic'),
(5, 'Civil disobedience'),
(6, 'Speeches'),
(7, 'Music/singing'),
(8, 'Prayer'),
(9, 'Moment of silence'),
(10, 'Human chain'),
(11, 'Occupation'),
(12, 'Boycott'),
(13, 'Banner display'),
(14, 'Art installation'),
(15, 'Street theater');

-- Insert police measures (sample data)
INSERT INTO police_measures (id, name) VALUES
(0, 'Other'),
(1, 'Present but not intervening'),
(2, 'Traffic control'),
(3, 'Perimeter established'),
(4, 'Verbal warnings'),
(5, 'Arrests made'),
(6, 'Use of barriers'),
(7, 'Dispersal order'),
(8, 'Tear gas deployed'),
(9, 'Rubber bullets used'),
(10, 'Water cannons used'),
(11, 'Mounted police'),
(12, 'Riot gear deployed'),
(13, 'Negotiations'),
(14, 'De-escalation tactics'),
(15, 'Surveillance');

-- Insert notes options (sample data)
INSERT INTO notes_options (id, name) VALUES
(0, 'Other'),
(1, 'Peaceful protest'),
(2, 'Some violence reported'),
(3, 'Mass arrest'),
(4, 'Counter-protesters present'),
(5, 'Media coverage'),
(6, 'Political figures attended'),
(7, 'Part of larger movement'),
(8, 'First amendment zone'),
(9, 'Permit obtained'),
(10, 'Spontaneous gathering'),
(11, 'Social media organized'),
(12, 'Weather impacted'),
(13, 'COVID protocols observed'),
(14, 'International solidarity'),
(15, 'Historic significance');

-- Insert sample protests for testing the reference search feature
INSERT INTO protests (
  id,
  date_of_event,
  locality,
  state_code,
  title,
  organization_name,
  claims_summary,
  is_online,
  crowd_size_low,
  crowd_size_high,
  sources,
  created_at
) VALUES
(
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  '2024-03-15',
  'New York',
  'NY',
  'Climate Action Now March',
  'Fridays for Future NYC',
  'Demanding immediate climate action and renewable energy transition. Youth-led march from Union Square to Times Square.',
  false,
  5000,
  8000,
  'https://example.com/climate-march-nyc',
  '2024-03-16 10:00:00'
),
(
  'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12',
  '2024-02-20',
  'Seattle',
  'WA',
  'Tech Workers for Fair Wages',
  'Tech Workers Coalition',
  'Tech industry employees rally for better wages and working conditions amid layoffs.',
  false,
  1500,
  2000,
  'https://example.com/tech-workers-seattle',
  '2024-02-21 10:00:00'
),
(
  'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13',
  '2024-01-10',
  'Los Angeles',
  'CA',
  'Housing Justice Rally',
  'LA Tenants Union',
  'Protest against rising rents and demanding rent control measures.',
  false,
  3000,
  4500,
  'https://example.com/housing-la',
  '2024-01-11 10:00:00'
),
(
  'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14',
  '2023-12-05',
  'Chicago',
  'IL',
  'Education Funding Protest',
  'Chicago Teachers Union',
  'Teachers and parents demand increased education funding and smaller class sizes.',
  false,
  2000,
  3000,
  'https://example.com/education-chicago',
  '2023-12-06 10:00:00'
),
(
  'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a15',
  '2023-11-15',
  'Austin',
  'TX',
  'Healthcare Access March',
  'Healthcare for All Texas',
  'March for universal healthcare and prescription drug price controls.',
  false,
  1000,
  1500,
  'https://example.com/healthcare-austin',
  '2023-11-16 10:00:00'
);

-- Add some junction table data for the sample protests
INSERT INTO protest_submission_types (protest_id, submission_type_id) VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 1),
('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 1),
('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', 1),
('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14', 1),
('e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a15', 1);

INSERT INTO protest_event_types (protest_id, event_type_id) VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 6), -- Rally
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 16), -- Demonstration
('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 11), -- Protest
('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', 6), -- Rally
('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14', 11), -- Protest
('e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a15', 25); -- Walk

INSERT INTO protest_participant_types (protest_id, participant_type_id) VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 2), -- Students
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 3), -- Environmental activists
('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 1), -- Workers/Labor
('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', 11), -- Community organizations
('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14', 5), -- Teachers
('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14', 6), -- Parents
('e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a15', 4); -- Healthcare workers

-- Update the search vectors for the sample protests (if trigger doesn't handle it)
UPDATE protests SET search_vector =
  setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
  setweight(to_tsvector('english', coalesce(claims_summary, '')), 'B') ||
  setweight(to_tsvector('english', coalesce(organization_name, '')), 'D')
WHERE search_vector IS NULL;

-- Display success message
DO $$
BEGIN
  RAISE NOTICE 'Seed data loaded successfully!';
  RAISE NOTICE 'Sample protests created with IDs:';
  RAISE NOTICE '  - a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11 (Climate March NYC)';
  RAISE NOTICE '  - b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12 (Tech Workers Seattle)';
  RAISE NOTICE '  - c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13 (Housing LA)';
  RAISE NOTICE '  - d0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14 (Education Chicago)';
  RAISE NOTICE '  - e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a15 (Healthcare Austin)';
END
$$;