// Database table types for Supabase

export interface State {
  code: string;
  name: string;
}

export interface LookupOption {
  id: number;
  name: string;
}

// Specific type aliases for clarity
export type SubmissionType = LookupOption;
export type EventType = LookupOption;
export type ParticipantType = LookupOption;
export type ParticipantMeasure = LookupOption;
export type PoliceMeasure = LookupOption;
export type NotesOption = LookupOption;
export type CountMethod = LookupOption;

// Form types
export type IncidentStatus = 'yes' | 'no';

// Data structure for Supabase submission
// This represents the protest data as stored in the database
export interface ProtestData {
  date_of_event: string;
  locality: string;
  state_code: string;
  location_name?: string;
  title: string;
  organization_name?: string;
  notable_participants?: string;
  targets?: string;
  claims_summary?: string;
  claims_verbatim?: string;
  is_online: boolean;
  crowd_size_low: number | null;
  crowd_size_high: number | null;
  participant_injury: IncidentStatus;
  participant_injury_details?: string;
  police_injury: IncidentStatus;
  police_injury_details?: string;
  arrests: IncidentStatus;
  arrests_details?: string;
  property_damage: IncidentStatus;
  property_damage_details?: string;
  participant_casualties: IncidentStatus;
  participant_casualties_details?: string;
  police_casualties: IncidentStatus;
  police_casualties_details?: string;
  sources?: string;
}

// Junction table data types
export interface JunctionOption {
  id: number | null;
  other?: string | null;
}