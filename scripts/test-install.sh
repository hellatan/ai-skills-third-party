#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ai-skills-third-party-install.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

run_install() {
  SKILLS_INSTALL_ALLOW_WORKTREE=1 \
  SKILLS_CLAUDE_DIR="$1" \
  SKILLS_AGENTS_DIR="$2" \
  "$REPO_ROOT/scripts/install.sh" --no-save --quiet "$3"
}

assert_link_target() {
  local link="$1" expected="$2" actual
  [[ -L "$link" ]] || { echo "expected symlink: $link" >&2; exit 1; }
  actual="$(python3 -c 'import os,sys; link,expected=sys.argv[1:3]; raw=os.readlink(link); resolved=raw if os.path.isabs(raw) else os.path.join(os.path.dirname(link), raw); print(os.path.abspath(resolved) == os.path.abspath(expected))' "$link" "$expected")"
  [[ "$actual" == "True" ]] || { echo "unexpected target for $link: $(readlink "$link")" >&2; exit 1; }
}

CLAUDE_DIR="$TMP_ROOT/claude skills"
AGENTS_DIR="$TMP_ROOT/agents skills"
FOREIGN_DIR="$TMP_ROOT/foreign"
mkdir -p "$CLAUDE_DIR" "$AGENTS_DIR" "$FOREIGN_DIR"
ln -s "$FOREIGN_DIR/find-skills" "$CLAUDE_DIR/find-skills"

run_install "$CLAUDE_DIR" "$AGENTS_DIR" --target=both

assert_link_target "$AGENTS_DIR/find-skills" "$REPO_ROOT/skills/find-skills"
assert_link_target "$CLAUDE_DIR/find-skills" "$FOREIGN_DIR/find-skills"

ln -s "$REPO_ROOT/skills/obsolete-skill" "$CLAUDE_DIR/obsolete-skill"
run_install "$CLAUDE_DIR" "$AGENTS_DIR" --target=claude
[[ ! -e "$CLAUDE_DIR/obsolete-skill" && ! -L "$CLAUDE_DIR/obsolete-skill" ]] || {
  echo "expected owned stale link to be pruned" >&2
  exit 1
}

CLAUDE_ONLY_DIR="$TMP_ROOT/claude-only"
AGENTS_ONLY_DIR="$TMP_ROOT/agents-only"
run_install "$CLAUDE_ONLY_DIR" "$AGENTS_ONLY_DIR" --target=agents
[[ ! -e "$CLAUDE_ONLY_DIR/find-skills" && ! -L "$CLAUDE_ONLY_DIR/find-skills" ]] || {
  echo "target=agents should not install Claude links" >&2
  exit 1
}
assert_link_target "$AGENTS_ONLY_DIR/find-skills" "$REPO_ROOT/skills/find-skills"

echo "installer fixtures passed"
