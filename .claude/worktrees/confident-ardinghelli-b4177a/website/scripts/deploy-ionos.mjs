#!/usr/bin/env node
/**
 * Deploy the built `dist/` directory to IONOS Webhosting Plus over SFTP/FTPS.
 *
 * Required env vars (set them via .env, GitHub Actions secrets, or your shell):
 *   IONOS_FTP_HOST       e.g. access-XXXXX.webspace-host.com
 *   IONOS_FTP_USER       e.g. u00000000
 *   IONOS_FTP_PASSWORD   the SFTP/FTPS password
 *   IONOS_FTP_REMOTE_DIR e.g. /  (defaults to "/")
 *
 * Usage: npm run build && npm run deploy:ionos
 */

import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";
import { Client } from "basic-ftp";
import { applyDawnyWebsiteEnv } from "./load-env.mjs";

applyDawnyWebsiteEnv();

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, "..");
const localDir = resolve(projectRoot, "dist");

if (!existsSync(localDir)) {
  console.error(`✗ ${localDir} not found. Run \`npm run build\` first.`);
  process.exit(1);
}

const host = process.env.IONOS_FTP_HOST;
const user = process.env.IONOS_FTP_USER;
const password = process.env.IONOS_FTP_PASSWORD;
const remoteDir = process.env.IONOS_FTP_REMOTE_DIR ?? "/";

if (!host || !user || !password) {
  console.error("✗ Missing IONOS_FTP_HOST / IONOS_FTP_USER / IONOS_FTP_PASSWORD env vars.");
  console.error("  Copy the repo-root .env.example to .env (or website/.env) and fill in the values.");
  process.exit(1);
}

const client = new Client(30_000);
client.ftp.verbose = false;

try {
  console.log(`→ Connecting to ${host} as ${user} (FTPS)…`);
  await client.access({
    host,
    user,
    password,
    secure: true,
    secureOptions: { rejectUnauthorized: false },
  });

  console.log(`→ Ensuring remote dir ${remoteDir}`);
  await client.ensureDir(remoteDir);

  console.log(`→ Uploading ${localDir} → ${remoteDir}`);
  client.trackProgress((info) => {
    if (info.name) {
      process.stdout.write(`  ${info.type.padEnd(8)} ${info.name}\n`);
    }
  });
  await client.uploadFromDir(localDir, remoteDir);
  client.trackProgress();

  console.log("✓ Deploy complete.");
} catch (err) {
  console.error("✗ Deploy failed:", err.message);
  process.exitCode = 1;
} finally {
  client.close();
}
