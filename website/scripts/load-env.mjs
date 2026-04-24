/**
 * Minimal .env loader (no dependency): merges root + website env files.
 * Precedence: existing process.env (shell / CI) wins; then repo-root .env;
 * then website/.env (overrides root for the same key).
 */
import { existsSync, readFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const websiteRoot = resolve(__dirname, "..");
const repoRoot = resolve(websiteRoot, "..");

/**
 * @param {string} filePath
 * @returns {Record<string, string>}
 */
function parseEnvFile(filePath) {
  const out = {};
  if (!existsSync(filePath)) return out;
  const text = readFileSync(filePath, "utf8");
  for (const rawLine of text.split("\n")) {
    const line = rawLine.replace(/\r$/, "").trim();
    if (!line || line.startsWith("#")) continue;
    const eq = line.indexOf("=");
    if (eq <= 0) continue;
    const key = line.slice(0, eq).trim();
    if (!key || key.startsWith("#")) continue;
    let val = line.slice(eq + 1).trim();
    const q =
      (val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"));
    if (q && val.length >= 2) val = val.slice(1, -1);
    out[key] = val;
  }
  return out;
}

export function applyDawnyWebsiteEnv() {
  const rootVars = parseEnvFile(resolve(repoRoot, ".env"));
  const siteVars = parseEnvFile(resolve(websiteRoot, ".env"));
  const merged = { ...rootVars, ...siteVars };
  for (const [key, value] of Object.entries(merged)) {
    if (process.env[key] === undefined) process.env[key] = value;
  }
}
