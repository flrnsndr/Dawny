import type { APIRoute } from "astro";
import { getCollection } from "astro:content";
import { APP_STORE_URL } from "@/i18n";

const SITE = "https://dawnyapp.com";

/**
 * llms-full.txt — every article as plain markdown, so a model can read the
 * whole site without crawling and rendering each page.
 */
export const GET: APIRoute = async () => {
  const posts = await getCollection("blog");

  /** Pushes a post's own headings below the level of its title in this document. */
  const demoteHeadings = (markdown: string) =>
    markdown.replace(/^(#{1,4})(\s+\S)/gm, (_match, hashes: string, rest: string) => `${hashes}##${rest}`);

  const sections = ["en", "de"].map((lang) => {
    const heading = lang === "en" ? "English articles" : "German articles (deutschsprachige Artikel)";
    const articles = posts
      .filter((post) => post.id.startsWith(`${lang}/`))
      .sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf())
      .map((post) => {
        const slug = post.id.replace(`${lang}/`, "").replace(".md", "");
        const url = `${SITE}/${lang}/blog/${slug}/`;
        const date = post.data.pubDate.toISOString().slice(0, 10);
        const body = demoteHeadings((post.body ?? "").trim());

        return [
          `### ${post.data.title}`,
          "",
          `Source: ${url}`,
          `Published: ${date}`,
          `Language: ${lang}`,
          `Author: Florian Schneider`,
          "",
          body,
        ].join("\n");
      });

    return [`## ${heading}`, "", articles.join("\n\n---\n\n")].join("\n");
  });

  const body = `# Dawny: full article text

Dawny is a free iPhone task app that resets your daily task list at 3 AM, so tasks never become overdue. A Backlog holds everything you might do; a Daily Focus holds what you chose for today. At 3 AM the Daily Focus clears: unfinished tasks return to the Backlog, and tasks that keep slipping move to the Archive. Recurring tasks always return to the Backlog and are never archived.

Website: ${SITE}
App Store: ${APP_STORE_URL}
Author: Florian Schneider, Karlsruhe, Germany
License of this text: © Florian Schneider. Quotation with attribution to dawnyapp.com is welcome.

---

${sections.join("\n\n---\n\n")}
`;

  return new Response(body, {
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
};
