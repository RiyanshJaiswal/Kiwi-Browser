#!/usr/bin/env bash
# Prepare a matching Chromium checkout using the tracked Kiwi source overlay.
set -euo pipefail
if [[ $# -lt 2 || $# -gt 3 || ( $# == 3 && $3 != --apply ) ]]; then
  echo 'Usage: bash prepare_kiwi_source.sh KIWI_REPO CHROMIUM_SRC [--apply]' >&2
  exit 2
fi
kiwi=$(cd "$1" && pwd -P)
chromium=$(cd "$2" && pwd -P)
[[ "$kiwi" != "$chromium" ]] || { echo 'Source and destination must differ.' >&2; exit 1; }
for repo in "$kiwi" "$chromium"; do
  [[ $(git -C "$repo" rev-parse --show-toplevel) == "$repo" ]] || { echo "Not a Git root: $repo" >&2; exit 1; }
  [[ -z $(git -C "$repo" status --porcelain --untracked-files=no) ]] || { echo "Tracked changes present: $repo" >&2; exit 1; }
done
version() {
  local path=$1 prefix=$2 k v out=''
  for k in MAJOR MINOR BUILD PATCH; do
    v=$(sed -n "s/^${prefix}${k}=\([0-9][0-9]*\)$/\1/p" "$path")
    [[ $v =~ ^[0-9]+$ ]] || return 1
    out+="${out:+.}$v"
  done
  printf '%s\n' "$out"
}
expected=$(version "$kiwi/CHROMIUM_VERSION" CHROMIUM_)
actual=$(version "$chromium/chrome/VERSION" '')
[[ "$expected" == "$actual" ]] || { echo "Version mismatch: Kiwi requires $expected; checkout is $actual" >&2; exit 1; }
for p in .gn DEPS BUILD.gn build/config/BUILDCONFIG.gn; do
  [[ -f "$chromium/$p" ]] || { echo "Missing full Chromium source: $p" >&2; exit 1; }
done
paths=(base chrome components content extensions net remoting services third_party ui)
for p in "${paths[@]}"; do
  git -C "$kiwi" cat-file -e "HEAD:$p" || exit 1
done
printf 'Kiwi overlay: %s\nChromium: %s\nVersion: %s\n' "$(git -C "$kiwi" rev-parse HEAD)" "$(git -C "$chromium" rev-parse HEAD)" "$actual"
printf 'Overlay roots: %s\n' "${paths[*]}"
if [[ ${3:-} != --apply ]]; then
  echo 'Dry run passed. No files changed. Use --apply on a disposable checkout.'
  exit 0
fi
# Apply only tracked source files; never replace .git, DEPS or workflow metadata.
# Use a disposable checkout: this intentionally replaces overlapping source files.
git -C "$kiwi" archive --format=tar HEAD -- "${paths[@]}" | tar -xf - -C "$chromium"
echo 'Overlay applied. Review git diff and run build checks; no APK built.'
