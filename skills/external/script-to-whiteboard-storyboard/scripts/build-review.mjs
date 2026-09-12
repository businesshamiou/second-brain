#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

function parseArgs(items) {
  const result = {};
  for (let i = 0; i < items.length; i++) if (items[i].startsWith("--")) result[items[i].slice(2)] = items[++i];
  return result;
}
const args = parseArgs(process.argv.slice(2));
if (!args.manifest || !args.images || !args.output) {
  console.error("Usage: build-review.mjs --manifest storyboard.json --images images --output review.html");
  process.exit(2);
}
const manifest = JSON.parse(fs.readFileSync(path.resolve(args.manifest), "utf8"));
const imageDir = path.resolve(args.images);
const outputPath = path.resolve(args.output);
const esc = value => String(value ?? "").replace(/[&<>"']/g, char => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[char]));
const toUrl = file => pathToFileURL(file).href;

const cards = manifest.beats.map(beat => {
  const imagePath = path.join(imageDir, `${beat.id}.png`);
  const image = fs.existsSync(imagePath) ? `<img src="${toUrl(imagePath)}" alt="${esc(beat.title)}">` : `<div class="missing">Image not generated yet<br>${esc(beat.id)}.png</div>`;
  return `<article id="${esc(beat.id)}"><div class="copy"><div class="eyebrow">${esc(beat.id)} · ${esc(beat.visualMode)}</div><h2>${esc(beat.title)}</h2><blockquote>${esc(beat.script)}</blockquote><h3>Visual direction</h3><p>${esc(beat.direction)}</p><details><summary>Generation prompt</summary><pre>${esc(beat.prompt)}</pre></details></div><div class="visual">${image}</div></article>`;
}).join("\n");

const html = `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${esc(manifest.projectTitle)} — Storyboard Review</title><style>
:root{font-family:Inter,ui-sans-serif,system-ui,sans-serif;color:#181818;background:#f1eee8}*{box-sizing:border-box}body{margin:0}header{position:sticky;top:0;z-index:2;background:rgba(241,238,232,.94);backdrop-filter:blur(12px);border-bottom:1px solid #d8d1c7;padding:18px 4vw;display:flex;justify-content:space-between;align-items:end}h1{font-size:clamp(24px,3vw,44px);margin:0;letter-spacing:-.04em}.count{color:#756d64}main{width:min(1500px,94vw);margin:28px auto 80px;display:grid;gap:24px}article{display:grid;grid-template-columns:minmax(300px,.78fr) minmax(520px,1.4fr);background:#fff;border:1px solid #ddd5cb;border-radius:18px;overflow:hidden;box-shadow:0 10px 30px #6f635419}.copy{padding:30px}.visual{background:#faf9f6;display:grid;place-items:center;min-height:420px;border-left:1px solid #e4ddd4}.visual img{width:100%;height:100%;object-fit:contain}.eyebrow{font:700 12px/1.2 ui-monospace,monospace;color:#ee5b91;text-transform:uppercase;letter-spacing:.08em}h2{font-size:30px;line-height:1;margin:10px 0 22px}blockquote{margin:0 0 28px;border-left:4px solid #f5d95d;padding:4px 0 4px 16px;font:600 18px/1.5 Georgia,serif}h3{font-size:12px;text-transform:uppercase;letter-spacing:.08em;margin:0 0 8px;color:#756d64}p{line-height:1.55}details{margin-top:22px}summary{cursor:pointer;font-weight:700}pre{white-space:pre-wrap;font:12px/1.55 ui-monospace,monospace;background:#f6f3ee;padding:16px;border-radius:10px;max-height:360px;overflow:auto}.missing{color:#8a8178;text-align:center}.progress{height:4px;position:fixed;left:0;top:0;background:#ee5b91;z-index:3;width:calc(100% * var(--scroll,0))}@media(max-width:900px){article{grid-template-columns:1fr}.visual{border-left:0;border-top:1px solid #e4ddd4;min-height:260px}header{position:static}}
</style></head><body><div class="progress"></div><header><div><div class="eyebrow">Side-by-side review</div><h1>${esc(manifest.projectTitle)}</h1></div><div class="count">${manifest.beats.length} visual beats</div></header><main>${cards}</main><script>addEventListener('scroll',()=>document.documentElement.style.setProperty('--scroll',scrollY/(document.documentElement.scrollHeight-innerHeight)))</script></body></html>`;
fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, html);
console.log(`Review page written: ${outputPath}`);
