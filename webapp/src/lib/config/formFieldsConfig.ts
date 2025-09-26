/**
 * Single source of truth for all form fields
 * This configuration generates types, schemas, and form helpers
 */

// Field type patterns
export const INCIDENT_FIELDS = [
  'participant_injury',
  'police_injury',
  'arrests',
  'property_damage',
  'participant_casualties',
  'police_casualties'
] as const;

export const MULTISELECT_WITH_OTHER = [
  'event_types',
  'participant_measures',
  'police_measures',
  'notes'
] as const;

export const MULTISELECT_WITHOUT_OTHER = [
  'participant_types'
] as const;

// Simple text fields
export const TEXT_FIELDS = [
  'locality',
  'state_code',
  'location_name',
  'title',
  'organization_name',
  'notable_participants',
  'targets',
  'claims_summary',
  'claims_verbatim',
  'count_method',
  'sources'
] as const;

// Special fields
export const SPECIAL_FIELDS = {
  date_of_event: 'date',
  is_online: 'boolean',
  crowd_size_low: 'number_string',
  crowd_size_high: 'number_string'
} as const;

// Type generation
export type IncidentField = typeof INCIDENT_FIELDS[number];
export type MultiselectField = typeof MULTISELECT_WITH_OTHER[number] | typeof MULTISELECT_WITHOUT_OTHER[number];
export type TextField = typeof TEXT_FIELDS[number];

// Generate incident field types
export type IncidentFieldsType = {
  [K in IncidentField]: 'yes' | 'no';
} & {
  [K in `${IncidentField}_details`]: string;
};

// Generate multiselect field types
export type MultiselectFieldsType = {
  [K in MultiselectField]: string[];
};

// Generate text field types
export type TextFieldsType = {
  [K in TextField]: string;
};

// Combined form data type
export interface FormDataType extends
  IncidentFieldsType,
  MultiselectFieldsType,
  TextFieldsType {
  date_of_event: string;
  is_online: boolean;
  crowd_size_low: string;
  crowd_size_high: string;
}

// Other values type for multiselects with "other" option
export type OtherValuesType = {
  eventTypeOthers: Record<number, string>;
  participantMeasureOthers: Record<number, string>;
  policeMeasureOthers: Record<number, string>;
  notesOthers: Record<number, string>;
};

// Helper to create default form data
export function createDefaultFormData(): FormDataType {
  const data: any = {};

  // Text fields default to empty string
  TEXT_FIELDS.forEach(field => {
    data[field] = '';
  });

  // Special fields
  data.date_of_event = '';
  data.is_online = false;
  data.crowd_size_low = '';
  data.crowd_size_high = '';

  // Incident fields default to 'no' with empty details
  INCIDENT_FIELDS.forEach(field => {
    data[field] = 'no';
    data[`${field}_details`] = '';
  });

  // Multiselect fields default to empty arrays
  [...MULTISELECT_WITH_OTHER, ...MULTISELECT_WITHOUT_OTHER].forEach(field => {
    data[field] = [];
  });

  return data;
}

// Helper to create default other values
export function createDefaultOtherValues(): OtherValuesType {
  return {
    eventTypeOthers: { 0: '' },
    participantMeasureOthers: { 0: '' },
    policeMeasureOthers: { 0: '' },
    notesOthers: { 0: '' }
  };
}


// Required fields for validation
export const REQUIRED_FIELDS = [
  'date_of_event',
  'locality',
  'state_code',
  'sources'
] as const;

// Conditional required fields
export const CONDITIONAL_REQUIRED = {
  inPerson: ['count_method', 'crowd_size_low', 'crowd_size_high']
} as const;