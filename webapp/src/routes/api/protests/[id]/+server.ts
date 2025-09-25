import { json } from '@sveltejs/kit';
import { supabase } from '$lib/supabase';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ params }) => {
  const { id } = params;

  // Validate UUID format
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(id)) {
    return json({ error: 'Invalid protest ID format' }, { status: 400 });
  }

  try {
    // Fetch main protest data
    const { data: protestData, error: protestError } = await supabase
      .from('protests')
      .select(`
        id,
        title,
        date_of_event,
        locality,
        state_code,
        location_name,
        organization_name,
        notable_participants,
        targets,
        claims_summary,
        claims_verbatim,
        macroevent,
        is_online,
        crowd_size_low,
        crowd_size_high,
        count_method,
        participant_injury,
        participant_injury_details,
        police_injury,
        police_injury_details,
        arrests,
        arrests_details,
        property_damage,
        property_damage_details,
        participant_casualties,
        participant_casualties_details,
        police_casualties,
        police_casualties_details,
        sources,
        created_at,
        referenced_protest_id,
        reference_type
      `)
      .eq('id', id)
      .single();

    if (protestError) {
      if (protestError.code === 'PGRST116') {
        return json({ error: 'Protest not found' }, { status: 404 });
      }
      console.error('Error fetching protest:', protestError);
      return json({ error: 'Failed to fetch protest' }, { status: 500 });
    }

    // Fetch junction table data in parallel
    const [
      eventTypesRes,
      participantTypesRes,
      participantMeasuresRes,
      policeMeasuresRes,
      notesRes
    ] = await Promise.all([
      supabase.from('protest_event_types')
        .select('event_type_id, other_value')
        .eq('protest_id', id),
      supabase.from('protest_participant_types')
        .select('participant_type_id')
        .eq('protest_id', id),
      supabase.from('protest_participant_measures')
        .select('measure_id, other_value')
        .eq('protest_id', id),
      supabase.from('protest_police_measures')
        .select('measure_id, other_value')
        .eq('protest_id', id),
      supabase.from('protest_notes')
        .select('note_id, other_value')
        .eq('protest_id', id)
    ]);

    // Compile the complete protest data
    const completeData = {
      ...protestData,
      event_types: eventTypesRes.data || [],
      participant_types: participantTypesRes.data || [],
      participant_measures: participantMeasuresRes.data || [],
      police_measures: policeMeasuresRes.data || [],
      notes: notesRes.data || []
    };

    return json({ protest: completeData });
  } catch (err) {
    console.error('Unexpected error:', err);
    return json({ error: 'An unexpected error occurred' }, { status: 500 });
  }
};