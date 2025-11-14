// Condensed form data mapping using central configuration

import type { ProtestFormSchema } from '$lib/types/schemas';
import {
  INCIDENT_FIELDS,
  TEXT_FIELDS,
  MULTISELECT_WITH_OTHER,
  MULTISELECT_WITHOUT_OTHER,
  createDefaultFormData,
  type FormDataType,
  type OtherValuesType
} from '$lib/config/formFieldsConfig';

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
  claims_summary?: string;
  claims_verbatim?: string;
  is_online?: boolean;
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
  participant_types?: Array<{ participant_type_id: number; other_value?: string }>;
  participant_measures?: Array<{ measure_id: number; other_value?: string }>;
  police_measures?: Array<{ measure_id: number; other_value?: string }>;
  notes?: Array<{ note_id: number; other_value?: string }>;
  count_methods?: Array<{ count_method_id: number; other_value?: string }>;
}

// Simple, declarative helper functions for form data manipulation

/**
 * Condensed populate function using configuration patterns
 */
export function populateFormData(
  protest: ProtestApiResponse,
  formData: any,
  otherValues: OtherValuesType
) {
  // Handle all text fields in one go
  TEXT_FIELDS.forEach(field => {
    formData[field] = protest[field as keyof typeof protest] || '';
  });

  // Special fields
  formData.date_of_event = protest.date_of_event || '';
  formData.is_online = protest.is_online || false;
  formData.crowd_size_low = protest.crowd_size_low?.toString() || '';
  formData.crowd_size_high = protest.crowd_size_high?.toString() || '';

  // Handle all incident fields using the pattern
  INCIDENT_FIELDS.forEach(field => {
    formData[field] = protest[field as keyof typeof protest] || 'no';
    formData[`${field}_details`] = protest[`${field}_details` as keyof typeof protest] || '';
  });

  // Handle multiselects with "other" pattern
  const multiSelectMap = {
    event_types: { idField: 'event_type_id', otherField: 'eventTypeOthers' },
    participant_types: { idField: 'participant_type_id', otherField: 'participantTypeOthers' },
    participant_measures: { idField: 'measure_id', otherField: 'participantMeasureOthers' },
    police_measures: { idField: 'measure_id', otherField: 'policeMeasureOthers' },
    notes: { idField: 'note_id', otherField: 'notesOthers' },
    count_methods: { idField: 'count_method_id', otherField: 'countMethodOthers' }
  };

  Object.entries(multiSelectMap).forEach(([fieldName, config]) => {
    const data = protest[fieldName as keyof typeof protest] as any[];
    if (data) {
      formData[fieldName] = data
        .map(item => item[config.idField]?.toString())
        .filter(Boolean);

      const otherEntry = data.find(item => item[config.idField] === 0);
      const otherKey = config.otherField as keyof OtherValuesType;
      if (otherEntry?.other_value) {
        otherValues[otherKey][0] = otherEntry.other_value.replace(/^"|"$/g, '');
      } else {
        otherValues[otherKey][0] = '';
      }
    } else {
      formData[fieldName] = [];
      const otherKey = config.otherField as keyof OtherValuesType;
      otherValues[otherKey][0] = '';
    }
  });

  // Handle multiselects without "other" (if any)
  MULTISELECT_WITHOUT_OTHER.forEach((field: string) => {
    const data = (protest as any)[field] as any[];
    formData[field] = data
      ? data.map((item: any) => item[`${field.slice(0, -1)}_id`]?.toString()).filter(Boolean)
      : [];
  });
}

/**
 * Condensed clear function using configuration
 */
export function clearFormData(formData: any, otherValues: OtherValuesType) {
  // Use the default form data from configuration
  Object.assign(formData, createDefaultFormData());

  // Clear all "other" values
  Object.keys(otherValues).forEach(key => {
    otherValues[key as keyof OtherValuesType][0] = '';
  });
}