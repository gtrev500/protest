/**
 * Minimal Umami Analytics helper.
 *
 * - No-ops automatically during SSR or when Umami env vars are missing.
 * - Queues events until the Umami script is ready to avoid race conditions.
 * - Keeps implementation light so analytics does not add application complexity.
 */

declare global {
  interface Window {
    umami?: {
      track: (event: string, data?: Record<string, any>) => void;
    };
  }
}

type QueuedEvent = {
  event: string;
  data?: Record<string, any>;
};

const isBrowser = typeof window !== 'undefined';
const umamiEnabled =
  Boolean(import.meta.env.VITE_UMAMI_SCRIPT_URL) && Boolean(import.meta.env.VITE_UMAMI_WEBSITE_ID);

const queue: QueuedEvent[] = [];
let pollHandle: number | null = null;

function flushQueue() {
  if (!isBrowser || !window.umami?.track) {
    return;
  }

  while (queue.length > 0) {
    const next = queue.shift();
    if (!next) {
      continue;
    }
    window.umami.track(next.event, next.data);
  }
}

function ensurePolling() {
  if (!isBrowser || pollHandle !== null) {
    return;
  }

  const poll = () => {
    if (window.umami?.track) {
      flushQueue();
      pollHandle = null;
      return;
    }

    pollHandle = window.requestAnimationFrame(poll);
  };

  pollHandle = window.requestAnimationFrame(poll);
}

/**
 * Track an analytics event.
 * @param event - The event name (e.g., 'form_viewed', 'form_submit_success')
 * @param data - Optional event properties (no PII)
 */
export function trackEvent(event: string, data?: Record<string, any>): void {
  if (!isBrowser || !umamiEnabled) {
    return;
  }

  if (window.umami?.track) {
    window.umami.track(event, data);
    return;
  }

  queue.push({ event, data });
  ensurePolling();
}

/**
 * Track an analytics event that must be sent even during page unload.
 * Uses navigator.sendBeacon() for reliability when the page is closing.
 * Ideal for tracking form abandonment, session end, etc.
 *
 * @param event - The event name (e.g., 'form_abandoned')
 * @param data - Optional event properties (no PII)
 */
export function trackEventBeacon(event: string, data?: Record<string, any>): void {
  if (!isBrowser || !umamiEnabled) {
    return;
  }

  let beaconSent = false;

  if (navigator.sendBeacon) {
    const payload = JSON.stringify({
      type: 'event',
      payload: {
        website: import.meta.env.VITE_UMAMI_WEBSITE_ID,
        hostname: window.location.hostname,
        language: navigator.language,
        screen: `${window.screen.width}x${window.screen.height}`,
        title: document.title,
        url: window.location.pathname,
        name: event,
        data: data || {}
      }
    });

    const scriptUrl = import.meta.env.VITE_UMAMI_SCRIPT_URL;
    const baseUrl = scriptUrl.replace('/script.js', '');
    beaconSent = navigator.sendBeacon(`${baseUrl}/api/send`, payload);
  }

  if (!beaconSent && window.umami?.track) {
    window.umami.track(event, data);
  }
}

/**
 * Called when Umami script loads to flush queued events.
 * @internal
 */
export function markUmamiReady(): void {
  flushQueue();
}
