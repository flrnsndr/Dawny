import { getCollection } from "astro:content";
import { type Lang, getDict } from "@/i18n";
import { extractQuickAnswer } from "@/lib/blog";

const SITE = "https://dawnyapp.com";

function escapeXml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

/** RSS 2.0 feed of every published article in one language. */
export async function buildFeed(lang: Lang): Promise<Response> {
  const dict = getDict(lang);
  const feedUrl = `${SITE}/${lang}/rss.xml`;
  const blogUrl = `${SITE}/${lang}/blog/`;

  const posts = (await getCollection("blog", ({ id }) => id.startsWith(`${lang}/`))).sort(
    (a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf()
  );

  const items = posts.map((post) => {
    const slug = post.id.replace(`${lang}/`, "").replace(".md", "");
    const url = `${SITE}/${lang}/blog/${slug}/`;
    const summary = extractQuickAnswer(post.body ?? "") ?? post.data.description;

    return `    <item>
      <title>${escapeXml(post.data.title)}</title>
      <link>${url}</link>
      <guid isPermaLink="true">${url}</guid>
      <pubDate>${post.data.pubDate.toUTCString()}</pubDate>
      <description>${escapeXml(summary)}</description>
    </item>`;
  });

  const latest = posts[0]?.data.pubDate;

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>${escapeXml(`${dict.blog.title} — Dawny`)}</title>
    <link>${blogUrl}</link>
    <description>${escapeXml(dict.blog.description)}</description>
    <language>${lang === "de" ? "de-DE" : "en-US"}</language>
    <copyright>© Florian Schneider</copyright>
    <atom:link href="${feedUrl}" rel="self" type="application/rss+xml" />
${latest ? `    <lastBuildDate>${new Date(latest).toUTCString()}</lastBuildDate>\n` : ""}${items.join("\n")}
  </channel>
</rss>
`;

  return new Response(xml, {
    headers: { "Content-Type": "application/rss+xml; charset=utf-8" },
  });
}
