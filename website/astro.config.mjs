import { readFileSync, readdirSync } from "node:fs";
import { defineConfig } from "astro/config";
import sitemap from "@astrojs/sitemap";
import tailwindcss from "@tailwindcss/vite";

/**
 * Publication dates per blog URL, read straight from the markdown frontmatter.
 * Only pages with a date we actually know get a `lastmod`; guessing one (the
 * build timestamp, say) would tell crawlers the whole site changed on deploy.
 */
function blogLastmod() {
  const dates = new Map();

  for (const lang of ["en", "de"]) {
    const dir = new URL(`./src/content/blog/${lang}/`, import.meta.url);
    for (const file of readdirSync(dir).filter((name) => name.endsWith(".md"))) {
      const source = readFileSync(new URL(file, dir), "utf8");
      const pubDate = source.match(/^pubDate:\s*(.+?)\s*$/m)?.[1]?.replace(/^["']|["']$/g, "");
      if (!pubDate) continue;

      const slug = file.replace(/\.md$/, "");
      dates.set(`https://dawnyapp.com/${lang}/blog/${slug}/`, new Date(pubDate).toISOString());
    }
  }

  return dates;
}

const BLOG_LASTMOD = blogLastmod();

// https://astro.build/config
export default defineConfig({
  site: "https://dawnyapp.com",
  trailingSlash: "ignore",
  build: {
    format: "directory",
    inlineStylesheets: "always",
  },
  i18n: {
    defaultLocale: "en",
    locales: ["en", "de"],
    routing: {
      prefixDefaultLocale: true,
      redirectToDefaultLocale: false,
    },
  },
  integrations: [
    sitemap({
      filter: (page) => page !== "https://dawnyapp.com/",
      serialize(item) {
        const lastmod = BLOG_LASTMOD.get(item.url);
        return lastmod ? { ...item, lastmod } : item;
      },
      i18n: {
        defaultLocale: "en",
        locales: {
          en: "en-US",
          de: "de-DE",
        },
      },
    }),
  ],
  vite: {
    plugins: [tailwindcss()],
    build: {
      target: "esnext",
    },
  },
});
