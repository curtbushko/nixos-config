#!/usr/bin/env bash
set -euo pipefail

[[ $# == 3 ]] || {
	printf 'Usage: %s <config.json> <pi-herdr-agents-package> <node-24-binary>\n' "$0" >&2
	exit 1
}

# Exercise upstream loaders without loading credentials or spawning agents.
"$3" --experimental-strip-types --input-type=module - "$1" "$2" <<'JS'
import assert from 'node:assert/strict';
import { dirname, join } from 'node:path';
import { pathToFileURL } from 'node:url';

const [configPath, packagePath] = process.argv.slice(2);
const configDir = dirname(configPath);
const examplePath = join(packagePath, 'config.json.example');
const core = join(packagePath, 'maestro/core');
const status = await import(pathToFileURL(join(core, 'status.ts')));
assert.equal(status.loadStatusConfig(configPath, examplePath).enabled, true);
for (const [file, loader] of [
  ['model', 'loadModelConfig'],
  ['role', 'loadRoleConfig'],
  ['persistent', 'loadPersistentConfig'],
  ['supervision', 'loadSupervisionConfig'],
  ['sidebar', 'loadSidebarConfig'],
  ['pane', 'loadPaneConfig'],
]) {
  const module = await import(pathToFileURL(join(core, 'config', `${file}-config.ts`)));
  const parsed = module[loader](configDir, examplePath);
  if (file === 'pane') assert.equal(parsed.mode, 'tab');
}
console.log('HerdR agents config loaders passed');
JS
