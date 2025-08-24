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
    this.cityInput = page.getByLabel('City');
    this.stateSelect = page.getByLabel('State');
    this.dateInput = page.getByLabel('Date');
    this.onlineEventCheckbox = page.getByLabel('This was an online event');
    this.countMethodInput = page.getByLabel('Crowd Counting Method');
    this.sourcesTextarea = page.locator('textarea[name="sources"]');
    this.submitButton = page.getByRole('button', { name: /submit/i });
    this.errorContainer = page.locator('.bg-red-50');
    this.submissionTypeSection = page.locator('text=Submission Type').locator('..');
  }

  async goto() {
    await this.page.goto('/form');
  }

  async fillBasicInfo(city: string, stateIndex: number, date: string) {
    await this.cityInput.fill(city);
    await this.stateSelect.selectOption({ index: stateIndex });
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

  async fillCrowdSize(low: string, best: string, high: string, method?: string) {
    if (method) {
      await this.countMethodInput.fill(method);
    }

    const lowEstimate = this.page.locator('input[name="low_estimate"]');
    const bestEstimate = this.page.locator('input[name="best_estimate"]');
    const highEstimate = this.page.locator('input[name="high_estimate"]');

    if (await lowEstimate.count() > 0) {
      await lowEstimate.fill(low);
      await bestEstimate.fill(best);
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
    return await this.page.getByRole('button', { name: /submitting/i }).isVisible();
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