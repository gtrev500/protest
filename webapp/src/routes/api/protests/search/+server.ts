import { json } from '@sveltejs/kit';
import { supabase } from '$lib/supabase';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ url }) => {
  const query = url.searchParams.get('q') || '';
  const limit = parseInt(url.searchParams.get('limit') || '10');
  const offset = parseInt(url.searchParams.get('offset') || '0');

  // Validate inputs
  if (query.length < 3) {
    return json({ results: [] });
  }

  if (limit > 50) {
    return json({ error: 'Limit cannot exceed 50' }, { status: 400 });
  }

  try {
    const { data, error } = await supabase.rpc('search_protests_for_reference', {
      query_text: query,
      limit_count: Math.min(limit, 50),
      offset_count: offset
    });

    if (error) {
      // Error details included in response
      return json({ error: 'Search failed', details: error.message }, { status: 500 });
    }

    // Format the results for the frontend
    const results = (data || []).map((protest: any) => ({
      id: protest.id,
      title: protest.title || 'Untitled Event',
      date_of_event: protest.date_of_event,
      locality: protest.locality,
      state_code: protest.state_code,
      claims_summary: protest.claims_summary,
      organization_name: protest.organization_name,
      rank: protest.rank,
      submission_date: protest.submission_date
    }));

    return json({
      results,
      query,
      total: results.length,
      hasMore: results.length === limit
    });
  } catch (err) {
    console.error('Unexpected error during search:', err);
    return json({ error: 'An unexpected error occurred' }, { status: 500 });
  }
};