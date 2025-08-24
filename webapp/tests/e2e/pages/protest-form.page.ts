import { type Page, type Locator } from '@playwright/test';

export class ProtestFormPage {
  readonly page: Page;
  readonly cityInput: Locator;
  readonly stateSelect: Locator;
  readonly dateInput: Locator;
  readonly onlineEventCheckbox: Locator;
  readonly countMethodInput: Locator;
  readonly sourcesTextarea: Locator;
  readonly submitButton: Locator;
  readonly errorContainer: Locator;
  readonly submissionTypeSection: Locator;

  constructor(page: Page) {
    this.page = page;
    // Use the actual form field names from the schema
    this.cityInput = page.locator('input[name="locality"]');
    this.stateSelect = page.locator('select[name="state_code"]');
    this.dateInput = page.locator('input[name="date_of_event"]');
    this.onlineEventCheckbox = page.locator('input[name="is_online"]');
    this.countMethodInput = page.locator('input[name="count_method"]');
    this.sourcesTextarea = page.locator('textarea[name="sources"]');
    this.submitButton = page.getByRole('button', { name: /submit/i });
    this.errorContainer = page.locator('.bg-red-50');
    this.submissionTypeSection = page.locator('text=Submission Type').locator('..');
  }

  async goto() {
    await this.page.goto('/form');
  }

  async fillBasicInfo(city: string, stateValue: string, date: string) {
    await this.cityInput.fill(city);
    await this.stateSelect.selectOption(stateValue);
    await this.dateInput.fill(date);
  }

  async selectSubmissionTypes(indices: number[]) {
    const checkboxes = this.submissionTypeSection.locator('input[type="checkbox"]');
    for (const index of indices) {
      await checkboxes.nth(index).check();
    }
  }

  async fillEventDetails(eventType?: string, participantTypes?: string[]) {
    if (eventType) {
      const eventTypeSelect = this.page.locator('select[name="event_type"]');
      if (await eventTypeSelect.count() > 0) {
        await eventTypeSelect.selectOption(eventType);
      }
    }

    if (participantTypes && participantTypes.length > 0) {
      for (const type of participantTypes) {
        const checkbox = this.page.locator(`label:has-text("${type}")`).locator('input[type="checkbox"]');
        if (await checkbox.count() > 0) {
          await checkbox.check();
        }
      }
    }
  }

  async fillClaims(claims: string) {
    const claimsTextarea = this.page.locator('textarea[name="claims"]');
    if (await claimsTextarea.count() > 0) {
      await claimsTextarea.fill(claims);
    }
  }

  async setOnlineEvent(isOnline: boolean) {
    if (isOnline) {
      await this.onlineEventCheckbox.check();
    } else {
      await this.onlineEventCheckbox.uncheck();
    }
  }

  async fillCrowdSize(low: string, high: string, method?: string) {
    if (method) {
      await this.countMethodInput.fill(method);
    }

    const lowEstimate = this.page.locator('input[name="crowd_size_low"]');
    const highEstimate = this.page.locator('input[name="crowd_size_high"]');

    if (await lowEstimate.count() > 0) {
      await lowEstimate.fill(low);
      await highEstimate.fill(high);
    }
  }

  async selectMeasures(participantMeasures: string[], policeMeasures: string[]) {
    // Select participant measures
    for (const measure of participantMeasures) {
      const checkbox = this.page.locator(`label:has-text("${measure}")`).first();
      if (await checkbox.count() > 0) {
        await checkbox.click();
      }
    }

    // Select police measures
    for (const measure of policeMeasures) {
      const checkbox = this.page.locator(`label:has-text("${measure}")`).last();
      if (await checkbox.count() > 0) {
        await checkbox.click();
      }
    }
  }

  async fillIncidents(incidents: string) {
    const incidentsTextarea = this.page.locator('textarea[name="incidents"]');
    if (await incidentsTextarea.count() > 0) {
      await incidentsTextarea.fill(incidents);
    }
  }

  async selectNotes(notes: string[]) {
    for (const note of notes) {
      const checkbox = this.page.locator(`label:has-text("${note}")`);
      if (await checkbox.count() > 0) {
        await checkbox.click();
      }
    }
  }

  async fillSources(sources: string) {
    await this.sourcesTextarea.fill(sources);
  }

  async submitForm() {
    await this.submitButton.click();
  }

  async isSubmitting() {
    // Check if button text contains 'Submitting'
    const buttonText = await this.submitButton.textContent();
    return buttonText?.includes('Submitting') || false;
  }

  async waitForSubmission() {
    // Wait for either navigation to success page or error display
    await Promise.race([
      this.page.waitForURL('**/success**', { timeout: 10000 }),
      this.errorContainer.waitFor({ state: 'visible', timeout: 10000 })
    ]).catch(() => {});
  }

  async hasErrors() {
    return await this.errorContainer.isVisible();
  }

  async getErrorMessages() {
    const errors = await this.page.locator('.bg-red-50 li').allTextContents();
    return errors;
  }

  async fillOtherField(sectionName: string, text: string) {
    const section = this.page.locator(`text=${sectionName}`).locator('..');
    const otherCheckbox = section.locator('label:has-text("Other")');
    
    if (await otherCheckbox.count() > 0) {
      await otherCheckbox.click();
      const otherInput = otherCheckbox.locator('..').locator('input[type="text"]');
      await otherInput.fill(text);
    }
  }
}