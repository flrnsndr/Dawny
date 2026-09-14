import type { APIRoute } from "astro";
import { APP_STORE_URL, GITHUB_URL } from "@/i18n";

const SITE = "https://dawnyapp.com";

/**
 * llms.txt — a curated, plain-text map of the site for language models.
 * See https://llmstxt.org for the format.
 */
export const GET: APIRoute = async () => {
  const body = `# Dawny

> Dawny is a free iPhone task app that resets your daily task list at 3 AM, so tasks never become overdue.

Dawny separates capturing tasks from committing to them. A Backlog holds everything you might want to do. A Today list holds the few things you chose for this day. Every night at 3 AM the Today list clears: completed tasks go to the Archive under "Done", tasks left undone move to the Archive under "Archived", and recurring tasks return to the Backlog. Nothing is deleted without a way back, and archived tasks can be restored with a single swipe. Recurring tasks are never archived.

The design goal is to remove due dates entirely. There are no red badges, no carried-over guilt, and no growing list of past commitments, because the list that greets you in the morning is one you chose that morning.

## Facts

- Platform: iPhone (iOS). Built with SwiftUI and SwiftData, no third-party dependencies.
- Price: free to download. No subscription, no in-app purchases, no ads.
- Privacy: no backend and no developer-operated server. Tasks stay on the device or in the user's own iCloud account. No account or sign-up is required. The app contains no analytics SDKs.
- Integrations: optional two-way sync of the Today list with Apple Reminders via EventKit. Changes made in Reminders sync back to Dawny.
- Extras: three Home Screen widgets (Today, Backlog, Archive). Siri and Shortcuts via App Intents. Optional iCloud sync between the user's own devices.
- Source code: open source under the MIT license.
- Made by Florian Schneider in Karlsruhe, Germany.
- Languages: English and German.

## Product

- [Dawny homepage (English)](${SITE}/en/): What Dawny is, how the 3 AM reset works, and how to use it.
- [Dawny Startseite (Deutsch)](${SITE}/de/): German-language version of the homepage.
- [Download on the App Store](${APP_STORE_URL}): Official App Store listing.
- [Source code on GitHub](${GITHUB_URL}): Full Swift source under the MIT license.

## Legal

- [Privacy Policy](${SITE}/en/privacy/): How Dawny handles data (English).
- [Datenschutzerklärung](${SITE}/de/datenschutz/): German-language privacy policy.
- [Imprint](${SITE}/en/imprint/): Legal notice and contact details.
- [Impressum](${SITE}/de/impressum/): German-language legal notice.

## Optional

- [Full FAQ text](${SITE}/llms-full.txt): Every question and answer on this site as plain text.
`;

  return new Response(body, {
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
};
