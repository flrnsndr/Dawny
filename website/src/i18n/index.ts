import en from "./en.json";
import de from "./de.json";

export const languages = {
  en: "English",
  de: "Deutsch",
} as const;

export const defaultLang: Lang = "en";

export type Lang = "en" | "de";
export type Dict = typeof en;

const dicts: Record<Lang, Dict> = { en, de: de as Dict };

export function getDict(lang: Lang): Dict {
  return dicts[lang] ?? dicts[defaultLang];
}

export function getLangFromUrl(url: URL): Lang {
  const [, segment] = url.pathname.split("/");
  if (segment === "de" || segment === "en") return segment;
  return defaultLang;
}

export function localizedPath(lang: Lang, path = ""): string {
  const clean = path.replace(/^\//, "");
  return `/${lang}/${clean}`.replace(/\/+$/g, clean ? "" : "/");
}

export function alternateLang(lang: Lang): Lang {
  return lang === "en" ? "de" : "en";
}

export const TESTFLIGHT_URL = "https://testflight.apple.com/join/h9JSWasd";
export const GITHUB_URL = "https://github.com/flrnsndr/Dawny";
export const CONTACT_EMAIL = "info@dawnyapp.com";
