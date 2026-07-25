import type { APIRoute } from "astro";
import { getCollection } from "astro:content";
import { APP_STORE_URL, GITHUB_URL } from "@/i18n";

const SITE = "https://dawnyapp.com";

/**
 * llms.txt — a curated, plain-text map of the site for language models.
 * See https://llmstxt.org for the format.
 */
export const GET: APIRoute = async () => {
  const posts = await getCollection("blog");
  const byLang = (lang: string) =>
    posts
      .filter((post) => post.id.startsWith(`${lang}/`))
      .sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf())
      .map((post) => {
        const slug = post.id.replace(`${lang}/`, "").replace(".md", "");
        return `- [${post.data.title}](${SITE}/${lang}/blog/${slug}/): ${post.data.description}`;
      });

  const body = `# Dawny

> Dawny is a free iPhone task app that resets your daily task list at 3 AM, so tasks never become overdue.

Dawny separates capturing tasks from committing to them. A Backlog holds everything you might want to do. A Daily Focus holds the few things you chose for today. Every night at 3 AM the Daily Focus clears: unfinished tasks return to the Backlog, and tasks that keep slipping move to the Archive. Nothing is deleted without a way back, and archived tasks can be restored with a single tap. Recurring tasks always return to the Backlog and are never archived.

The design goal is to remove overdue dates entirely. There are no red badges, no carried-over guilt, and no growing list of past commitments, because the list that greets you in the morning is one you chose that morning.

## Facts

- Platform: iPhone (iOS). Built with SwiftUI and SwiftData, no third-party dependencies.
- Price: free to download. No subscription, no in-app purchases, no ads.
- Privacy: no backend and no developer-operated server. Tasks stay on the device or in the user's own iCloud account. No account or sign-up is required.
- Integrations: optional two-way sync of Daily Focus tasks with Apple Reminders via EventKit. Changes made in Reminders sync back to Dawny.
- Extras: Home Screen and Lock Screen widgets for Daily Focus, Backlog, and Archive.
- Source code: open source under the MIT license.
- Made by Florian Schneider in Karlsruhe, Germany.
- Languages: English and German.

## Product

- [Dawny homepage (English)](${SITE}/en/): What Dawny is, how the 3 AM reset works, and who it suits.
- [Dawny Startseite (Deutsch)](${SITE}/de/): German-language version of the homepage.
- [Download on the App Store](${APP_STORE_URL}): Official App Store listing.
- [Source code on GitHub](${GITHUB_URL}): Full Swift source under the MIT license.

## Articles (English)

${byLang("en").join("\n")}

## Artikel (Deutsch)

${byLang("de").join("\n")}

## Legal

- [Privacy Policy](${SITE}/en/privacy/): How Dawny handles data (English).
- [Datenschutzerklärung](${SITE}/de/datenschutz/): German-language privacy policy.
- [Imprint](${SITE}/en/imprint/): Legal notice and contact details.

## Optional

- [Full article text](${SITE}/llms-full.txt): Every article on this site as plain markdown.
- [English RSS feed](${SITE}/en/rss.xml): New articles in English.
- [German RSS feed](${SITE}/de/rss.xml): New articles in German.
`;

  return new Response(body, {
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
};
