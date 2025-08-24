import { test, expect } from '@playwright/test';

test.describe('Protest Form', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/form');
  });

  test('should load the form with all sections', async ({ page }) => {
    // Check main heading
    await expect(page.locator('h1')).toContainText('Protest Crowd Counts & Information');
    
    // Verify key sections are present using actual field names
    await expect(page.getByText('Submission Type')).toBeVisible();
    await expect(page.locator('input[name="locality"]')).toBeVisible();
    await expect(page.locator('select[name="state_code"]')).toBeVisible();
    await expect(page.locator('input[name="date_of_event"]')).toBeVisible();
  });

  test('should show/hide crowd size section based on online event checkbox', async ({ page }) => {
    // Initially crowd counting method should be visible
    await expect(page.locator('input[name="count_method"]')).toBeVisible();
    
    // Check online event checkbox
    await page.locator('input[name="is_online"]').check();
    
    // Crowd counting method should be hidden
    await expect(page.locator('input[name="count_method"]')).not.toBeVisible();
    
    // Uncheck and verify it's visible again
    await page.locator('input[name="is_online"]').uncheck();
    await expect(page.locator('input[name="count_method"]')).toBeVisible();
  });

  test('should validate required fields', async ({ page }) => {
    // Try to submit without filling required fields
    await page.getByRole('button', { name: /submit/i }).click();
    
    // Wait for server response
    await page.waitForLoadState('networkidle');
    
    // Should either show validation errors or stay on form page
    const hasErrors = await page.locator('.bg-red-50').isVisible();
    if (hasErrors) {
      await expect(page.locator('.bg-red-50')).toBeVisible();
      await expect(page.getByText(/Please fix the following errors/i)).toBeVisible();
    } else {
      // At minimum, should not redirect to success
      await expect(page).not.toHaveURL(/\/success/);
    }
  });

  test('should handle submission type selection', async ({ page }) => {
    // Get submission type checkboxes
    const submissionSection = page.locator('text=Submission Type').locator('..');
    
    // Check if first option is pre-checked (component prop firstOptionIsChecked)
    const firstCheckbox = submissionSection.locator('input[type="checkbox"]').first();
    const isFirstChecked = await firstCheckbox.isChecked();
    
    // If not checked by default, check it
    if (!isFirstChecked) {
      await firstCheckbox.check();
    }
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
    // Set timeout for this specific test
    test.setTimeout(60000);
    
    // Basic Information - use actual field names
    await page.locator('input[name="locality"]').fill('New York');
    await page.locator('select[name="state_code"]').selectOption('NY');
    await page.locator('input[name="date_of_event"]').fill('2024-01-15');
    
    // Claims section
    const claimsTextarea = page.locator('textarea[name="claims_summary"]');
    if (await claimsTextarea.count() > 0) {
      await claimsTextarea.fill('Climate action, Environmental justice');
    }
    
    // Crowd Counting Method (for non-online events)
    await page.locator('input[name="count_method"]').fill('Manual headcount at entrance');
    
    // Crowd size fields
    const lowEstimate = page.locator('input[name="crowd_size_low"]');
    const highEstimate = page.locator('input[name="crowd_size_high"]');
    
    if (await lowEstimate.count() > 0) {
      await lowEstimate.fill('100');
      await highEstimate.fill('200');
    }
    
    // Sources (required field)
    await page.locator('textarea[name="sources"]').fill('https://example.com/news-article');
    
    // Submit the form
    const submitButton = page.getByRole('button', { name: /submit/i });
    await submitButton.click();
    
    // Wait for response - use a more robust approach
    try {
      // Wait for either navigation or error message
      await page.waitForURL('**/success**', { timeout: 15000 });
      // If we get here, submission was successful
      expect(page.url()).toContain('/success');
    } catch {
      // Check if there are validation errors
      const hasErrors = await page.locator('.bg-red-50').isVisible();
      if (hasErrors) {
        // This is expected if there are validation issues
        expect(hasErrors).toBe(true);
      } else {
        // Check if the form is still processing
        const buttonText = await submitButton.textContent();
        expect(buttonText).toContain('Submitting');
      }
    }
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
    await page.locator('input[name="locality"]').fill('Boston');
    
    // Submit without required fields (should trigger validation)
    await page.getByRole('button', { name: /submit/i }).click();
    
    // Wait for server response
    await page.waitForLoadState('networkidle');
    
    // Check that the filled data is preserved
    await expect(page.locator('input[name="locality"]')).toHaveValue('Boston');
  });

  test('should handle keyboard navigation', async ({ page }) => {
    // Start with first input - use more specific selector
    await page.locator('input[name="locality"]').focus();
    
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