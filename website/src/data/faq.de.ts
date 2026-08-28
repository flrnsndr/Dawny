import type { FaqBlock } from "@/data/faq";

/**
 * German FAQ content. Populated in step 6 of the relaunch. Block skeletons only
 * for now: titles, intros, anchors, surfaces and the "Weiter zu …" chain.
 */
export const faqBlocks: FaqBlock[] = [
  {
    id: "reset",
    anchor: "faq-reset",
    title: "Der Reset",
    intro: "Was nachts um drei passiert, und warum.",
    surface: "paper",
    next: { anchor: "faq-bedienung", label: "Wie nutze ich Dawny am besten?" },
    groups: [{ items: [] }],
  },
  {
    id: "bedienung",
    anchor: "faq-bedienung",
    title: "Wie nutze ich Dawny am besten?",
    intro:
      "Die Handgriffe, die man einmal gesehen haben muss, und wie man sich den Tag damit einteilt.",
    surface: "paper-warm",
    next: { anchor: "faq-konzept", label: "Das Konzept dahinter" },
    groups: [
      { label: "Die Handgriffe", items: [] },
      { label: "Wie man sich den Tag einteilt", items: [] },
    ],
  },
  {
    id: "konzept",
    anchor: "faq-konzept",
    title: "Das Konzept dahinter",
    intro: "Die Fragen, die kommen, wenn Dawny sich anders verhält als erwartet.",
    surface: "paper-2",
    next: { anchor: "faq-technik", label: "Geräte, Sync und Widgets" },
    groups: [{ items: [] }],
  },
  {
    id: "technik",
    anchor: "faq-technik",
    title: "Geräte, Sync und Widgets",
    intro: "Was auf anderen Geräten ankommt, und was nicht.",
    surface: "paper",
    next: { anchor: "faq-daten", label: "Daten, Kosten, Support" },
    groups: [{ items: [] }],
  },
  {
    id: "daten",
    anchor: "faq-daten",
    title: "Daten, Kosten, Support",
    intro: "Wem was gehört und was das kostet.",
    surface: "paper-warm",
    groups: [{ items: [] }],
  },
];
