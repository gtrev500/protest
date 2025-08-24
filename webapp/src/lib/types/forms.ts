// Form-related types that can be shared across components

export interface FormActionResult {
  errors?: Record<string, string | string[]>;
  message?: string;
  values?: Record<string, any>;
}

export interface ProtestFormProps {
  states?: any[];
  eventTypes?: any[];
  participantTypes?: any[];
  participantMeasures?: any[];
  policeMeasures?: any[];
  notesOptions?: any[];
  submissionTypes?: any[];
  form?: FormActionResult | null;
  enhance?: any;
}