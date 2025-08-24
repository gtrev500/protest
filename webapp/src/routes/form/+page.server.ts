import type { PageServerLoad } from './$types';
import { supabase } from '$lib/supabase';
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