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
  'macroevent',
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

// Field metadata for UI generation (optional future use)
export const FIELD_LABELS = {
  // Basic info
  date_of_event: 'Date of Event',
  locality: 'City',
  state_code: 'State',
  location_name: 'Location Name',
  title: 'Event Title',

  // Event details
  organization_name: 'Organization Name',
  notable_participants: 'Notable Participants',
  targets: 'Target(s) or Focal Point(s)',
  macroevent: 'Macroevent',

  // Claims
  claims_summary: 'Claims Summary',
  claims_verbatim: 'Claims Verbatim',

  // Crowd
  is_online: 'Online Event',
  count_method: 'Crowd Counting Method',
  crowd_size_low: 'Crowd Size (Low Estimate)',
  crowd_size_high: 'Crowd Size (High Estimate)',

  // Sources
  sources: 'Sources',

  // Incidents
  participant_injury: 'Participant Injuries',
  police_injury: 'Police Injuries',
  arrests: 'Arrests',
  property_damage: 'Property Damage',
  participant_casualties: 'Participant Casualties',
  police_casualties: 'Police Casualties',

  // Multiselects
  event_types: 'Event Types',
  participant_types: 'Participant Types',
  participant_measures: 'Participant Measures',
  police_measures: 'Police Measures',
  notes: 'Notes'
} as const;

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