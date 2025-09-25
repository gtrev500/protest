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
    // Try using the RPC function first
    const { data: rpcData, error: rpcError } = await supabase.rpc('search_protests_for_reference', {
      query_text: query,
      limit_count: Math.min(limit, 50),
      offset_count: offset
    });

    let data = rpcData;
    let error = rpcError;

    // If RPC function doesn't exist, fall back to direct query
    if (rpcError && (rpcError.code === '42883' || rpcError.message?.includes('function') || rpcError.message?.includes('does not exist'))) {
      console.log('RPC function not found, using fallback search method');

      // Fallback: Direct query using existing columns
      const searchPattern = `%${query}%`;
      const { data: fallbackData, error: fallbackError } = await supabase
        .from('protests')
        .select('id, title, date_of_event, locality, state_code, claims_summary, organization_name, created_at')
        .or(`locality.ilike.${searchPattern},organization_name.ilike.${searchPattern},title.ilike.${searchPattern},claims_summary.ilike.${searchPattern}`)
        .order('date_of_event', { ascending: false })
        .limit(limit)
        .range(offset, offset + limit - 1);

      data = fallbackData;
      error = fallbackError;

      // Transform to match expected format
      if (data) {
        data = data.map((item: any) => ({
          ...item,
          submission_date: item.created_at,
          rank: 1.0 // Default rank for fallback search
        }));
      }
    }

    if (error) {
      console.error('Search error:', {
        message: error.message,
        details: error.details,
        hint: error.hint,
        code: error.code
      });
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