import assert from "node:assert/strict";
import { test } from "node:test";
import { createRequire } from "node:module";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";

// Run with NODE_PATH pointing at Pi's node_modules (e.g. the Home Manager profile).
const require = createRequire(import.meta.url);
const esbuild = require("esbuild");
const modules = `${dirname(dirname(require.resolve("esbuild")))}/../`;
const output = join(await mkdtemp(join(tmpdir(), "pi-vim-ex-")), "editor.mjs");
await esbuild.build({
  entryPoints: [new URL("./vim-editor.ts", import.meta.url).pathname],
  outfile: output,
  bundle: true,
  platform: "node",
  format: "esm",
  packages: "external",
  resolveExtensions: [".ts", ".js", ".json"],
  plugins: [{
    name: "pi-imports",
    setup(build) {
      build.onResolve({ filter: /^@earendil-works\/pi-(coding-agent|tui)$/ }, ({ path }) => ({
        path: `${modules}${path}/dist/index.js`,
        external: true,
      }));
    },
  }],
});
const { VimEditor } = await import(output);

function editor() {
  const instance = new VimEditor({ requestRender() {} }, {}, { matches() { return false; } });
  instance.focused = true;
  return instance;
}

function type(editor, text) {
  for (const char of text) editor.handleInput(char);
}

function label(editor) {
  return editor.render(40)[0];
}

test("normal-mode colon opens the input box, cancels and restores the draft", () => {
  const e = editor();
  e.setText("draft");
  e.handleInput("\x1b");
  e.handleInput(":");
  assert.equal(e.vimState.mode, "command-line");
  assert.equal(e.getText(), ":");
  type(e, "help");
  assert.equal(e.getText(), ":help");
  e.handleInput("\x1b");
  assert.equal(e.getText(), "draft");
  assert.equal(e.vimState.mode, "normal");
  e.handleInput(":");
  e.handleInput("\x7f");
  assert.equal(e.getText(), "draft");
  assert.equal(e.vimState.mode, "normal");
});

test("ex commands and forwarded slash commands use the input editor", () => {
  const e = editor();
  e.handleInput("\x1b");
  e.setText("draft");
  e.handleInput(":");
  type(e, "w");
  e.handleInput("\r");
  assert.equal(e.getText(), "draft");
  assert.equal(e.vimState.mode, "normal");

  e.handleInput(":");
  type(e, "help");
  // The base editor submits via its onSubmit callback.
  let submitted;
  e.onSubmit = (text) => { submitted = text; };
  e.handleInput("\r");
  assert.equal(submitted, "/help");
  assert.equal(e.getText(), "draft");
});

test("colon typed into an insert-mode prompt still dispatches Pi commands", () => {
  const e = editor();
  let submitted;
  e.onSubmit = (text) => { submitted = text; };
  type(e, ":help");
  e.handleInput("\r");
  assert.equal(submitted, "/help");
});

test("prompt accents follow insert, normal, visual and command modes", () => {
  const e = editor();
  assert.match(label(e), /\x1b\[38;2;159;201;117m─+ INSERT /);
  e.handleInput("\x1b");
  assert.match(label(e), /\x1b\[38;2;125;174;163m─+ NORMAL /);
  e.handleInput("v");
  assert.match(label(e), /\x1b\[38;2;231;138;78m─+ VISUAL /);
  e.handleInput(":");
  assert.match(label(e), /\x1b\[38;2;216;166;87m─+ COMMAND /);
});
