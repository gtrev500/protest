import type { PageServerLoad, Actions } from './$types';
import { supabase } from '$lib/supabase';
import { fail, redirect } from '@sveltejs/kit';
import { protestFormSchema } from '$lib/types/schemas';
import { prepareSubmissionData } from '$lib/utils/formDataPreparation';
import { validateTurnstileToken } from '$lib/utils/turnstile';
import type {
  State,
  EventType,
  ParticipantType,
  ParticipantMeasure,
  PoliceMeasure,
  NotesOption,
  SubmissionType
} from '$lib/types/database';

export const load: PageServerLoad = async ({ setHeaders }) => {
  // Cache for 1 hour on CDN, 5 minutes in browser
  setHeaders({
    'cache-control': 'public, s-maxage=3600, max-age=300, stale-while-revalidate=86400'
  });
  const [
    statesRes,
    eventTypesRes,
    participantTypesRes,
    participantMeasuresRes,
    policeMeasuresRes,
    notesRes,
    submissionTypesRes
  ] = await Promise.all([
    supabase.from('states').select('*').order('name'),
    supabase.from('event_types').select('*').order('name'),
    supabase.from('participant_types').select('*').order('name'),
    supabase.from('participant_measures').select('*').order('name'),
    supabase.from('police_measures').select('*').order('name'),
    supabase.from('notes_options').select('*').order('name'),
    supabase.from('submission_types').select('*') // no sort because order matters, first option checked
  ]);

  if (statesRes.error) console.error('Error loading states:', statesRes.error);
  if (eventTypesRes.error) console.error('Error loading event types:', eventTypesRes.error);
  if (participantTypesRes.error) console.error('Error loading participant types:', participantTypesRes.error);
  if (participantMeasuresRes.error) console.error('Error loading participant measures:', participantMeasuresRes.error);
  if (policeMeasuresRes.error) console.error('Error loading police measures:', policeMeasuresRes.error);
  if (notesRes.error) console.error('Error loading notes options:', notesRes.error);
  if (submissionTypesRes.error) console.error('Error loading submission types:', submissionTypesRes.error);

  return {
    states: (statesRes.data ?? []) as State[],
    eventTypes: (eventTypesRes.data ?? []) as EventType[],
    participantTypes: (participantTypesRes.data ?? []) as ParticipantType[],
    participantMeasures: (participantMeasuresRes.data ?? []) as ParticipantMeasure[],
    policeMeasures: (policeMeasuresRes.data ?? []) as PoliceMeasure[],
    notesOptions: (notesRes.data ?? []) as NotesOption[],
    submissionTypes: (submissionTypesRes.data ?? []) as SubmissionType[]
  };
};

export const actions: Actions = {
  default: async ({ request }) => {
    const formData = await request.formData();
    
    // Get Turnstile token from form
    const turnstileToken = formData.get('turnstile_token')?.toString() || '';
    
    // Validate Turnstile token
    if (!turnstileToken) {
      return fail(400, {
        message: 'Please complete the CAPTCHA verification',
        values: {}
      });
    }
    
    const turnstileResult = await validateTurnstileToken(turnstileToken);
    if (!turnstileResult.success) {
      return fail(400, {
        message: turnstileResult.error || 'CAPTCHA verification failed. Please try again.',
        values: {}
      });
    }
    
    // Convert FormData to object
    const rawData: Record<string, any> = {};
    
    // Handle regular fields
    for (const [key, value] of formData.entries()) {
      if (key.endsWith('_other')) {
        // Store "other" text fields separately
        rawData[key] = value.toString();
      } else if (key in rawData) {
        // Handle multiple values (checkboxes)
        if (!Array.isArray(rawData[key])) {
          rawData[key] = [rawData[key]];
        }
        rawData[key].push(value.toString());
      } else {
        rawData[key] = value.toString();
      }
    }
    
    // Convert checkbox arrays to arrays if they're single values
    const checkboxFields = ['submission_types', 'event_types', 'participant_types', 
                           'participant_measures', 'police_measures', 'notes'];
    for (const field of checkboxFields) {
      if (rawData[field] && !Array.isArray(rawData[field])) {
        rawData[field] = [rawData[field]];
      } else if (!rawData[field]) {
        rawData[field] = [];
      }
    }
    
    // Parse numeric fields
    if (rawData.crowd_size_low) {
      rawData.crowd_size_low = parseInt(rawData.crowd_size_low) || null;
    }
    if (rawData.crowd_size_high) {
      rawData.crowd_size_high = parseInt(rawData.crowd_size_high) || null;
    }
    
    // Handle boolean field
    rawData.is_online = rawData.is_online === 'true' || rawData.is_online === 'on';
    
    // Validate with Zod
    const result = protestFormSchema.safeParse(rawData);
    
    if (!result.success) {
      return fail(400, {
        errors: result.error.flatten().fieldErrors,
        values: rawData
      });
    }
    
    try {
      // Prepare submission data
      const submissionData = prepareSubmissionData(result.data, {
        submissionTypeOthers: { 0: rawData.submission_types_other || '' },
        eventTypeOthers: { 0: rawData.event_types_other || '' },
        participantMeasureOthers: { 0: rawData.participant_measures_other || '' },
        policeMeasureOthers: { 0: rawData.police_measures_other || '' },
        notesOthers: { 0: rawData.notes_other || '' }
      });
      
      // Submit using the database function
      const { data, error } = await supabase.rpc('submit_protest', submissionData);
      
      if (error) {
        console.error('Supabase RPC error:', error);
        return fail(500, {
          message: 'Failed to submit protest information. Please try again.',
          values: rawData
        });
      }
      
      if (!data || !data.id) {
        return fail(500, {
          message: 'Submission failed - no ID returned',
          values: rawData
        });
      }
      
      // Redirect to success page
      throw redirect(303, `/success?id=${data.id}`);
      
    } catch (error) {
      // In SvelteKit, redirects are special objects that need to be re-thrown
      // Check if this is a redirect response
      if (error && typeof error === 'object' && 'status' in error && 'location' in error) {
        // This is a redirect, re-throw it
        throw error;
      }
      
      // For even more safety, also check for Response instances
      if (error instanceof Response) {
        throw error;
      }
      
      console.error('Error submitting protest:', error);
      return fail(500, {
        message: 'An unexpected error occurred. Please try again.',
        values: rawData
      });
    }
  }
}; 