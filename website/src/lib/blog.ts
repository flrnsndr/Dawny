/**
 * Helpers that read structure out of the raw markdown of a blog post so it can
 * be re-emitted as JSON-LD, llms.txt or RSS without duplicating the content.
 */

export interface FaqEntry {
  question: string;
  answer: string;
}

/** H2 titles that introduce the FAQ block, in both locales. */
const FAQ_HEADING = /^(faq|frequently asked questions|häufig gestellte fragen|häufige fragen)$/i;

/** Collapses inline markdown to plain text. Block markers are removed first. */
export function stripMarkdown(md: string): string {
  return md
    .replace(/^\s{0,3}#{1,6}\s+/gm, "")
    .replace(/^\s{0,3}>\s?/gm, "")
    .replace(/^\s{0,3}([-*+]|\d+\.)\s+/gm, "")
    .replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
    .replace(/`([^`]+)`/g, "$1")
    .replace(/(\*\*|__)(.+?)\1/g, "$2")
    .replace(/(\*|_)(?=\S)(.+?)(?<=\S)\1/g, "$2")
    .replace(/\s+/g, " ")
    .trim();
}

/** Splits a markdown fragment into blocks (paragraphs and list items). */
function toBlocks(lines: string[]): string[] {
  const blocks: string[] = [];
  let current: string[] = [];

  const flush = () => {
    if (current.length) blocks.push(current.join(" "));
    current = [];
  };

  for (const line of lines) {
    if (!line.trim()) {
      flush();
      continue;
    }
    if (/^\s{0,3}([-*+]|\d+\.)\s+/.test(line)) flush();
    current.push(line.trim());
  }
  flush();

  return blocks.map(stripMarkdown).filter(Boolean);
}

/** Joins blocks into one plain-text answer, keeping sentence boundaries intact. */
function joinBlocks(blocks: string[]): string {
  return blocks
    .map((block) => (/[.!?:;]$/.test(block) ? block : `${block}.`))
    .join(" ")
    .trim();
}

/**
 * The lead blockquote every post opens with ("Quick Answer: …"), without its
 * bold label. Used as the article abstract and as the llms.txt summary.
 */
export function extractQuickAnswer(body: string): string | null {
  const quote = body.match(/^[ \t]{0,3}>.*(?:\r?\n[ \t]{0,3}>.*)*/m);
  if (!quote) return null;

  const text = stripMarkdown(quote[0]).replace(/^\*{0,2}[^:*]{0,40}:\*{0,2}\s*/, "");
  return text || null;
}

/**
 * Question/answer pairs from the post's FAQ section. Returns an empty array
 * when the post has no FAQ block.
 */
export function extractFaq(body: string): FaqEntry[] {
  const entries: FaqEntry[] = [];
  let inFaq = false;
  let question: string | null = null;
  let answer: string[] = [];

  const flush = () => {
    if (question) {
      const text = joinBlocks(toBlocks(answer));
      if (text) entries.push({ question, answer: text });
    }
    question = null;
    answer = [];
  };

  for (const line of body.split(/\r?\n/)) {
    const h2 = line.match(/^##\s+(.+?)\s*$/);
    if (h2) {
      flush();
      inFaq = FAQ_HEADING.test(stripMarkdown(h2[1]));
      continue;
    }
    if (!inFaq) continue;

    const h3 = line.match(/^###\s+(.+?)\s*$/);
    if (h3) {
      flush();
      question = stripMarkdown(h3[1]);
      continue;
    }
    if (question) answer.push(line);
  }
  flush();

  return entries;
}

/** Rough word count of the rendered prose, for BlogPosting.wordCount. */
export function countWords(body: string): number {
  const text = stripMarkdown(body);
  return text ? text.split(/\s+/).length : 0;
}
