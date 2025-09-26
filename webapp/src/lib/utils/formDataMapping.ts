// Simple, declarative field mapping for form autofill
// Uses existing types from schemas.ts to avoid duplication

import type { ProtestFormSchema } from '$lib/types/schemas';

// Type for what we get back from the API when fetching a protest
// This extends the form schema but has some differences in data types
export interface ProtestApiResponse {
  // All the same fields as the form, but:
  // - crowd sizes come as numbers from the database
  // - junction tables come with full relationship data

  // Basic fields (same as form)
  date_of_event?: string;
  locality?: string;
  state_code?: string;
  location_name?: string;
  title?: string;
  organization_name?: string;
  notable_participants?: string;
  targets?: string;
  macroevent?: string;
  claims_summary?: string;
  claims_verbatim?: string;
  is_online?: boolean;
  count_method?: string;
  sources?: string;

  // Crowd sizes are numbers from API
  crowd_size_low?: number;
  crowd_size_high?: number;

  // Incident fields (same as form)
  participant_injury?: 'yes' | 'no' | 'unknown';
  participant_injury_details?: string;
  police_injury?: 'yes' | 'no' | 'unknown';
  police_injury_details?: string;
  arrests?: 'yes' | 'no' | 'unknown';
  arrests_details?: string;
  property_damage?: 'yes' | 'no' | 'unknown';
  property_damage_details?: string;
  participant_casualties?: 'yes' | 'no' | 'unknown';
  participant_casualties_details?: string;
  police_casualties?: 'yes' | 'no' | 'unknown';
  police_casualties_details?: string;

  // Junction tables with full data
  event_types?: Array<{ event_type_id: number; other_value?: string }>;
  participant_types?: Array<{ participant_type_id: number }>;
  participant_measures?: Array<{ measure_id: number; other_value?: string }>;
  police_measures?: Array<{ measure_id: number; other_value?: string }>;
  notes?: Array<{ note_id: number; other_value?: string }>;
}

// Simple, declarative helper functions for form data manipulation

/**
 * Populates form data from an API response
 * Handles all field mappings and transformations in a straightforward way
 */
export function populateFormData(
  protest: ProtestApiResponse,
  formData: any, // Using any here because Svelte's $state doesn't preserve types well
  otherValues: any
) {
  // Copy simple text fields directly
  formData.date_of_event = protest.date_of_event || '';
  formData.locality = protest.locality || '';
  formData.state_code = protest.state_code || '';
  formData.location_name = protest.location_name || '';
  formData.title = protest.title || '';
  formData.organization_name = protest.organization_name || '';
  formData.notable_participants = protest.notable_participants || '';
  formData.targets = protest.targets || '';
  formData.macroevent = protest.macroevent || '';
  formData.claims_summary = protest.claims_summary || '';
  formData.claims_verbatim = protest.claims_verbatim || '';
  formData.sources = protest.sources || '';
  formData.count_method = protest.count_method || '';

  // Boolean field
  formData.is_online = protest.is_online || false;

  // Convert numeric crowd sizes to strings for form inputs
  formData.crowd_size_low = protest.crowd_size_low?.toString() || '';
  formData.crowd_size_high = protest.crowd_size_high?.toString() || '';

  // Incident fields with defaults
  formData.participant_injury = protest.participant_injury || 'no';
  formData.participant_injury_details = protest.participant_injury_details || '';
  formData.police_injury = protest.police_injury || 'no';
  formData.police_injury_details = protest.police_injury_details || '';
  formData.arrests = protest.arrests || 'no';
  formData.arrests_details = protest.arrests_details || '';
  formData.property_damage = protest.property_damage || 'no';
  formData.property_damage_details = protest.property_damage_details || '';
  formData.participant_casualties = protest.participant_casualties || 'no';
  formData.participant_casualties_details = protest.participant_casualties_details || '';
  formData.police_casualties = protest.police_casualties || 'no';
  formData.police_casualties_details = protest.police_casualties_details || '';

  // Handle event types
  if (protest.event_types) {
    formData.event_types = protest.event_types
      .map(e => e.event_type_id?.toString())
      .filter(Boolean);

    const eventTypeOther = protest.event_types.find(e => e.event_type_id === 0);
    if (eventTypeOther?.other_value) {
      otherValues.eventTypeOthers[0] = eventTypeOther.other_value.replace(/^"|"$/g, '');
    } else {
      otherValues.eventTypeOthers[0] = '';
    }
  } else {
    formData.event_types = [];
    otherValues.eventTypeOthers[0] = '';
  }

  // Handle participant types (no "other" field)
  if (protest.participant_types) {
    formData.participant_types = protest.participant_types
      .map(p => p.participant_type_id?.toString())
      .filter(Boolean);
  } else {
    formData.participant_types = [];
  }

  // Handle participant measures
  if (protest.participant_measures) {
    formData.participant_measures = protest.participant_measures
      .map(m => m.measure_id?.toString())
      .filter(Boolean);

    const participantMeasureOther = protest.participant_measures.find(m => m.measure_id === 0);
    if (participantMeasureOther?.other_value) {
      otherValues.participantMeasureOthers[0] = participantMeasureOther.other_value;
    } else {
      otherValues.participantMeasureOthers[0] = '';
    }
  } else {
    formData.participant_measures = [];
    otherValues.participantMeasureOthers[0] = '';
  }

  // Handle police measures
  if (protest.police_measures) {
    formData.police_measures = protest.police_measures
      .map(m => m.measure_id?.toString())
      .filter(Boolean);

    const policeMeasureOther = protest.police_measures.find(m => m.measure_id === 0);
    if (policeMeasureOther?.other_value) {
      otherValues.policeMeasureOthers[0] = policeMeasureOther.other_value;
    } else {
      otherValues.policeMeasureOthers[0] = '';
    }
  } else {
    formData.police_measures = [];
    otherValues.policeMeasureOthers[0] = '';
  }

  // Handle notes
  if (protest.notes) {
    formData.notes = protest.notes
      .map(n => n.note_id?.toString())
      .filter(Boolean);

    const noteOther = protest.notes.find(n => n.note_id === 0);
    if (noteOther?.other_value) {
      otherValues.notesOthers[0] = noteOther.other_value;
    } else {
      otherValues.notesOthers[0] = '';
    }
  } else {
    formData.notes = [];
    otherValues.notesOthers[0] = '';
  }
}

/**
 * Clears all form data to default/empty values
 */
export function clearFormData(formData: any, otherValues: any) {
  // Clear text fields
  formData.date_of_event = '';
  formData.locality = '';
  formData.state_code = '';
  formData.location_name = '';
  formData.title = '';
  formData.organization_name = '';
  formData.notable_participants = '';
  formData.targets = '';
  formData.macroevent = '';
  formData.claims_summary = '';
  formData.claims_verbatim = '';
  formData.sources = '';
  formData.count_method = '';
  formData.crowd_size_low = '';
  formData.crowd_size_high = '';

  // Clear boolean
  formData.is_online = false;

  // Clear incident fields to 'no'
  formData.participant_injury = 'no';
  formData.participant_injury_details = '';
  formData.police_injury = 'no';
  formData.police_injury_details = '';
  formData.arrests = 'no';
  formData.arrests_details = '';
  formData.property_damage = 'no';
  formData.property_damage_details = '';
  formData.participant_casualties = 'no';
  formData.participant_casualties_details = '';
  formData.police_casualties = 'no';
  formData.police_casualties_details = '';

  // Clear arrays
  formData.event_types = [];
  formData.participant_types = [];
  formData.participant_measures = [];
  formData.police_measures = [];
  formData.notes = [];

  // Clear "other" values
  otherValues.eventTypeOthers[0] = '';
  otherValues.participantMeasureOthers[0] = '';
  otherValues.policeMeasureOthers[0] = '';
  otherValues.notesOthers[0] = '';
}