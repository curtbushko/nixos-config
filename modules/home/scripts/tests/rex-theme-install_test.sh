#!/usr/bin/env bash
set -euo pipefail

for command in bash cmp dirname ln mkdir mktemp mv; do
	command -v "$command" >/dev/null || {
		printf '%s is required\n' "$command" >&2
		exit 1
	}
done
script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/rex-theme-install"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
work="$(mktemp -d)"
cleanup() {
	mkdir -p "$repo/.trash"
	mv "$work" "$repo/.trash/"
}
trap cleanup EXIT
source="$work/source theme"
destination="$work/config with spaces/rex/themes/flair"
printf 'foreground = #abcdef\n' >"$source"

# Fresh install produces a real file, not a symlink to the source.
bash "$script" "$source" "$destination"
[[ -f "$destination" && ! -L "$destination" ]]
cmp "$source" "$destination"
printf 'changed source\n' >"$source"
if cmp -s "$source" "$destination"; then exit 1; fi

# Updates preserve the previous file in .trash.
bash "$script" "$source" "$destination"
cmp "$source" "$destination"
previous=("${destination%/*}"/.trash/rex-theme.*/previous)
[[ ${#previous[@]} -eq 1 ]]
printf 'foreground = #abcdef\n' >"$work/expected"
cmp "$work/expected" "${previous[0]}"

# Unchanged activation does not make another backup.
bash "$script" "$source" "$destination"
previous=("${destination%/*}"/.trash/rex-theme.*/previous)
[[ ${#previous[@]} -eq 1 ]]

# A link with identical contents must still be replaced, without altering its target.
mv "$destination" "$work/old-file"
ln -s "$source" "$destination"
bash "$script" "$source" "$destination"
[[ -f "$destination" && ! -L "$destination" ]]
cmp "$source" "$destination"
previous=("${destination%/*}"/.trash/rex-theme.*/previous)
[[ ${#previous[@]} -eq 2 ]]
links=0
for file in "${previous[@]}"; do
	if [[ -L "$file" ]]; then links=$((links + 1)); fi
done
[[ "$links" -eq 1 ]]

# Broken links are also backed up and replaced.
mv "$destination" "$work/old-file-2"
ln -s "$work/nonexistent" "$destination"
bash "$script" "$source" "$destination"
[[ -f "$destination" && ! -L "$destination" ]]
cmp "$source" "$destination"

# Migration can use the existing symlink as both source and destination.
mv "$destination" "$work/old-file-3"
ln -s "$source" "$destination"
bash "$script" "$destination" "$destination"
[[ -f "$destination" && ! -L "$destination" ]]
cmp "$source" "$destination"

# Invalid inputs must fail without changing an existing theme.
if bash "$script" "$work/missing-source" "$destination"; then exit 1; fi
cmp "$source" "$destination"
mkdir "$work/directory-target"
if bash "$script" "$source" "$work/directory-target"; then exit 1; fi
if bash "$script"; then exit 1; fi
printf 'Rex regular-file theme installation: passed\n'
