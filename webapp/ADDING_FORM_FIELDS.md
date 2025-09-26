# Guide: Adding New Fields to the Protest Form

## Current Process (Too Complex!)

When adding a new field, you currently need to update **8-10 different files**:

### 1. Database Schema
```sql
-- In migrations/*.sql
ALTER TABLE protests ADD COLUMN your_new_field TEXT;
```

### 2. Database Types
```typescript
// src/lib/types/database.ts
export interface ProtestData {
  // ... existing fields
  your_new_field?: string;
}
```

### 3. Form Validation Schema
```typescript
// src/lib/types/schemas.ts
export const protestFormSchema = z.object({
  // ... existing fields
  your_new_field: z.string().optional()
});
```

### 4. Form State
```typescript
// src/lib/components/ProtestForm.svelte
let formData = $state({
  // ... existing fields
  your_new_field: ''
});
```

### 5. Form Data Mapping (Populate)
```typescript
// src/lib/utils/formDataMapping.ts - populateFormData()
formData.your_new_field = protest.your_new_field || '';
```

### 6. Form Data Mapping (Clear)
```typescript
// src/lib/utils/formDataMapping.ts - clearFormData()
formData.your_new_field = '';
```

### 7. Form Data Mapping (API Response Type)
```typescript
// src/lib/utils/formDataMapping.ts - ProtestApiResponse
your_new_field?: string;
```

### 8. Form Preparation
```typescript
// src/lib/utils/formDataPreparation.ts
your_new_field: values.your_new_field,
```

### 9. Database Function
```sql
-- In submit_protest function
your_new_field text DEFAULT NULL
```

### 10. UI Component
```svelte
<!-- In appropriate form section -->
<TextField
  name="your_new_field"
  label="Your New Field"
  bind:value={formData.your_new_field}
/>
```

## The Problem

This violates DRY and makes the codebase fragile. A single field addition shouldn't require 10 file changes!

## Proposed Solution: Single Source of Truth

### Option 1: Schema-First Approach
Use the Zod schema as the single source of truth and derive everything else:

```typescript
// src/lib/types/schemas.ts becomes the ONLY place to define fields
export const protestFormSchema = z.object({
  date_of_event: z.string().min(1, 'Date is required'),
  locality: z.string().min(1, 'City is required'),
  // ... all fields defined here
});

// Auto-derive types
export type ProtestFormData = z.infer<typeof protestFormSchema>;

// Auto-generate default values
export const defaultFormData = protestFormSchema.parse({});
```

### Option 2: Configuration-Based Approach
Create a central field configuration:

```typescript
// src/lib/config/formFields.ts
export const FORM_FIELDS = {
  date_of_event: {
    type: 'string',
    required: true,
    default: '',
    label: 'Date of Event',
    component: 'DateField'
  },
  locality: {
    type: 'string',
    required: true,
    default: '',
    label: 'City',
    component: 'TextField'
  },
  // ... all fields defined here
} as const;
```

Then generate schema, types, and UI from this configuration.

### Option 3: Database-First Approach
Use database introspection to generate types:

1. Define fields in database only
2. Use a tool like `supabase gen types` to generate TypeScript types
3. Build form from generated types

## Recommendation

**Option 1 (Schema-First)** is best for this codebase because:
- You already have the Zod schema
- It provides runtime validation
- Types can be inferred
- It's the most "SvelteKit way"

Would reduce field additions from 10 files to 2-3 files:
1. Add to schema
2. Add UI component
3. Add database migration

Everything else could be derived/automated.

## ✅ IMPLEMENTED: Configuration-Based Solution

We've successfully condensed the form field management using a central configuration in `src/lib/config/formFieldsConfig.ts`. This dramatically reduces code duplication:

### Before vs After

**Before (formDataMapping.ts):** 230 lines
**After:** 139 lines (~40% reduction)

**Before (ProtestForm.svelte form state):** 50+ lines
**After:** 2 lines

### Key Improvements

1. **Single Configuration File** (`formFieldsConfig.ts`):
   - Defines all field patterns once (incident fields, multiselects, text fields)
   - Auto-generates TypeScript types from patterns
   - Provides default values for all fields

2. **Pattern-Based Processing**:
   - 6 incident fields handled in 3 lines instead of 18
   - 4 multiselect "other" fields handled in one loop
   - 13 text fields handled in one forEach

3. **Simplified Usage**:
   ```typescript
   // Old way: 50+ lines of manual field definitions
   let formData = $state({
     date_of_event: '',
     locality: '',
     // ... 40+ more fields
   });

   // New way: 2 lines
   let formData = $state(createDefaultFormData());
   let otherValues = $state(createDefaultOtherValues());
   ```

### To Add a New Field Now:

1. **Simple text field**: Add to `TEXT_FIELDS` array
2. **Incident field**: Add to `INCIDENT_FIELDS` array
3. **Multiselect**: Add to appropriate multiselect array
4. **Special field**: Add to `SPECIAL_FIELDS` object

That's it! The populate/clear functions automatically handle it.

## Type Cleanup Opportunities Found

### Completed Cleanups
1. ✅ Removed `FormValues` interface (was completely unused)
2. ✅ Removed `ProtestFormProps` from forms.ts (duplicated inline Props)
3. ✅ Deleted forms.ts entirely (moved `FormActionResult` to where it's created)

### Remaining Issues

#### 1. Awkward Import Path
- `ProtestForm.svelte` imports `FormActionResult` from `../../routes/form/+page.server`
- This creates coupling between component and route
- **Options:**
  - Accept it (it's only one import)
  - Move back to a shared location
  - Make ProtestForm less generic (accept it's only used in one route)

#### 2. Type Duplication Between Files
Same fields defined in multiple places:
- `schemas.ts` - Zod validation schema
- `database.ts` - ProtestData interface
- `formDataMapping.ts` - ProtestApiResponse interface
- `ProtestForm.svelte` - formData $state object
- `formDataPreparation.ts` - prepareProtestData function

#### 3. Multi-Select "Other" Pattern
The pattern of ID=0 meaning "other" with a separate text field is repeated across:
- Event Types
- Participant Measures
- Police Measures
- Notes

This could be abstracted into a reusable pattern.

#### 4. Incident Fields Pattern
Six identical yes/no fields with optional details:
- participant_injury + participant_injury_details
- police_injury + police_injury_details
- arrests + arrests_details
- property_damage + property_damage_details
- participant_casualties + participant_casualties_details
- police_casualties + police_casualties_details

These follow the exact same pattern and could be generated/configured rather than hand-coded.