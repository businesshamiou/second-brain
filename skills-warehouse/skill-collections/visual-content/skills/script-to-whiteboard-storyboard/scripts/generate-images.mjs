#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { spawn } from "node:child_process";

function parseArgs(items) {
  const result = {};
  for (let i = 0; i < items.length; i++) {
    if (!items[i].startsWith("--")) continue;
    const key = items[i].slice(2);
    result[key] = items[i + 1]?.startsWith("--") || items[i + 1] === undefined ? true : items[++i];
  }
  return result;
}

const args = parseArgs(process.argv.slice(2));
if (!args.manifest || !args.output) {
  console.error("Usage: generate-images.mjs --manifest storyboard.json --output images [--style-ref style.png] [--mascot-ref mascot.png] [--concurrency 4] [--ids S001,S002] [--dry-run]");
  process.exit(2);
}

const manifestPath = path.resolve(args.manifest);
const outputDir = path.resolve(args.output);
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
const selected = args.ids ? new Set(String(args.ids).split(",").map(value => value.trim()).filter(Boolean)) : null;
const beats = manifest.beats.filter(beat => !selected || selected.has(beat.id));
const concurrency = Math.max(1, Number(args.concurrency || 4));
const styleRef = args["style-ref"] ? path.resolve(args["style-ref"]) : null;
const mascotRef = args["mascot-ref"] ? path.resolve(args["mascot-ref"]) : null;

for (const [label, file] of [["style reference", styleRef], ["mascot reference", mascotRef]]) {
  if (file && !fs.existsSync(file)) throw new Error(`Missing ${label}: ${file}`);
}
fs.mkdirSync(outputDir, { recursive: true });
fs.mkdirSync(path.join(path.dirname(outputDir), "prompts"), { recursive: true });

function run(command, commandArgs) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, commandArgs, { stdio: ["ignore", "pipe", "pipe"] });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", chunk => stdout += chunk);
    child.stderr.on("data", chunk => stderr += chunk);
    child.on("error", reject);
    child.on("close", code => code === 0 ? resolve(stdout) : reject(new Error(`${command} exited ${code}: ${stderr || stdout}`)));
  });
}

function extractUrl(text) {
  const urls = text.match(/https?:\/\/[^\s"']+/g) || [];
  return urls.reverse().find(url => /\.(png|jpe?g)(\?|$)/i.test(url)) || urls[0];
}

async function generate(beat) {
  const imagePath = path.join(outputDir, `${beat.id}.png`);
  const promptPath = path.join(path.dirname(outputDir), "prompts", `${beat.id}.txt`);
  fs.writeFileSync(promptPath, `${beat.prompt.trim()}\n`);
  if (fs.existsSync(imagePath) && fs.statSync(imagePath).size > 0) {
    console.log(`[skip] ${beat.id}`);
    return;
  }
  const commandArgs = ["generate", "create", "gpt_image_2", "--prompt", beat.prompt, "--aspect_ratio", "16:9", "--resolution", "2k", "--quality", "high", "--wait", "--wait-timeout", "20m"];
  if (styleRef) commandArgs.push("--image", styleRef);
  if (mascotRef) commandArgs.push("--image", mascotRef);
  if (args["dry-run"]) {
    console.log(`[dry-run] ${beat.id} -> ${imagePath}\n${beat.prompt}\n`);
    return;
  }
  console.log(`[start] ${beat.id}`);
  const output = await run("higgsfield", commandArgs);
  const url = extractUrl(output);
  if (!url) throw new Error(`${beat.id}: no image URL found in Higgsfield output`);
  const response = await fetch(url);
  if (!response.ok) throw new Error(`${beat.id}: download failed with HTTP ${response.status}`);
  const tempPath = path.join(os.tmpdir(), `${beat.id}-${Date.now()}.png`);
  fs.writeFileSync(tempPath, Buffer.from(await response.arrayBuffer()));
  fs.renameSync(tempPath, imagePath);
  console.log(`[done] ${beat.id} -> ${imagePath}`);
}

let next = 0;
const failures = [];
async function worker() {
  while (next < beats.length) {
    const beat = beats[next++];
    try { await generate(beat); }
    catch (error) { failures.push(`${beat.id}: ${error.message}`); console.error(`[failed] ${beat.id}: ${error.message}`); }
  }
}

await Promise.all(Array.from({ length: Math.min(concurrency, beats.length || 1) }, worker));
if (failures.length) {
  console.error(`${failures.length} generation(s) failed. Re-run the same command to resume.`);
  process.exit(1);
}
console.log(`${args["dry-run"] ? "Prepared" : "Completed"} ${beats.length} beat(s).`);
