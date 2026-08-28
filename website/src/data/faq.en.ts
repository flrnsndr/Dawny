import type { FaqBlock } from "@/data/faq";

/**
 * English FAQ content. Populated in step 6 of the relaunch. Block skeletons only
 * for now: titles, intros, anchors, surfaces and the "Next up …" chain.
 */
export const faqBlocks: FaqBlock[] = [
  {
    id: "reset",
    anchor: "faq-reset",
    title: "The reset",
    intro: "What happens at 3 AM, and why.",
    surface: "paper",
    next: { anchor: "faq-bedienung", label: "Getting the most out of Dawny" },
    groups: [{ items: [] }],
  },
  {
    id: "bedienung",
    anchor: "faq-bedienung",
    title: "Getting the most out of Dawny",
    intro: "The gestures worth seeing once, and how to plan a day with them.",
    surface: "paper-warm",
    next: { anchor: "faq-konzept", label: "The idea behind it" },
    groups: [
      { label: "The gestures", items: [] },
      { label: "Planning a day", items: [] },
    ],
  },
  {
    id: "konzept",
    anchor: "faq-konzept",
    title: "The idea behind it",
    intro: "The questions that come up when Dawny behaves differently than expected.",
    surface: "paper-2",
    next: { anchor: "faq-technik", label: "Devices, sync and widgets" },
    groups: [{ items: [] }],
  },
  {
    id: "technik",
    anchor: "faq-technik",
    title: "Devices, sync and widgets",
    intro: "What reaches your other devices, and what does not.",
    surface: "paper",
    next: { anchor: "faq-daten", label: "Data, cost, support" },
    groups: [{ items: [] }],
  },
  {
    id: "daten",
    anchor: "faq-daten",
    title: "Data, cost, support",
    intro: "Who owns what, and what it costs.",
    surface: "paper-warm",
    groups: [{ items: [] }],
  },
];
