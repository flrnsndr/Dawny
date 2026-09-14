/**
 * FAQ data model. The visible accordions and the FAQPage JSON-LD are both built
 * from the same `faq.de.ts` / `faq.en.ts` arrays, so they can never drift apart.
 *
 * Item and block ids are stable and identical across locales, so a deep link
 * like `/de/#reset-uhrzeit` opens the same question on both language pages.
 */

export type FaqBlockId = "reset" | "bedienung" | "konzept" | "technik" | "daten";

/** Background flavour a FAQ block sits on. Maps to a `--color-*` token. */
export type FaqSurface = "paper" | "paper-warm" | "paper-2";

export interface FaqItem {
  /** Stable, locale-independent id. Also the `id` of the rendered `<details>`. */
  id: string;
  /** Question, shown in the `<summary>`. */
  q: string;
  /** Answer, two to five sentences, plain text. */
  a: string;
}

export interface FaqGroup {
  /** Optional sub-heading shown above the group (used in block B). */
  label?: string;
  items: FaqItem[];
}

export interface FaqBlock {
  id: FaqBlockId;
  /** In-page anchor, e.g. "faq-reset". */
  anchor: string;
  title: string;
  /** One-sentence lead under the block heading. */
  intro: string;
  groups: FaqGroup[];
  /** Pointer to the next block, rendered as a "Weiter zu …" link. */
  next?: { anchor: string; label: string };
  surface: FaqSurface;
}

/**
 * A flat question/answer pair. Used by SchemaOrg.astro to emit one FAQPage
 * object per language page.
 */
export interface FaqEntry {
  question: string;
  answer: string;
}

/** Flattens all blocks of one locale into the pairs the JSON-LD needs. */
export function faqEntries(blocks: FaqBlock[]): FaqEntry[] {
  return blocks.flatMap((block) =>
    block.groups.flatMap((group) =>
      group.items.map((item) => ({ question: item.q, answer: item.a })),
    ),
  );
}

/** The canonical block order, shared by both locales and checked by the parity test. */
export const FAQ_BLOCK_ORDER: FaqBlockId[] = ["reset", "bedienung", "konzept", "technik", "daten"];
