# Test Verification Guide

This guide provides instructions for running the Playwright E2E tests and verifying that form submissions are correctly saved to the Supabase database.

## Running the Tests

### Available Test Commands

Run these commands from the project root directory (`/home/clu/projects/webapp`):

#### 1. **Run All Tests (Headless)**
```bash
npm run test:e2e
```
Runs all tests in headless mode. Fast and suitable for CI/CD.

#### 2. **Interactive UI Mode**
```bash
npm run test:e2e:ui
```
Opens Playwright's UI where you can run, debug, and watch tests interactively.

#### 3. **Debug Mode**
```bash
npm run test:e2e:debug
```
Runs tests with the Playwright Inspector for step-by-step debugging.

#### 4. **Headed Browser Mode**
```bash
npm run test:e2e:headed
```
Runs all tests with a visible browser window.

#### 5. **Visual Inspection Mode (15-second pause)**
```bash
npm run test:e2e:inspect
```
- Opens a visible browser
- Fills the entire form with test data
- **Pauses for 15 seconds** before submission
- Allows you to visually verify all fields are filled correctly
- Automatically continues after the pause

#### 6. **Step-by-Step Inspection Mode**
```bash
npm run test:e2e:step
```
- Opens a visible browser
- Fills the form section by section
- **Pauses 5 seconds after each section**
- Provides console messages about what to check
- **20-second final review** before submission
- Total runtime: ~2 minutes

### Running Specific Tests

To run a single test file:
```bash
npx playwright test tests/e2e/protest-form.spec.ts
```

To run tests matching a pattern:
```bash
npx playwright test --grep "validation"
```

## Verifying Database Insertions

After running the tests, verify that data was correctly saved to Supabase.

### Step 1: Access Supabase SQL Editor

1. Log into your Supabase dashboard
2. Navigate to your project
3. Click **"SQL Editor"** in the left sidebar
4. Create a new query

### Step 2: Run the Verification Query

Copy and paste this complete SQL query into the Supabase SQL Editor:

```sql
SELECT 
    p.id, 
    p.locality, 
    p.state_code, 
    p.date_of_event, 
    p.title, 
    p.organization_name, 
    p.location_name, 
    p.claims_summary, 
    p.claims_verbatim, 
    p.crowd_size_low, 
    p.crowd_size_high, 
    p.count_method, 
    p.is_online, 
    p.sources, 
    p.participant_injury, 
    p.police_injury, 
    p.arrests, 
    p.property_damage, 
    p.participant_casualties, 
    p.police_casualties, 
    p.created_at, 
    STRING_AGG(DISTINCT st.name, ', ') as submission_types, 
    STRING_AGG(DISTINCT et.name, ', ') as event_types, 
    STRING_AGG(DISTINCT pt.name, ', ') as participant_types, 
    STRING_AGG(DISTINCT pm.name, ', ') as participant_measures, 
    STRING_AGG(DISTINCT polm.name, ', ') as police_measures, 
    STRING_AGG(DISTINCT no.name, ', ') as notes 
FROM protests p 
LEFT JOIN protest_submission_types pst ON p.id = pst.protest_id 
LEFT JOIN submission_types st ON pst.submission_type_id = st.id 
LEFT JOIN protest_event_types pet ON p.id = pet.protest_id 
LEFT JOIN event_types et ON pet.event_type_id = et.id 
LEFT JOIN protest_participant_types ppt ON p.id = ppt.protest_id 
LEFT JOIN participant_types pt ON ppt.participant_type_id = pt.id 
LEFT JOIN protest_participant_measures ppm ON p.id = ppm.protest_id 
LEFT JOIN participant_measures pm ON ppm.measure_id = pm.id 
LEFT JOIN protest_police_measures ppolm ON p.id = ppolm.protest_id 
LEFT JOIN police_measures polm ON ppolm.measure_id = polm.id 
LEFT JOIN protest_notes pn ON p.id = pn.protest_id 
LEFT JOIN notes_options no ON pn.note_id = no.id 
WHERE 
    (p.locality = 'Seattle' AND p.state_code = 'WA' AND p.date_of_event = '2024-01-20') OR 
    (p.locality = 'New York' AND p.state_code = 'NY' AND p.date_of_event = '2024-12-15') OR 
    p.created_at > NOW() - INTERVAL '1 hour' 
GROUP BY 
    p.id, p.locality, p.state_code, p.date_of_event, p.title, p.organization_name, 
    p.location_name, p.claims_summary, p.claims_verbatim, p.crowd_size_low, 
    p.crowd_size_high, p.count_method, p.is_online, p.sources, p.participant_injury, 
    p.police_injury, p.arrests, p.property_damage, p.participant_casualties, 
    p.police_casualties, p.created_at 
ORDER BY p.created_at DESC;
```

### Step 3: Verify the Results

The query will return all test protests. Look for:

#### Expected Test Data from Visual Inspection Test:
- **Location:** Seattle, WA
- **Date:** 2024-01-20
- **Organization:** Community Action Network
- **Crowd Size:** 250-350
- **Counting Method:** Visual estimation from elevated position
- **Sources:** Multiple URLs including localnews.com, twitter.com, facebook.com

#### Expected Many-to-Many Relationships:
- **Submission Types:** Should include "new record" and/or "data correction"
- **Event Types:** "Banner Drop", "Boat parade"
- **Participant Types:** "Community members", "Parents"
- **Participant Measures:** "Banners", "Chanted", "Signs"
- **Police Measures:** "arrived on scene", "observed from a distance"
- **Notes:** "Part of a nat day of action"

### Alternative Queries

#### Get Only the Most Recent Test Submission:
```sql
SELECT * FROM protests 
WHERE locality IN ('Seattle', 'New York') 
ORDER BY created_at DESC 
LIMIT 1;
```

#### Count Total Test Submissions Today:
```sql
SELECT COUNT(*) as total_today 
FROM protests 
WHERE created_at > CURRENT_DATE;
```

#### Check for Failed Submissions (with errors):
```sql
SELECT * FROM protests 
WHERE sources IS NULL 
   OR locality IS NULL 
   OR state_code IS NULL 
   OR date_of_event IS NULL 
ORDER BY created_at DESC;
```

## Troubleshooting

### If Tests Fail

1. **Check the test report:**
   ```bash
   npx playwright show-report
   ```

2. **Run a specific failing test in debug mode:**
   ```bash
   npx playwright test --debug --grep "test name"
   ```

3. **Check screenshots of failures:**
   - Located in `test-results/` directory
   - Each failed test has a screenshot showing the state at failure

### If Data Isn't in Database

1. **Check Supabase logs:**
   - Go to Supabase Dashboard → Logs → API logs
   - Look for any RPC errors for `submit_protest`

2. **Verify the dev server is running:**
   ```bash
   npm run dev
   ```

3. **Check network requests in test:**
   ```bash
   npm run test:e2e:ui
   ```
   Use the UI mode to inspect network activity during form submission

## Test Data Cleanup (Optional)

To remove test data after verification:

```sql
-- Delete test protests (be careful!)
DELETE FROM protests 
WHERE locality IN ('Seattle', 'New York') 
  AND date_of_event IN ('2024-01-20', '2024-12-15')
  AND organization_name = 'Community Action Network';
```

**Warning:** Only run cleanup in development/test environments, never in production!

## Summary

1. Run tests using the npm commands above
2. Copy the main verification SQL query into Supabase SQL Editor
3. Verify that all fields and relationships are correctly saved
4. Use the visual inspection modes to debug any issues with form filling

The complete test suite ensures:
- All form fields are properly filled
- Validation works correctly
- Data is successfully submitted to Supabase
- All many-to-many relationships are preserved
- The form handles both online and in-person events correctly