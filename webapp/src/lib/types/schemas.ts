import { z } from 'zod';

// Schema for incident status fields
export const incidentStatusSchema = z.enum(['yes', 'no']);

// Main form schema
export const protestFormSchema = z.object({
  // Basic info
  date_of_event: z.string().min(1, 'Date is required'),
  locality: z.string().min(1, 'City is required'),
  state_code: z.string().min(1, 'State is required'),
  location_name: z.string().optional(),
  title: z.string().min(1, 'Event title is required'),
  organization_name: z.string().optional(),
  notable_participants: z.string().optional(),
  targets: z.string().optional(),
  claims_summary: z.string().optional(),
  claims_verbatim: z.string().optional(),
  macroevent: z.string().optional(),
  is_online: z.boolean(),
  
  // Crowd size - using nullable to handle empty inputs, which Felte treats as undefined
  crowd_size_low: z.number().int().min(0).optional().nullable(),
  crowd_size_high: z.number().int().min(0).optional().nullable(),
  
  // Multi-select arrays (ids are stringified numbers; 0 represents "Other")
  event_types: z.array(z.string()).default([]),
  participant_types: z.array(z.string()).default([]),
  participant_measures: z.array(z.string()).default([]),
  police_measures: z.array(z.string()).default([]),
  notes: z.array(z.string()).default([]),
  
  // Incident fields
  participant_injury: incidentStatusSchema.default('no'),
  participant_injury_details: z.string().optional(),
  police_injury: incidentStatusSchema.default('no'),
  police_injury_details: z.string().optional(),
  arrests: incidentStatusSchema.default('no'),
  arrests_details: z.string().optional(),
  property_damage: incidentStatusSchema.default('no'),
  property_damage_details: z.string().optional(),
  participant_casualties: incidentStatusSchema.default('no'),
  participant_casualties_details: z.string().optional(),
  police_casualties: incidentStatusSchema.default('no'),
  police_casualties_details: z.string().optional(),
  
  // Sources
  sources: z.string().optional()
});

// Infer the type from the schema for use in the component
export type ProtestFormSchema = z.infer<typeof protestFormSchema>;
