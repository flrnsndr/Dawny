import { faqBlocks as de } from "../src/data/faq.de.ts";
import { faqBlocks as en } from "../src/data/faq.en.ts";
import { FAQ_BLOCK_ORDER } from "../src/data/faq.ts";

let ok = true;
const fail = (msg: string) => {
  ok = false;
  console.error(`✗ ${msg}`);
};

const deBlockIds = de.map((b) => b.id);
const enBlockIds = en.map((b) => b.id);

if (JSON.stringify(deBlockIds) !== JSON.stringify(FAQ_BLOCK_ORDER)) {
  fail(`faq.de.ts block order ${JSON.stringify(deBlockIds)} does not match FAQ_BLOCK_ORDER ${JSON.stringify(FAQ_BLOCK_ORDER)}`);
}
if (JSON.stringify(enBlockIds) !== JSON.stringify(FAQ_BLOCK_ORDER)) {
  fail(`faq.en.ts block order ${JSON.stringify(enBlockIds)} does not match FAQ_BLOCK_ORDER ${JSON.stringify(FAQ_BLOCK_ORDER)}`);
}

for (const blockId of FAQ_BLOCK_ORDER) {
  const deBlock = de.find((b) => b.id === blockId);
  const enBlock = en.find((b) => b.id === blockId);
  if (!deBlock) {
    fail(`faq.de.ts is missing block "${blockId}"`);
    continue;
  }
  if (!enBlock) {
    fail(`faq.en.ts is missing block "${blockId}"`);
    continue;
  }

  if (deBlock.groups.length !== enBlock.groups.length) {
    fail(`block "${blockId}": group count differs (de: ${deBlock.groups.length}, en: ${enBlock.groups.length})`);
    continue;
  }

  deBlock.groups.forEach((deGroup, i) => {
    const enGroup = enBlock.groups[i];
    const deIds = deGroup.items.map((item) => item.id);
    const enIds = enGroup.items.map((item) => item.id);

    if (JSON.stringify(deIds) !== JSON.stringify(enIds)) {
      fail(`block "${blockId}", group ${i} (${deGroup.label ?? "unlabeled"}): item ids differ\n  de: ${JSON.stringify(deIds)}\n  en: ${JSON.stringify(enIds)}`);
    }

    for (const item of [...deGroup.items, ...enGroup.items]) {
      if (!item.q.trim() || !item.a.trim()) {
        fail(`block "${blockId}", item "${item.id}": empty question or answer`);
      }
    }
  });
}

const deCount = de.flatMap((b) => b.groups).flatMap((g) => g.items).length;
const enCount = en.flatMap((b) => b.groups).flatMap((g) => g.items).length;
if (deCount !== enCount) {
  fail(`total item count differs (de: ${deCount}, en: ${enCount})`);
}

if (!ok) {
  console.error(`\nFAQ parity check failed.`);
  process.exit(1);
}

console.log(`✓ FAQ parity check passed: ${FAQ_BLOCK_ORDER.length} blocks, ${deCount} items, de/en in sync.`);
