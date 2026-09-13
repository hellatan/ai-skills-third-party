#!/usr/bin/env bash
# Install this checkout's third-party skills into an explicitly selected
# discovery root. The default remains Claude-only for backward compatibility. A
# selection is saved clone-locally so repeated manual installs can omit it.
set -euo pipefail
shopt -s nullglob

QUIET=0
REQUESTED_TARGET=""
SAVE_SELECTION=1
CLAUDE_DIR="${SKILLS_CLAUDE_DIR:-$HOME/.claude/skills}"
AGENTS_DIR="${SKILLS_AGENTS_DIR:-$HOME/.agents/skills}"
CONFIG_KEY="ai-skills-third-party.installTarget"

usage() {
  cat <<'EOF'
Usage: ./scripts/install.sh [--target=claude|agents|both] [--quiet]

Installs third-party skill symlinks into Claude Code (~/.claude/skills),
agent-neutral discovery (~/.agents/skills), or both. No argument preserves the
legacy Claude-only behavior unless this clone has a previously saved explicit
target selection.

Environment variables SKILLS_CLAUDE_DIR and SKILLS_AGENTS_DIR are intended for
isolated tests. Tests may also pass --no-save to avoid changing this clone's
local git config. The installer preserves unowned symlinks, files, and
directories; remove a conflicting target yourself before intentionally taking it
over.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=1 ;;
    --target=*) REQUESTED_TARGET="${arg#--target=}" ;;
    --claude) REQUESTED_TARGET="claude" ;;
    --agents) REQUESTED_TARGET="agents" ;;
    --both) REQUESTED_TARGET="both" ;;
    --no-save) SAVE_SELECTION=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $arg (try --help)" >&2; exit 2 ;;
  esac
done

case "$REQUESTED_TARGET" in
  ''|claude|agents|both) ;;
  *) echo "invalid target: $REQUESTED_TARGET" >&2; exit 2 ;;
esac

say() { [[ "$QUIET" -eq 1 ]] || echo "$@"; }
note() { echo "$@"; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
[[ -d "$SKILLS_DIR" ]] || { echo "No skills/ directory found at $SKILLS_DIR" >&2; exit 1; }

git_dir_abs() {
  local value
  value="$(git -C "$REPO_ROOT" rev-parse "$1" 2>/dev/null || true)"
  [[ -z "$value" ]] && return 0
  [[ "$value" = /* ]] || value="$REPO_ROOT/$value"
  (cd "$value" 2>/dev/null && pwd) || echo "$value"
}

GIT_COMMON="$(git_dir_abs --git-common-dir)"
GIT_LOCAL="$(git_dir_abs --git-dir)"
if [[ -n "$GIT_COMMON" && "$GIT_COMMON" != "$GIT_LOCAL" && "${SKILLS_INSTALL_ALLOW_WORKTREE:-0}" != 1 ]]; then
  [[ "$QUIET" -eq 1 ]] && exit 0
  echo "Skipping: this is a linked worktree. Install from the primary checkout instead."
  exit 0
fi

saved_target="$(git -C "$REPO_ROOT" config --local --get "$CONFIG_KEY" 2>/dev/null || true)"
if [[ -z "$REQUESTED_TARGET" ]]; then
  REQUESTED_TARGET="${saved_target:-claude}"
fi
if [[ "$SAVE_SELECTION" -eq 1 ]]; then
  git -C "$REPO_ROOT" config --local "$CONFIG_KEY" "$REQUESTED_TARGET" 2>/dev/null || true
fi
case "$REQUESTED_TARGET" in
  claude|agents|both) ;;
  *) echo "invalid saved target in git config $CONFIG_KEY: $REQUESTED_TARGET" >&2; exit 2 ;;
esac

absolute_path() {
  python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$1"
}

resolved_link_target() {
  local link="$1" raw
  raw="$(readlink "$link")"
  if [[ "$raw" = /* ]]; then
    absolute_path "$raw"
  else
    absolute_path "$(dirname "$link")/$raw"
  fi
}

link_points_to() {
  local link="$1" expected="$2"
  [[ "$(resolved_link_target "$link")" == "$(absolute_path "$expected")" ]]
}

install_root() {
  local target_dir="$1" skill_path skill_name link raw candidate

  mkdir -p "$target_dir"
  say "Installing third-party skills from $SKILLS_DIR -> $target_dir"

  for skill_path in "$SKILLS_DIR"/*; do
    skill_name="$(basename "$skill_path")"

    if [[ -L "$skill_path" && ! -e "$skill_path" ]]; then
      note "WARNING: $skill_name is a dangling skills/ link; skipping."
      continue
    fi
    [[ -d "$skill_path" ]] || continue

    if [[ ! -e "$skill_path/SKILL.md" ]]; then
      note "WARNING: $skill_name has no SKILL.md; skipping."
      continue
    fi

    link="$target_dir/$skill_name"
    if [[ -L "$link" ]]; then
      if link_points_to "$link" "$skill_path"; then
        say "  $skill_name: already installed"
        continue
      fi
      note "WARNING: $link is an unowned symlink -> $(readlink "$link"); leaving it unchanged."
      continue
    fi
    if [[ -e "$link" ]]; then
      note "WARNING: $link exists and is not an owned symlink; leaving it unchanged."
      continue
    fi

    ln -s "$skill_path" "$link"
    note "installed $skill_name -> $target_dir"
  done

  for link in "$target_dir"/*; do
    [[ -L "$link" && ! -e "$link" ]] || continue
    raw="$(readlink "$link")"
    candidate="$(resolved_link_target "$link")"
    if [[ "$(dirname "$candidate")" == "$(absolute_path "$SKILLS_DIR")" ]]; then
      rm "$link"
      note "pruned owned stale link $(basename "$link")"
    else
      note "WARNING: dangling unowned link $link -> $raw; leaving it unchanged."
    fi
  done
}

case "$REQUESTED_TARGET" in
  claude) install_root "$CLAUDE_DIR" ;;
  agents) install_root "$AGENTS_DIR" ;;
  both)
    install_root "$CLAUDE_DIR"
    install_root "$AGENTS_DIR"
    ;;
esac

say
say "Done."
