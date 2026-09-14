import type { APIRoute } from "astro";
import { APP_STORE_URL } from "@/i18n";
import { faqBlocks as faqDe } from "@/data/faq.de";
import { faqBlocks as faqEn } from "@/data/faq.en";
import type { FaqBlock } from "@/data/faq";

const SITE = "https://dawnyapp.com";

/**
 * llms-full.txt — the full FAQ of both language pages as plain text, so a model
 * can read the whole site without crawling and rendering each accordion.
 */
export const GET: APIRoute = async () => {
  const renderBlocks = (blocks: FaqBlock[]) =>
    blocks
      .map((block) => {
        const items = block.groups
          .flatMap((group) => group.items)
          .map((item) => `#### ${item.q}\n\n${item.a}`)
          .join("\n\n");
        return `### ${block.title}\n\n${block.intro}\n\n${items}`;
      })
      .join("\n\n");

  const body = `# Dawny: full FAQ text

Dawny is a free iPhone task app that resets your daily task list at 3 AM, so tasks never become overdue. A Backlog holds everything you might do; a Today list holds what you chose for this day. At 3 AM the Today list clears: completed tasks go to the Archive under "Done", undone tasks move to the Archive under "Archived", and recurring tasks return to the Backlog. Recurring tasks are never archived.

Website: ${SITE}
App Store: ${APP_STORE_URL}
Author: Florian Schneider, Karlsruhe, Germany
License of this text: © Florian Schneider. Quotation with attribution to dawnyapp.com is welcome.

---

## English FAQ

${renderBlocks(faqEn)}

---

## Deutsche FAQ

${renderBlocks(faqDe)}
`;

  return new Response(body, {
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
};
