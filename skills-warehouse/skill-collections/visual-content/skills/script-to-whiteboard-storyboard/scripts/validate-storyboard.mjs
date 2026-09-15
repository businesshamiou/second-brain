#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const args = Object.fromEntries(process.argv.slice(2).reduce((pairs, item, index, all) => {
  if (item.startsWith("--")) pairs.push([item.slice(2), all[index + 1]]);
  return pairs;
}, []));

if (!args.manifest) {
  console.error("Usage: validate-storyboard.mjs --manifest /absolute/path/storyboard.json [--images /absolute/path/images]");
  process.exit(2);
}

const manifestPath = path.resolve(args.manifest);
const data = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
const allowedModes = new Set(["single-scene", "metaphor", "contrast", "flow-3", "pipeline-4", "journey", "system-map", "collection", "hierarchy", "loop", "device-sync", "checklist"]);
const errors = [];
const ids = new Set();

if (!data.projectTitle?.trim()) errors.push("projectTitle is required");
if (!Array.isArray(data.beats) || data.beats.length === 0) errors.push("beats must be a non-empty array");

for (const [index, beat] of (data.beats || []).entries()) {
  const label = beat.id || `beat ${index + 1}`;
  if (!/^S\d{3,}$/.test(beat.id || "")) errors.push(`${label}: id must match S001 style`);
  if (ids.has(beat.id)) errors.push(`${label}: duplicate id`);
  ids.add(beat.id);
  for (const field of ["script", "title", "visualClaim", "direction", "prompt"]) {
    if (typeof beat[field] !== "string" || !beat[field].trim()) errors.push(`${label}: ${field} is required`);
  }
  if (!allowedModes.has(beat.visualMode)) errors.push(`${label}: unsupported visualMode ${JSON.stringify(beat.visualMode)}`);
  if (!Array.isArray(beat.labels)) errors.push(`${label}: labels must be an array`);
  if (beat.title?.trim().split(/\s+/).length > 9) errors.push(`${label}: title exceeds 9 words`);
  if ((beat.labels || []).length > 5) errors.push(`${label}: more than 5 labels`);
  if (beat.prompt && !beat.prompt.includes(beat.title)) errors.push(`${label}: prompt does not contain exact title`);
  if (beat.prompt && !/Do not add any other words|no other text/i.test(beat.prompt)) errors.push(`${label}: prompt lacks an explicit no-extra-text constraint`);
  if (beat.prompt && !/16:9/.test(beat.prompt)) errors.push(`${label}: prompt does not specify 16:9`);
}

if (args.images && Array.isArray(data.beats)) {
  const imageDir = path.resolve(args.images);
  for (const beat of data.beats) {
    const imagePath = path.join(imageDir, `${beat.id}.png`);
    if (!fs.existsSync(imagePath) || fs.statSync(imagePath).size === 0) errors.push(`${beat.id}: missing image ${imagePath}`);
  }
}

if (errors.length) {
  console.error(`Storyboard validation failed with ${errors.length} error(s):`);
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log(`Storyboard valid: ${data.beats.length} beats in ${manifestPath}`);
