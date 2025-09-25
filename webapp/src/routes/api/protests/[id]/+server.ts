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
    const { data, error } = await supabase
      .from('protests')
      .select('id, title, date_of_event, locality, state_code, claims_summary, organization_name, created_at')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return json({ error: 'Protest not found' }, { status: 404 });
      }
      console.error('Error fetching protest:', error);
      return json({ error: 'Failed to fetch protest' }, { status: 500 });
    }

    return json({ protest: data });
  } catch (err) {
    console.error('Unexpected error:', err);
    return json({ error: 'An unexpected error occurred' }, { status: 500 });
  }
};