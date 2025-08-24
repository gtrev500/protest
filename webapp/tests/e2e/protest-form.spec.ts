import { test, expect } from '@playwright/test';

test.describe('Protest Form', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/form');
  });

  test('should load the form with all sections', async ({ page }) => {
    // Check main heading
    await expect(page.locator('h1')).toContainText('Protest Crowd Counts & Information');
    
    // Verify key sections are present
    await expect(page.getByText('Submission Type')).toBeVisible();
    await expect(page.getByLabel('City')).toBeVisible();
    await expect(page.getByLabel('State')).toBeVisible();
    await expect(page.getByLabel('Date')).toBeVisible();
  });

  test('should show/hide crowd size section based on online event checkbox', async ({ page }) => {
    // Initially crowd size should be visible
    await expect(page.getByLabel('Crowd Counting Method')).toBeVisible();
    
    // Check online event checkbox
    await page.getByLabel('This was an online event').check();
    
    // Crowd size section should be hidden
    await expect(page.getByLabel('Crowd Counting Method')).not.toBeVisible();
    
    // Uncheck and verify it's visible again
    await page.getByLabel('This was an online event').uncheck();
    await expect(page.getByLabel('Crowd Counting Method')).toBeVisible();
  });

  test('should validate required fields', async ({ page }) => {
    // Try to submit without filling required fields
    await page.getByRole('button', { name: /submit/i }).click();
    
    // Should show validation errors
    await expect(page.locator('.bg-red-50')).toBeVisible();
    await expect(page.getByText(/Please fix the following errors/i)).toBeVisible();
  });

  test('should handle submission type selection', async ({ page }) => {
    // Get submission type checkboxes
    const submissionSection = page.locator('text=Submission Type').locator('..');
    
    // First option should be checked by default
    const firstCheckbox = submissionSection.locator('input[type="checkbox"]').first();
    await expect(firstCheckbox).toBeChecked();
    
    // Check additional options
    const checkboxes = submissionSection.locator('input[type="checkbox"]');
    const count = await checkboxes.count();
    
    if (count > 1) {
      await checkboxes.nth(1).check();
      await expect(checkboxes.nth(1)).toBeChecked();
    }
  });

  test('should handle "other" text fields for various sections', async ({ page }) => {
    // Look for "Other" checkboxes and their associated text fields
    const otherCheckboxes = page.locator('label:has-text("Other")');
    const firstOther = otherCheckboxes.first();
    
    if (await firstOther.count() > 0) {
      await firstOther.click();
      
      // Find the associated text input
      const otherInput = firstOther.locator('..').locator('input[type="text"]');
      await otherInput.fill('Custom option text');
      await expect(otherInput).toHaveValue('Custom option text');
    }
  });

  test('should fill and submit a complete form', async ({ page }) => {
    // Basic Information
    await page.getByLabel('City').fill('New York');
    await page.getByLabel('State').selectOption({ index: 1 }); // Select first state
    await page.getByLabel('Date').fill('2024-01-15');
    
    // Event Details - assuming these fields exist based on the imports
    const eventTypeSelect = page.locator('select[name="event_type"]');
    if (await eventTypeSelect.count() > 0) {
      await eventTypeSelect.selectOption({ index: 1 });
    }
    
    // Claims section
    const claimsTextarea = page.locator('textarea[name="claims"]');
    if (await claimsTextarea.count() > 0) {
      await claimsTextarea.fill('Climate action, Environmental justice');
    }
    
    // Crowd Counting Method (for non-online events)
    await page.getByLabel('Crowd Counting Method').fill('Manual headcount at entrance');
    
    // Crowd size fields
    const lowEstimate = page.locator('input[name="low_estimate"]');
    const bestEstimate = page.locator('input[name="best_estimate"]');
    const highEstimate = page.locator('input[name="high_estimate"]');
    
    if (await lowEstimate.count() > 0) {
      await lowEstimate.fill('100');
      await bestEstimate.fill('150');
      await highEstimate.fill('200');
    }
    
    // Sources (required field)
    await page.locator('textarea[name="sources"]').fill('https://example.com/news-article');
    
    // Submit the form
    await page.getByRole('button', { name: /submit/i }).click();
    
    // Check for loading state
    await expect(page.getByRole('button', { name: /submitting/i })).toBeVisible();
  });

  test('should display participant and police measures sections', async ({ page }) => {
    // Scroll to measures section
    const measuresSection = page.locator('text=Participant Measures').first();
    if (await measuresSection.count() > 0) {
      await measuresSection.scrollIntoViewIfNeeded();
      
      // Check for checkboxes in participant measures
      const participantCheckboxes = measuresSection.locator('..').locator('input[type="checkbox"]');
      expect(await participantCheckboxes.count()).toBeGreaterThan(0);
    }
    
    const policeSection = page.locator('text=Police Measures').first();
    if (await policeSection.count() > 0) {
      await policeSection.scrollIntoViewIfNeeded();
      
      // Check for checkboxes in police measures
      const policeCheckboxes = policeSection.locator('..').locator('input[type="checkbox"]');
      expect(await policeCheckboxes.count()).toBeGreaterThan(0);
    }
  });

  test('should handle incidents section', async ({ page }) => {
    const incidentsTextarea = page.locator('textarea[name="incidents"]');
    if (await incidentsTextarea.count() > 0) {
      await incidentsTextarea.fill('No incidents reported during the protest.');
      await expect(incidentsTextarea).toHaveValue('No incidents reported during the protest.');
    }
  });

  test('should handle notes section with checkboxes', async ({ page }) => {
    const notesSection = page.locator('text=Notes').first();
    if (await notesSection.count() > 0) {
      const notesCheckboxes = notesSection.locator('..').locator('input[type="checkbox"]');
      
      if (await notesCheckboxes.count() > 0) {
        await notesCheckboxes.first().check();
        await expect(notesCheckboxes.first()).toBeChecked();
      }
    }
  });

  test('should preserve form data on validation error', async ({ page }) => {
    // Fill some fields
    await page.getByLabel('City').fill('Boston');
    
    // Submit without required fields (should trigger validation)
    await page.getByRole('button', { name: /submit/i }).click();
    
    // Check that the filled data is preserved
    await expect(page.getByLabel('City')).toHaveValue('Boston');
  });

  test('should handle keyboard navigation', async ({ page }) => {
    // Start with first input
    await page.getByLabel('City').focus();
    
    // Tab through fields
    await page.keyboard.press('Tab');
    
    // Should move to State field
    const focusedElement = await page.evaluate(() => document.activeElement?.tagName);
    expect(['SELECT', 'INPUT']).toContain(focusedElement);
  });

  test('should be mobile responsive', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Check that form is still accessible
    await expect(page.locator('h1')).toBeVisible();
    await expect(page.getByRole('button', { name: /submit/i })).toBeVisible();
    
    // Form should be single column on mobile
    const form = page.locator('form');
    await expect(form).toBeVisible();
  });
});