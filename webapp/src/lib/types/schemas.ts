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
  title: z.string().optional(),
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
  count_method: z.string().optional(),

  // Single submission type (changed from array)
  submission_type: z.string().min(1, 'Please select a submission type'),
  submission_type_other: z.string().optional(),
  referenced_protest_id: z.string().uuid().optional().nullable(),

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
  sources: z.string().min(1, 'Source(s) are required')
}).superRefine((data, ctx) => {
  // Validate reference requirement for corrections/updates
  // ID 2: "data correction"
  // ID 3: "updated or additional source for existing record"
  const needsReference = ['2', '3'].includes(data.submission_type);

  if (needsReference && !data.referenced_protest_id) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Please select the protest entry you are referencing',
      path: ['referenced_protest_id']
    });
  }

  // Validate "other" submission type
  if (data.submission_type === '0' && !data.submission_type_other?.trim()) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Please specify the submission type',
      path: ['submission_type_other']
    });
  }

  // Validation for in-person events
  if (!data.is_online) {
    // Count method is required for in-person events
    if (!data.count_method?.trim()) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Crowd counting method is required for in-person events',
        path: ['count_method']
      });
    }
    
    // Crowd size estimates are required for in-person events
    if (data.crowd_size_low === null || data.crowd_size_low === undefined) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Lower crowd size estimate is required for in-person events',
        path: ['crowd_size_low']
      });
    }
    
    if (data.crowd_size_high === null || data.crowd_size_high === undefined) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Higher crowd size estimate is required for in-person events',
        path: ['crowd_size_high']
      });
    }
  }
  
  // Future: Add other conditional validations here as needed
  // This keeps all complex validation logic in one organized place
});

// Infer the type from the schema for use in the component
export type ProtestFormSchema = z.infer<typeof protestFormSchema>;
