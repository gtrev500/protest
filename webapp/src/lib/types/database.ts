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
export type EventType = LookupOption;
export type ParticipantType = LookupOption;
export type ParticipantMeasure = LookupOption;
export type PoliceMeasure = LookupOption;
export type NotesOption = LookupOption;