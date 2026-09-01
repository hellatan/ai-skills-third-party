#!/usr/bin/env bash
# Symlinks each third-party skill into ~/.claude/skills/<skill-name> and prunes
# links to skills this collection no longer carries.
#
# Modeled on ~/projects/claude-skills/scripts/install.sh, with two differences:
# this collection vendors OTHER people's skills (skills/ holds symlinks into
# vendor/, which is the upstream checkout or extract), and it isn't a git clone,
# so there are no hooks to auto-resync — re-run this script after updating a
# vendor/ source.
#
# Run from anywhere: ./scripts/install.sh [--quiet]
#
#   --quiet   print only changes, warnings, and errors

set -euo pipefail
shopt -s nullglob

QUIET=0
for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=1 ;;
    -h|--help) awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"; exit 0 ;;
    *) echo "unknown option: $arg (try --help)" >&2; exit 2 ;;
  esac
done

say()  { [[ "$QUIET" -eq 1 ]] || echo "$@"; }
note() { echo "$@"; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
TARGET_DIR="$HOME/.claude/skills"

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "❌ No skills/ directory found at $SKILLS_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
say "Installing third-party skills from $SKILLS_DIR → $TARGET_DIR"
say

# --- Skills -------------------------------------------------------------------
# skills/* entries are themselves symlinks into vendor/, so -d follows them.
for skill_path in "$SKILLS_DIR"/*; do
  [[ -d "$skill_path" ]] || continue
  skill_name="$(basename "$skill_path")"
  target="$TARGET_DIR/$skill_name"

  if [[ ! -e "$skill_path/SKILL.md" ]]; then
    note "⚠️  $skill_name: no SKILL.md — skipping (Claude Code won't load it)."
    continue
  fi

  # A real directory or file in the way is the user's, not ours to delete.
  if [[ -e "$target" && ! -L "$target" ]]; then
    note "⚠️  $skill_name: $target exists and is not a symlink. Skipping."
    note "    To replace with this collection's version: rm -rf '$target' && rerun."
    continue
  fi

  if [[ -L "$target" ]]; then
    current_target="$(readlink "$target")"
    if [[ "$current_target" == "$skill_path" ]]; then
      say "✅ $skill_name: already symlinked correctly"
      continue
    fi
    # Another manager (e.g. `npx skills add` → ~/.agents/skills) owns this name.
    # Say where it pointed, so a silent takeover is never silent.
    note "🔄 $skill_name: replacing existing symlink → $current_target"
    rm "$target"
  fi

  ln -s "$skill_path" "$target"
  note "✅ $skill_name: installed"
done

# --- Prune --------------------------------------------------------------------
# Only dangling links pointing into THIS collection are ours to remove. Links to
# other repos (claude-skills, pinky-log, ~/.agents) are reported, never touched.
for link in "$TARGET_DIR"/*; do
  [[ -L "$link" ]] || continue
  [[ -e "$link" ]] && continue
  link_name="$(basename "$link")"
  link_target="$(readlink "$link")"
  if [[ "$link_target" == "$SKILLS_DIR"/* ]]; then
    rm "$link"
    note "🧹 $link_name: pruned (no longer in this collection)"
  else
    note "⚠️  $link_name: dangling symlink → $link_target"
    note "    Not from this collection, so leaving it. Remove with: rm '$link'"
  fi
done

say
say "Done. Run 'ls -la $TARGET_DIR' to verify."
