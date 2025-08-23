import { TURNSTILE_SECRET_KEY } from '$env/static/private';

export async function validateTurnstileToken(token: string): Promise<{ success: boolean; error?: string }> {
  try {
    const response = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        response: token,
        secret: TURNSTILE_SECRET_KEY,
      }),
    });

    const data = await response.json();

    return {
      success: data.success,
      error: data['error-codes']?.length ? data['error-codes'][0] : null,
    };
  } catch (error) {
    console.error('Turnstile validation error:', error);
    return { success: false, error: 'Validation failed' };
  }
}