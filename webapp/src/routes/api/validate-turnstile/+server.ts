import { json } from '@sveltejs/kit';
import { validateTurnstileToken } from '$lib/utils/turnstile';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request }) => {
  try {
    const { token } = await request.json();
    
    if (!token) {
      return json({ success: false, error: 'No token provided' }, { status: 400 });
    }

    const result = await validateTurnstileToken(token);
    return json(result);
  } catch (error) {
    console.error('Validation endpoint error:', error);
    return json({ success: false, error: 'Internal error' }, { status: 500 });
  }
};