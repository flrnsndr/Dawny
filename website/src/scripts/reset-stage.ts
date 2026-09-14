/**
 * Guided reset demo for the `#reset` section (concept 4.2), ported from
 * `website/prototype/demo.js`.
 *
 * Three panes side by side (Backlog, Today, Archive) and a five station
 * timeline (Before, Morning, During the day, 3 AM, Next morning) that starts by
 * itself once the section scrolls into view, so nobody has to guess where to
 * click.
 *
 * Every step is choreographed instead of being switched over in one go: first
 * the affected tasks are highlighted and everything else steps back, then one
 * task at a time travels, with a target badge on the entry and the destination
 * pane lighting up. The whole section rides a day -> night -> day arc; the 3 AM
 * step is the only dark one.
 *
 * Progressive enhancement: without JavaScript the end state after the reset
 * stays in the markup and the timeline stays hidden. This file only ever
 * un-hides the timeline and the pause control, it never builds the stage.
 *
 * Markup contract (see ResetStage.astro). All localized text comes out of the
 * DOM, never out of this file:
 *   #reset                      the section, carries .is-night / .is-guiding
 *   #stage-panes                pane container
 *   #stage-caption              aria-live caption
 *   #stage-timeline             timeline, `hidden` in markup
 *   #stage-replay #stage-pause  controls, `hidden` in markup
 *   [data-pane]                 backlog | today | archive
 *   [data-col][data-label]      backlog | today | archived | done, label = badge text
 *   [data-count] [data-empty]   count bubble / empty placeholder per pane resp. column
 *   .stage__task[data-id]       a task, containing an empty .stage__badge
 *   button[data-step][data-caption]  timeline station, caption for that step
 *
 * Analytics: the demo reports a handful of events through @/scripts/analytics,
 * see the capture() calls below. Nothing here depends on them, they are no-ops
 * without a PostHog token.
 */

import { capture } from "@/scripts/analytics";

const COLUMNS = ["backlog", "today", "archived", "done"] as const;
type ColumnKey = (typeof COLUMNS)[number];
type PaneKey = "backlog" | "today" | "archive";

interface Step {
  /** Pane that gets the accent border for this step. */
  focus: PaneKey | null;
  night: boolean;
  /** Task ids per column at the end of the step. */
  cols: Record<ColumnKey, string[]>;
  /** Task ids that are ticked off at the end of the step. */
  done: string[];
}

/** Which pane a column lives in. The archive pane holds two columns. */
const PANE_OF: Record<ColumnKey, PaneKey> = {
  backlog: "backlog",
  today: "today",
  archived: "archive",
  done: "archive",
};

const STEPS: Step[] = [
  {
    focus: "backlog",
    night: false,
    // Order matters: applyInstant() appends in this order, and the two tasks
    // that move to Today in step 2 sit at the top of the backlog.
    cols: { backlog: ["tickets", "rezept", "urlaub", "pass"], today: [], archived: [], done: [] },
    done: [],
  },
  {
    focus: "today",
    night: false,
    cols: { backlog: ["urlaub", "pass"], today: ["tickets", "rezept"], archived: [], done: [] },
    done: [],
  },
  {
    focus: "today",
    night: false,
    cols: { backlog: ["urlaub", "pass"], today: ["tickets", "rezept"], archived: [], done: [] },
    done: ["rezept"],
  },
  {
    focus: null,
    night: true,
    cols: { backlog: ["urlaub", "pass"], today: [], archived: ["tickets"], done: ["rezept"] },
    done: ["rezept"],
  },
  {
    focus: "today",
    night: false,
    cols: { backlog: ["urlaub", "pass"], today: [], archived: ["tickets"], done: ["rezept"] },
    done: ["rezept"],
  },
];

/* ---------------------------------------------------------------------------
   Tempo. One number for everything, it scales every duration below. Measured
   run time of a full pass:

     SPEED = 1.5   ->  about 41 s
     SPEED = 1.25  ->  about 35 s
     SPEED = 1     ->  about 28 s   (current)
     SPEED = 0.75  ->  about 21 s
     SPEED = 0.55  ->  about 15 s
   --------------------------------------------------------------------------- */
const SPEED = 1;

const TIMING = {
  travel: 1100, // sun and bar move on to the next station
  highlight: 1800, // run-up in which the affected tasks are marked
  tick: 1200, // gap between two check marks
  move: 1900, // duration of a single journey
  gap: 700, // pause between two journeys
  land: 1500, // afterglow at the destination
  settle: 500, // run-out before the step ends
  dwell: 1200, // stand time at the end of a step
} as const;
// settle + dwell is the pause between two steps, currently 1.7 s.

type TimingKey = keyof typeof TIMING;

interface Refs {
  stage: HTMLElement;
  panes: HTMLElement;
  captionEl: HTMLElement;
  timeline: HTMLElement;
  replayBtn: HTMLElement;
  pauseBtn: HTMLElement;
}

function init(): void {
  const stage = document.getElementById("reset");
  const panes = document.getElementById("stage-panes");
  const captionEl = document.getElementById("stage-caption");
  const timeline = document.getElementById("stage-timeline");
  const replayBtn = document.getElementById("stage-replay");
  const pauseBtn = document.getElementById("stage-pause");
  if (!stage || !panes || !captionEl || !timeline || !replayBtn || !pauseBtn) return;
  setup({ stage, panes, captionEl, timeline, replayBtn, pauseBtn });
}

function setup(refs: Refs): void {
  const { stage, panes, captionEl, timeline, replayBtn, pauseBtn } = refs;

  const cols = {} as Record<ColumnKey, HTMLElement>;
  for (const key of COLUMNS) {
    const el = panes.querySelector<HTMLElement>(`[data-col="${key}"]`);
    if (!el) return;
    cols[key] = el;
  }

  const stations = Array.from(timeline.querySelectorAll<HTMLButtonElement>("button[data-step]"));
  if (stations.length !== STEPS.length) return;

  const pauseLabel = pauseBtn.dataset.labelPause ?? "";
  const resumeLabel = pauseBtn.dataset.labelResume ?? "";
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  let token = 0; // abort marker: every new action bumps it
  let current = 0; // station the sun is standing on
  let paused = false;
  let waiters: Array<() => void> = [];
  let started = false; // has the run been kicked off, by the observer or by hand
  let observer: IntersectionObserver | null = null;

  /* -------------------------------------------------------------------------
     Timing, with the pause gate baked into sleep()
     ------------------------------------------------------------------------- */

  function ms(key: TimingKey): number {
    return TIMING[key] * SPEED;
  }

  /**
   * Every wait in the choreography goes through here, and every wait ends by
   * asking whether we are paused. In-flight Web Animations are left alone, so
   * pausing takes hold at the next scheduled beat rather than mid-flight, which
   * is under two seconds at SPEED = 1 and what SC 2.2.2 is after.
   */
  function sleep(m: number): Promise<void> {
    return new Promise<void>((resolve) => {
      window.setTimeout(resolve, m);
    }).then(gate);
  }

  function gate(): Promise<void> {
    if (!paused) return Promise.resolve();
    return new Promise<void>((resolve) => {
      waiters.push(resolve);
    });
  }

  /**
   * The label names the next action, so the accessible name changes with it.
   * That is why there is deliberately no aria-pressed: a button called "Resume"
   * that also reports itself as pressed reads as a contradiction.
   */
  function setPaused(next: boolean): void {
    paused = next;
    pauseBtn.textContent = next ? resumeLabel : pauseLabel;
    if (next) return;
    const pending = waiters;
    waiters = [];
    for (const resolve of pending) resolve();
  }

  /* -------------------------------------------------------------------------
     Small helpers
     ------------------------------------------------------------------------- */

  function taskEl(id: string): HTMLElement | null {
    return panes.querySelector<HTMLElement>(`.stage__task[data-id="${id}"]`);
  }

  function allTasks(): HTMLElement[] {
    return Array.from(panes.querySelectorAll<HTMLElement>(".stage__task"));
  }

  function paneEl(name: PaneKey): HTMLElement | null {
    return panes.querySelector<HTMLElement>(`[data-pane="${name}"]`);
  }

  function columnOf(id: string): ColumnKey | null {
    const el = taskEl(id);
    if (!el) return null;
    return COLUMNS.find((key) => cols[key].contains(el)) ?? null;
  }

  /** Task id -> the column it belongs in at the end of this step. */
  function targetsOf(step: Step): Map<string, ColumnKey> {
    const map = new Map<string, ColumnKey>();
    for (const key of COLUMNS) for (const id of step.cols[key]) map.set(id, key);
    return map;
  }

  function refreshEmpties(): void {
    for (const key of COLUMNS) {
      const empty = panes.querySelector<HTMLElement>(`[data-empty="${key}"]`);
      if (empty) empty.hidden = cols[key].children.length > 0;
    }
  }

  function refreshCounts(): void {
    const values: Record<PaneKey, number> = {
      backlog: cols.backlog.children.length,
      today: cols.today.children.length,
      archive: cols.archived.children.length + cols.done.children.length,
    };
    for (const [name, value] of Object.entries(values)) {
      const el = panes.querySelector<HTMLElement>(`[data-count="${name}"]`);
      if (!el) continue;
      const next = String(value);
      if (el.textContent === next) continue;
      el.textContent = next;
      el.classList.remove("is-bump");
      void el.offsetWidth; // force the animation to restart
      el.classList.add("is-bump");
    }
  }

  function badgeEl(el: HTMLElement): HTMLElement | null {
    return el.querySelector<HTMLElement>(".stage__badge");
  }

  function setBadge(el: HTMLElement, target: ColumnKey): void {
    const badge = badgeEl(el);
    if (!badge) return;
    badge.textContent = cols[target].dataset.label ?? "";
    badge.hidden = false;
    void badge.offsetWidth;
    badge.classList.add("is-shown");
  }

  function clearBadge(el: HTMLElement): void {
    const badge = badgeEl(el);
    if (!badge) return;
    badge.classList.remove("is-shown");
    badge.hidden = true;
    badge.textContent = "";
  }

  function clearMarks(): void {
    for (const el of allTasks()) {
      el.classList.remove("is-affected");
      clearBadge(el);
    }
    for (const pane of Array.from(panes.children)) pane.classList.remove("is-target");
    stage.classList.remove("is-guiding");
  }

  function setChrome(step: Step, index: number): void {
    stage.classList.toggle("is-night", step.night);
    for (const pane of Array.from(panes.children)) {
      const key = pane instanceof HTMLElement ? pane.dataset.pane : undefined;
      pane.classList.toggle("is-focus", step.focus === key);
    }
    captionEl.textContent = stations[index].dataset.caption ?? "";
    stations.forEach((button, i) => {
      button.classList.toggle("is-past", i < index);
      button.classList.toggle("is-active", i === index);
      button.classList.toggle("is-next", i === index + 1);
      button.setAttribute("aria-current", i === index ? "step" : "false");
    });
  }

  /**
   * The timeline bar travels from station to station over the duration of the
   * step, so you can see where you are and where it goes next at the same time.
   */
  function setProgress(index: number, duration: number): void {
    timeline.style.setProperty("--tl-dur", `${Math.max(0, duration)}ms`);
    timeline.style.setProperty("--tl-p", String(index / (STEPS.length - 1)));
  }

  /* -------------------------------------------------------------------------
     Set a state without animating
     ------------------------------------------------------------------------- */

  function applyInstant(index: number): void {
    const step = STEPS[index];
    clearMarks();
    for (const key of COLUMNS) {
      for (const id of step.cols[key]) {
        const el = taskEl(id);
        if (el) cols[key].appendChild(el);
      }
    }
    for (const el of allTasks()) {
      el.classList.remove("is-landed");
      el.classList.toggle("is-done", step.done.includes(el.dataset.id ?? ""));
    }
    refreshEmpties();
    refreshCounts();
    setChrome(step, index);
    setProgress(index, 0);
    current = index;
  }

  /* -------------------------------------------------------------------------
     Let a single task travel (FLIP)
     ------------------------------------------------------------------------- */

  function moveOne(id: string, target: ColumnKey, step: Step): Promise<void> {
    const el = taskEl(id);
    if (!el) return Promise.resolve();
    const destPane = paneEl(PANE_OF[target]);
    destPane?.classList.add("is-target");

    const nodes = allTasks();
    const before = nodes.map((node) => node.getBoundingClientRect());

    cols[target].appendChild(el);
    el.classList.toggle("is-done", step.done.includes(id));
    refreshEmpties();

    nodes.forEach((node, i) => {
      const after = node.getBoundingClientRect();
      const dx = before[i].left - after.left;
      const dy = before[i].top - after.top;
      if (!dx && !dy) return;
      node.animate(
        [{ transform: `translate(${dx}px, ${dy}px)` }, { transform: "none" }],
        { duration: ms("move"), easing: "cubic-bezier(.33,.68,.32,1)" },
      );
    });

    return sleep(ms("move")).then(() => {
      destPane?.classList.remove("is-target");
      clearBadge(el);
      el.classList.add("is-landed");
      refreshCounts(); // count up on arrival, not on departure
      window.setTimeout(() => el.classList.remove("is-landed"), ms("land"));
    });
  }

  /* -------------------------------------------------------------------------
     Play one step, choreographed
     ------------------------------------------------------------------------- */

  /**
   * A step has two beats: first the sun and the bar travel to the station, then
   * the animation belonging to that station runs.
   */
  function goTo(index: number, my: number): Promise<void> {
    const step = STEPS[index];
    const alive = (): boolean => my === token;

    if (reduce) {
      applyInstant(index);
      return Promise.resolve();
    }

    const travel = index === current ? 0 : ms("travel");
    setProgress(index, travel);
    current = index;

    return sleep(travel).then(() => {
      if (!alive()) return undefined;
      setChrome(step, index);
      return runStep(step, index, alive);
    });
  }

  function runStep(step: Step, index: number, alive: () => boolean): Promise<void> {
    const targets = targetsOf(step);
    const moves = Array.from(targets.keys()).filter((id) => columnOf(id) !== targets.get(id));
    const ticks = step.done.filter((id) => {
      const el = taskEl(id);
      return !!el && !el.classList.contains("is-done") && !moves.includes(id);
    });

    if (!moves.length && !ticks.length) {
      applyInstant(index);
      return Promise.resolve();
    }

    // Phase 1: mark the affected tasks and take everything else back
    stage.classList.add("is-guiding");
    for (const id of moves.concat(ticks)) {
      const el = taskEl(id);
      if (!el) continue;
      el.classList.add("is-affected");
      const target = targets.get(id);
      if (target && moves.includes(id)) setBadge(el, target);
    }

    let chain = sleep(ms("highlight"));

    // Phase 2: set the check marks, one after the other
    for (const id of ticks) {
      chain = chain.then(() => {
        if (!alive()) return undefined;
        taskEl(id)?.classList.add("is-done");
        return sleep(ms("tick"));
      });
    }

    // Phase 3: let one task after the other travel
    moves.forEach((id, i) => {
      chain = chain.then(() => {
        if (!alive()) return undefined;
        const target = targets.get(id);
        if (!target) return undefined;
        return moveOne(id, target, step).then(() => {
          if (!alive() || i === moves.length - 1) return undefined;
          return sleep(ms("gap"));
        });
      });
    });

    // Phase 4: tidy up
    return chain.then(() => {
      if (!alive()) return undefined;
      clearMarks();
      for (const el of allTasks()) {
        el.classList.toggle("is-done", step.done.includes(el.dataset.id ?? ""));
      }
      refreshEmpties();
      refreshCounts();
      return sleep(ms("settle"));
    });
  }

  /* -------------------------------------------------------------------------
     Run
     ------------------------------------------------------------------------- */

  /* Replay and pause share one slot: whichever is on screen, the other is
     hidden. If the keyboard sits on the one about to be hidden, it is handed to
     the one taking its place, otherwise focus would drop to the body. Focus is
     only ever moved when the user pressed that very button, the autoplay never
     pulls it. */

  function play(from: number, trigger: "autoplay" | "replay"): void {
    const my = ++token;
    capture("reset_demo_started", { trigger });
    const wasOnReplay = document.activeElement === replayBtn;
    replayBtn.hidden = true;
    if (!reduce) {
      pauseBtn.hidden = false;
      if (wasOnReplay) pauseBtn.focus();
    }

    function next(i: number): void {
      if (my !== token) return;
      if (i >= STEPS.length) {
        const wasOnPause = document.activeElement === pauseBtn;
        replayBtn.hidden = false;
        pauseBtn.hidden = true;
        if (wasOnPause) replayBtn.focus();
        capture("reset_demo_completed", { trigger });
        return;
      }
      void goTo(i, my).then(() => {
        if (my !== token) return undefined;
        return sleep(ms("dwell")).then(() => next(i + 1));
      });
    }

    next(from);
  }

  /**
   * Once somebody has driven the demo by hand, the pending autostart is off the
   * table. Without this a station clicked while the section is still below the
   * threshold would be overrun by the autoplay a moment later.
   */
  function cancelAutoStart(): void {
    started = true;
    observer?.disconnect();
  }

  timeline.hidden = false;

  // A click on the timeline snaps hard to the step before and then plays
  // exactly that one step animated.
  timeline.addEventListener("click", (event) => {
    const target = event.target;
    if (!(target instanceof Element)) return;
    const button = target.closest<HTMLButtonElement>("button[data-step]");
    if (!button) return;
    const index = Number.parseInt(button.dataset.step ?? "", 10);
    if (Number.isNaN(index)) return;

    cancelAutoStart();
    setPaused(false);
    capture("reset_demo_step_selected", { step: index + 1 });
    const my = ++token;
    replayBtn.hidden = false;
    pauseBtn.hidden = true;

    if (index === 0 || reduce) {
      applyInstant(index);
      return;
    }
    applyInstant(index - 1);
    void goTo(index, my);
  });

  replayBtn.addEventListener("click", () => {
    cancelAutoStart();
    setPaused(false);
    applyInstant(0);
    play(0, "replay");
  });

  pauseBtn.addEventListener("click", () => {
    const next = !paused;
    setPaused(next);
    capture(next ? "reset_demo_paused" : "reset_demo_resumed", { step: current + 1 });
  });

  // The afterglow lives in CSS but should scale with SPEED
  stage.style.setProperty("--land-dur", `${ms("land")}ms`);

  applyInstant(0);

  // Reduced motion: no autostart and no travel. The timeline stations stay as
  // five buttons that jump straight to their state, and there is nothing
  // auto-playing left for a pause control to pause.
  if (reduce) {
    pauseBtn.remove();
    replayBtn.hidden = false;
    return;
  }
  if (!("IntersectionObserver" in window)) {
    replayBtn.hidden = false;
    return;
  }

  observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting || started) continue;
        cancelAutoStart();
        play(0, "autoplay");
      }
    },
    { threshold: 0.35 },
  );
  observer.observe(panes);
}

init();
