#!/usr/bin/env node
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import sharp from "sharp";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, "..");
const outputPath = resolve(projectRoot, "public/og-image.png");

const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#050d20"/>
      <stop offset="0.6" stop-color="#0b1733"/>
      <stop offset="1" stop-color="#142547"/>
    </linearGradient>
    <radialGradient id="sun" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#fcc97a"/>
      <stop offset="0.55" stop-color="#f5b042"/>
      <stop offset="1" stop-color="#d8902a"/>
    </radialGradient>
    <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#f5b042" stop-opacity="0.55"/>
      <stop offset="0.5" stop-color="#f5b042" stop-opacity="0.18"/>
      <stop offset="1" stop-color="#f5b042" stop-opacity="0"/>
    </radialGradient>
  </defs>

  <rect width="1200" height="630" fill="url(#bg)"/>

  <!-- Stars -->
  <g fill="white" opacity="0.7">
    <circle cx="120" cy="80" r="1.4"/>
    <circle cx="320" cy="140" r="1"/>
    <circle cx="540" cy="60" r="1.6"/>
    <circle cx="780" cy="120" r="1.1"/>
    <circle cx="1020" cy="80" r="1.3"/>
    <circle cx="1140" cy="180" r="0.9"/>
  </g>

  <!-- Glow -->
  <ellipse cx="900" cy="500" rx="380" ry="380" fill="url(#glow)"/>

  <!-- Sun -->
  <circle cx="900" cy="500" r="130" fill="url(#sun)"/>
  <circle cx="900" cy="500" r="130" fill="none" stroke="#fcc97a" stroke-width="3" stroke-opacity="0.7"/>

  <!-- Horizon -->
  <line x1="60" y1="500" x2="1140" y2="500" stroke="#1a2c54" stroke-width="3" stroke-linecap="round"/>

  <!-- Eyebrow -->
  <text x="80" y="160" fill="#fcc97a" font-family="-apple-system, system-ui, sans-serif" font-size="22" font-weight="600" letter-spacing="4">DAWNY · iOS</text>

  <!-- Headline -->
  <text x="80" y="260" fill="white" font-family="-apple-system, system-ui, sans-serif" font-size="68" font-weight="700" letter-spacing="-1.5">A task app that deletes</text>
  <text x="80" y="340" fill="white" font-family="-apple-system, system-ui, sans-serif" font-size="68" font-weight="700" letter-spacing="-1.5">yesterday's tasks.</text>
  <text x="80" y="420" fill="#f5b042" font-family="-apple-system, system-ui, sans-serif" font-size="68" font-weight="700" letter-spacing="-1.5">On purpose.</text>

  <!-- Sub -->
  <text x="80" y="500" fill="rgba(255,255,255,0.65)" font-family="-apple-system, system-ui, sans-serif" font-size="26">No overdue. No carryover. No guilt.</text>

  <!-- URL -->
  <text x="80" y="580" fill="rgba(255,255,255,0.4)" font-family="-apple-system, ui-monospace, monospace" font-size="20" letter-spacing="2">dawny.app</text>
</svg>
`;

mkdirSync(dirname(outputPath), { recursive: true });

await sharp(Buffer.from(svg))
  .png({ quality: 90, compressionLevel: 9 })
  .toFile(outputPath);

console.log(`Generated ${outputPath}`);
