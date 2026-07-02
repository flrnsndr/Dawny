#!/usr/bin/env node
import { writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import QRCode from "qrcode";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, "..");
const outputPath = resolve(projectRoot, "public/assets/qr-appstore.svg");
const url = "https://apps.apple.com/app/id6762262959";

const svg = await QRCode.toString(url, {
  type: "svg",
  errorCorrectionLevel: "M",
  margin: 1,
  color: {
    dark: "#0B1733",
    light: "#FFFFFF00",
  },
  width: 240,
});

const cleaned = svg
  .replace(/<\?xml[^>]*\?>\n?/, "")
  .replace(/<!DOCTYPE[^>]*>\n?/, "")
  .replace(/shape-rendering="crispEdges"/, 'shape-rendering="crispEdges" role="img" aria-label="App Store QR code"');

mkdirSync(dirname(outputPath), { recursive: true });
writeFileSync(outputPath, cleaned, "utf8");
console.log(`Generated ${outputPath}`);
