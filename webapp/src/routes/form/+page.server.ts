import type { PageServerLoad } from './$types';
import { supabase } from '$lib/supabase';
import type {
  State,
  EventType,
  ParticipantType,
  ParticipantMeasure,
  PoliceMeasure,
  NotesOption
} from '$lib/types/database';

export const load: PageServerLoad = async () => {
  const [
    statesRes,
    eventTypesRes,
    participantTypesRes,
    participantMeasuresRes,
    policeMeasuresRes,
    notesRes
  ] = await Promise.all([
    supabase.from('states').select('*').order('name'),
    supabase.from('event_types').select('*').order('name'),
    supabase.from('participant_types').select('*').order('name'),
    supabase.from('participant_measures').select('*').order('name'),
    supabase.from('police_measures').select('*').order('name'),
    supabase.from('notes_options').select('*').order('name')
  ]);

  if (statesRes.error) console.error('Error loading states:', statesRes.error);
  if (eventTypesRes.error) console.error('Error loading event types:', eventTypesRes.error);
  if (participantTypesRes.error) console.error('Error loading participant types:', participantTypesRes.error);
  if (participantMeasuresRes.error) console.error('Error loading participant measures:', participantMeasuresRes.error);
  if (policeMeasuresRes.error) console.error('Error loading police measures:', policeMeasuresRes.error);
  if (notesRes.error) console.error('Error loading notes options:', notesRes.error);

  return {
    states: (statesRes.data ?? []) as State[],
    eventTypes: (eventTypesRes.data ?? []) as EventType[],
    participantTypes: (participantTypesRes.data ?? []) as ParticipantType[],
    participantMeasures: (participantMeasuresRes.data ?? []) as ParticipantMeasure[],
    policeMeasures: (policeMeasuresRes.data ?? []) as PoliceMeasure[],
    notesOptions: (notesRes.data ?? []) as NotesOption[]
  };
}; 