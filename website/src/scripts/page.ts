/**
 * The site's only page-level script (the guided demo has its own file).
 *
 *  1. Reveal-on-scroll for `[data-reveal]` elements, via a single
 *     IntersectionObserver that unobserves each element once shown. Nothing is
 *     wired to the scroll event (see concept 7.10). Progressive enhancement:
 *     this script adds `reveal-ready` to <html>, and only then does the CSS
 *     hide the elements. No JS or reduced motion means everything stays visible.
 *  2. Deep-link opener: if the URL hash points at a `<details>` (a FAQ item),
 *     open it and scroll it into view. Stateless, no storage.
 */

const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

function initReveal(): void {
  const els = document.querySelectorAll<HTMLElement>("[data-reveal]");
  if (!els.length || reduceMotion || !("IntersectionObserver" in window)) return;

  document.documentElement.classList.add("reveal-ready");

  const io = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        entry.target.classList.add("is-revealed");
        io.unobserve(entry.target);
      }
    },
    { threshold: 0.15, rootMargin: "0px 0px -10% 0px" },
  );
  els.forEach((el) => io.observe(el));
}

function openHashTarget(): void {
  const id = decodeURIComponent(window.location.hash.replace(/^#/, ""));
  if (!id) return;
  const el = document.getElementById(id);
  if (el instanceof HTMLDetailsElement) {
    el.open = true;
    el.scrollIntoView({ behavior: reduceMotion ? "auto" : "smooth", block: "center" });
  }
}

initReveal();
openHashTarget();
window.addEventListener("hashchange", openHashTarget);
