// Mission 230, step 7 (Owner, 2026-09-25 13:35: "automatiser le test gum"):
// the installer's questionnaire, displayed by the REAL gum, driven in a REAL
// terminal (a pseudo-terminal opened by @microsoft/tui-test).
//
// Everything the existing tests could not reach lives here: tests/test-install-
// gum-branch.sh proves the branch with a FAKE gum and a forced TTY, because no
// test has a terminal. This one has one.
//
// Run by tests/test-gum-questionnaire-real-terminal.sh, never on its own: that
// script finds gum and tui-test, refuses to download anything, prepares the
// sandbox and reads USER.md back afterwards. Inputs, all required:
//   SB_GUM_BASH        the bash to run the installer with
//   SB_GUM_REPO        the Vault to install from (--source)
//   SB_GUM_TEST_ROOT   --test-root: every write stays under it
//   SB_GUM_OUT         folder where the recording is written
//
// The nine screens, in the questionnaire's order, are the ones
// tests/test-install-gum-branch.sh lists; the accented answer is the same,
// « La simplicité », and the driver checks it byte for byte in USER.md.

import fs from "node:fs";
import path from "node:path";
import { test, expect } from "@microsoft/tui-test";

const BASH = process.env.SB_GUM_BASH;
const REPO = process.env.SB_GUM_REPO;
const ROOT = process.env.SB_GUM_TEST_ROOT;
const OUT = process.env.SB_GUM_OUT;
const COLUMNS = 120;
const ROWS = 32;
// Time allowed for one screen to appear. Generous on purpose: between two
// questions the installer checks its prerequisites, clones a Vault, deploys an
// assistant and creates a project.
const STEP_TIMEOUT = Number(process.env.SB_GUM_STEP_TIMEOUT || 300000);

for (const [name, value] of Object.entries({ SB_GUM_BASH: BASH, SB_GUM_REPO: REPO, SB_GUM_TEST_ROOT: ROOT, SB_GUM_OUT: OUT })) {
  if (!value) throw new Error(`${name} is not set: this file is run by tests/test-gum-questionnaire-real-terminal.sh`);
}

// The nine screens: a fragment of the question that is enough to recognise it,
// and the answer typed into gum. A blank answer accepts the default shown.
const SCREENS = [
  { key: "language", match: "Language / Langue / Idioma", answer: "FR" },
  { key: "assistant-name", match: "Quel nom veux-tu donner", answer: "Brian" },
  { key: "workspace", match: "Où doit vivre ton espace de travail", answer: "" },
  { key: "first-name", match: "Quel est ton prénom", answer: "Ana" },
  { key: "activity", match: "Que fais-tu, en une phrase", answer: "Construire un système personnel" },
  { key: "ai-tools", match: "Comment travailles-tu avec l", answer: "" },
  { key: "what-matters", match: "Qu'est-ce qui compte le plus", answer: "La simplicité" },
  { key: "first-project", match: "Créer un premier projet maintenant", answer: "o" },
  { key: "first-project-name", match: "Nom du premier projet", answer: "premier-projet" },
];

// The installer is the pty's program, launched directly -- never through
// `bash -c "bash ..."`, which is run with the PATH cmd.exe hands down and does
// not find a second bash there (measured: an empty screen, nothing launched).
test.use({
  program: {
    file: BASH,
    args: [`${REPO}/install.sh`, "--source", REPO, "--test-mode", "--test-root", ROOT],
  },
  rows: ROWS,
  columns: COLUMNS,
});

test("le questionnaire gum, neuf écrans dans un vrai terminal", async ({ terminal }) => {
  const started = Date.now();
  const frames = [];
  const seen = [];
  const capture = (label) => {
    const screen = terminal
      .getViewableBuffer()
      .map((row) => row.join("").replace(/\s+$/, ""));
    frames.push({ at: (Date.now() - started) / 1000, label, screen });
  };

  capture("start");
  for (const screen of SCREENS) {
    // Auto-wait: the assertion polls the rendered terminal until the question
    // gum draws is there, so the order below IS the order measured. The
    // timeout is given on every matcher: tui-test 0.0.4 loads its config file
    // in the runner process only, so a worker falls back to 5 s -- far too
    // short, the installer clones a Vault and creates a project between two
    // screens (measured: the prerequisites step alone takes about 45 s).
    await expect(terminal.getByText(screen.match)).toBeVisible({ timeout: STEP_TIMEOUT });
    seen.push(screen.key);
    capture(screen.key);
    terminal.submit(screen.answer);
  }

  // The last sentence of the installer, and the assistant's signature.
  await expect(terminal.getByText("Installé, tout est en place.")).toBeVisible({ timeout: STEP_TIMEOUT });
  capture("verdict");
  await expect(terminal.getByText("— Brian")).toBeVisible({ timeout: STEP_TIMEOUT });
  capture("signature");

  // The recording the Owner watches: asciinema v2 (asciinema play, or any
  // asciinema-player). One entry per screen -- clear, home, then the screen.
  fs.mkdirSync(OUT, { recursive: true });
  const header = {
    version: 2,
    width: COLUMNS,
    height: ROWS,
    timestamp: Math.floor(started / 1000),
    title: "Second Brain -- questionnaire gum, vrai terminal (Mission 230)",
    env: { TERM: "xterm-256color", SHELL: BASH },
  };
  const lines = [JSON.stringify(header)];
  for (const frame of frames) {
    const data = "\u001b[2J\u001b[H" + frame.screen.join("\r\n") + "\r\n";
    lines.push(JSON.stringify([frame.at, "o", data]));
    // Each screen stays on for a moment, so the replay is watchable.
    lines.push(JSON.stringify([frame.at + 1.2, "o", ""]));
  }
  fs.writeFileSync(path.join(OUT, "gum-questionnaire.cast"), lines.join("\n") + "\n", "utf8");
  fs.writeFileSync(
    path.join(OUT, "screens-seen.json"),
    JSON.stringify({ seen, expected: SCREENS.map((s) => s.key) }, null, 2),
    "utf8"
  );
  fs.writeFileSync(
    path.join(OUT, "screens.txt"),
    frames.map((f) => `=== ${f.label} (${f.at.toFixed(2)}s) ===\n${f.screen.join("\n")}`).join("\n\n"),
    "utf8"
  );

  expect(seen).toEqual(SCREENS.map((s) => s.key));
});
