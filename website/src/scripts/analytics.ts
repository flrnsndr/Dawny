/**
 * Thin wrapper around the PostHog snippet in `components/PostHog.astro`.
 *
 * That snippet only ships when PUBLIC_POSTHOG_PROJECT_TOKEN is set, so on a
 * local build without a token `window.posthog` is simply absent. Routing every
 * call through here keeps the "is it there?" check out of the feature scripts
 * and makes tracking a no-op instead of a crash.
 *
 * Declarative clicks (`data-ph-event="…"` in markup) are handled by the
 * snippet's own delegated listener. This helper is for the cases markup cannot
 * express: state a script knows and the DOM does not.
 */

interface PostHogLike {
  capture: (event: string, properties?: Record<string, unknown>) => void;
}

declare global {
  interface Window {
    posthog?: PostHogLike;
  }
}

export function capture(event: string, properties?: Record<string, unknown>): void {
  window.posthog?.capture(event, properties);
}
