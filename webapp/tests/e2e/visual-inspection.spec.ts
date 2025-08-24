import { test, expect } from '@playwright/test';
import { ProtestFormPage } from './pages/protest-form.page';

test.describe('Visual Inspection Tests', () => {
  test.describe.configure({ mode: 'serial' });

  test('complete form submission with pauses for visual inspection', async ({ page }) => {
    // This test is designed to run with headed browser for visual inspection
    test.setTimeout(120000); // 2 minutes to allow for manual inspection
    
    const formPage = new ProtestFormPage(page);
    await formPage.goto();
    
    console.log('📝 Starting form fill...');
    
    // Fill basic information
    await formPage.fillBasicInfo('Seattle', 'WA', '2024-01-20');
    await page.waitForTimeout(500); // Small pause to see the fill
    
    // Select submission types (first is already checked, select second too)
    await formPage.selectSubmissionTypes([1]);
    await page.waitForTimeout(500);
    
    // Fill event type checkboxes
    const eventTypes = page.locator('text=Event Type').locator('..').locator('input[type="checkbox"]');
    if (await eventTypes.count() > 0) {
      await eventTypes.nth(0).check();
      await eventTypes.nth(2).check();
      await page.waitForTimeout(500);
    }
    
    // Fill organization
    await page.locator('input[name="organization_name"]').fill('Community Action Network');
    await page.waitForTimeout(500);
    
    // Select participant types
    const participantTypes = page.locator('text=Participant Types').locator('..').locator('input[type="checkbox"]');
    if (await participantTypes.count() > 0) {
      await participantTypes.nth(2).check(); // Community members
      await participantTypes.nth(11).check(); // Parents
      await page.waitForTimeout(500);
    }
    
    // Fill claims
    await formPage.fillClaims('Housing justice, Affordable housing for all families');
    await page.waitForTimeout(500);
    
    // Set as physical event and fill crowd details
    await formPage.setOnlineEvent(false);
    await formPage.fillCrowdSize('250', '350', 'Visual estimation from elevated position');
    await page.waitForTimeout(500);
    
    // Select some participant measures
    const participantMeasures = page.locator('text=Participant Measures').locator('..').locator('input[type="checkbox"]');
    if (await participantMeasures.count() > 0) {
      await participantMeasures.nth(2).check(); // Banners
      await participantMeasures.nth(6).check(); // Chanted
      await participantMeasures.nth(17).check(); // Signs
      await page.waitForTimeout(500);
    }
    
    // Select police measures
    const policeMeasures = page.locator('text=Police Measures').locator('..').locator('input[type="checkbox"]');
    if (await policeMeasures.count() > 0) {
      await policeMeasures.nth(0).check(); // Arrived on scene
      await policeMeasures.nth(5).check(); // Observed from a distance
      await page.waitForTimeout(500);
    }
    
    // Fill incidents (all "No" by default)
    await formPage.fillIncidents('Peaceful protest with no incidents reported');
    await page.waitForTimeout(500);
    
    // Select notes options
    const notesCheckboxes = page.locator('text=Notes').locator('..').locator('input[type="checkbox"]');
    if (await notesCheckboxes.count() > 0) {
      await notesCheckboxes.nth(13).check(); // Part of nat day of action
      await page.waitForTimeout(500);
    }
    
    // Fill sources
    await formPage.fillSources('https://localnews.com/protest-coverage\nhttps://twitter.com/protest-updates\nhttps://facebook.com/event-page');
    
    // Scroll to submit button
    await page.getByRole('button', { name: /submit/i }).scrollIntoViewIfNeeded();
    
    // PAUSE FOR VISUAL INSPECTION
    console.log('');
    console.log('========================================');
    console.log('🔍 VISUAL INSPECTION PAUSE');
    console.log('========================================');
    console.log('The form has been filled. Please review:');
    console.log('✓ Basic information (City, State, Date)');
    console.log('✓ Submission types');
    console.log('✓ Event types and organization');
    console.log('✓ Participant types');
    console.log('✓ Claims');
    console.log('✓ Crowd size and counting method');
    console.log('✓ Participant and police measures');
    console.log('✓ Incidents section');
    console.log('✓ Notes');
    console.log('✓ Sources');
    console.log('');
    console.log('⏸️  Pausing for 15 seconds...');
    console.log('   (Test will continue automatically)');
    console.log('========================================');
    console.log('');
    
    // Wait 15 seconds for visual inspection
    await page.waitForTimeout(15000);
    
    console.log('▶️  Continuing with form submission...');
    
    // Submit form
    await formPage.submitForm();
    
    // Wait for submission
    await formPage.waitForSubmission();
    
    // Check result
    if (page.url().includes('/success')) {
      console.log('✅ Form submitted successfully!');
      await expect(page).toHaveURL(/\/success/);
    } else {
      const hasErrors = await formPage.hasErrors();
      if (hasErrors) {
        console.log('❌ Form has validation errors');
        const errors = await formPage.getErrorMessages();
        console.log('Errors:', errors);
      }
    }
  });

  test('manual form inspection with step-by-step pauses', async ({ page }) => {
    test.setTimeout(300000); // 5 minutes for thorough inspection
    
    const formPage = new ProtestFormPage(page);
    await formPage.goto();
    
    // Helper function to pause with message
    const pauseWithMessage = async (message: string, duration: number = 5000) => {
      console.log(`\n⏸️  ${message}`);
      console.log(`   Pausing for ${duration/1000} seconds...`);
      await page.waitForTimeout(duration);
    };
    
    console.log('\n📋 STEP-BY-STEP FORM INSPECTION TEST');
    console.log('=====================================\n');
    
    // Step 1: Basic Info
    await pauseWithMessage('Step 1: Filling basic information...', 2000);
    await formPage.fillBasicInfo('New York', 'NY', '2024-12-15');
    await pauseWithMessage('Basic info filled - review City, State, Date', 5000);
    
    // Step 2: Submission Type
    await pauseWithMessage('Step 2: Selecting submission types...', 2000);
    const submissionCheckboxes = formPage.submissionTypeSection.locator('input[type="checkbox"]');
    await submissionCheckboxes.nth(1).check();
    await submissionCheckboxes.nth(2).check();
    await pauseWithMessage('Submission types selected - review checkboxes', 5000);
    
    // Step 3: Event Details
    await pauseWithMessage('Step 3: Filling event details...', 2000);
    await page.locator('input[name="title"]').fill('March for Climate Justice');
    await page.locator('input[name="location_name"]').fill('City Hall Plaza');
    await pauseWithMessage('Event details filled - review title and location', 5000);
    
    // Step 4: Claims
    await pauseWithMessage('Step 4: Adding claims...', 2000);
    await page.locator('textarea[name="claims_summary"]').fill('Climate action now! Green New Deal!');
    await page.locator('textarea[name="claims_verbatim"]').fill('"What do we want? Climate justice!"\n"When do we want it? Now!"');
    await pauseWithMessage('Claims added - review summary and verbatim', 5000);
    
    // Step 5: Crowd Size
    await pauseWithMessage('Step 5: Setting crowd size...', 2000);
    await formPage.setOnlineEvent(false);
    await formPage.fillCrowdSize('500', '750', 'Police estimate and organizer count averaged');
    await pauseWithMessage('Crowd size set - review numbers and method', 5000);
    
    // Step 6: Sources
    await pauseWithMessage('Step 6: Adding sources...', 2000);
    await formPage.fillSources('https://nytimes.com/article\nhttps://local-news.com/coverage');
    await pauseWithMessage('Sources added - review URLs', 5000);
    
    // Final review
    await page.getByRole('button', { name: /submit/i }).scrollIntoViewIfNeeded();
    console.log('\n========================================');
    console.log('🔍 FINAL REVIEW');
    console.log('========================================');
    console.log('Please scroll through the form and review all entries.');
    console.log('The test will pause for 20 seconds.');
    console.log('After the pause, the form will be submitted.');
    console.log('========================================\n');
    
    await page.waitForTimeout(20000);
    
    console.log('📤 Submitting form...');
    await formPage.submitForm();
    
    // Wait for result
    await formPage.waitForSubmission();
    
    if (page.url().includes('/success')) {
      console.log('✅ Success! Form submitted without errors.');
    } else {
      console.log('⚠️  Form did not redirect to success page.');
      const hasErrors = await formPage.hasErrors();
      if (hasErrors) {
        const errors = await formPage.getErrorMessages();
        console.log('Validation errors found:', errors);
      }
    }
  });
});