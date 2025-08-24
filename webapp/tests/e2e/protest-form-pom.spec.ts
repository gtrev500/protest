import { test, expect } from '@playwright/test';
import { ProtestFormPage } from './pages/protest-form.page';

test.describe('Protest Form - Page Object Model Tests', () => {
  let formPage: ProtestFormPage;

  test.beforeEach(async ({ page }) => {
    formPage = new ProtestFormPage(page);
    await formPage.goto();
  });

  test('complete form submission flow', async ({ page }) => {
    // Fill basic information - use state code value
    await formPage.fillBasicInfo('Seattle', 'WA', '2024-01-20');

    // The first submission type is already checked by default
    // Optionally select additional types
    await formPage.selectSubmissionTypes([1]);

    // Fill event details
    await formPage.fillClaims('Housing justice, Affordable housing now');

    // Set as physical event and fill crowd details
    await formPage.setOnlineEvent(false);
    await formPage.fillCrowdSize('250', '350', 'Visual estimation from elevated position');

    // Fill incidents
    await formPage.fillIncidents('Peaceful protest with no incidents');

    // Fill sources (required field)
    await formPage.fillSources('https://localnews.com/protest-coverage\nhttps://twitter.com/protest-updates');

    // Submit form
    await formPage.submitForm();

    // Wait for form submission to complete
    await formPage.waitForSubmission();

    // Check if we're redirected to success page
    await expect(page).toHaveURL(/\/success/);
  });

  test('validation error handling', async ({ page }) => {
    // Try to submit empty form
    await formPage.submitForm();

    // Wait for server response
    await page.waitForLoadState('networkidle');

    // Check for errors after server response
    const hasErrors = await formPage.hasErrors();
    
    if (hasErrors) {
      expect(hasErrors).toBe(true);
      
      // Get error messages
      const errors = await formPage.getErrorMessages();
      expect(errors.length).toBeGreaterThan(0);
    } else {
      // If no validation errors shown, check we're still on the form page
      // (not redirected to success)
      await expect(page).not.toHaveURL(/\/success/);
      
      // Check that required fields have the required attribute
      const requiredFieldsCount = await page.locator('[required]').count();
      expect(requiredFieldsCount).toBeGreaterThan(0);
    }
  });

  test('online event toggle', async () => {
    // Initially should show crowd counting method
    await expect(formPage.countMethodInput).toBeVisible();

    // Set as online event
    await formPage.setOnlineEvent(true);

    // Crowd counting should be hidden
    await expect(formPage.countMethodInput).not.toBeVisible();

    // Set back to physical event
    await formPage.setOnlineEvent(false);

    // Should be visible again
    await expect(formPage.countMethodInput).toBeVisible();
  });

  test('other field functionality', async () => {
    // Fill "Other" field in submission type
    await formPage.fillOtherField('Submission Type', 'Academic researcher');

    // Verify the text was entered
    const otherInput = formPage.page.locator('text=Submission Type').locator('..').locator('input[type="text"]');
    await expect(otherInput).toHaveValue('Academic researcher');
  });
});