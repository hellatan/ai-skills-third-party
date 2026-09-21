# ai-skills-third-party contributor instructions

This public repository vendors third-party agent skills and exposes the selected
ones through normalized entries under `skills/`. It is the third-party companion
to `ai-skills`, which holds locally authored skills.

Read [SOURCES.md](SOURCES.md) before changing vendored sources, skill links, or
install behavior. It is the provenance and repository-workflow authority.

Cloud sessions load the shared workflow contract before other work: attach
`<CONTRACT_REPOS>` yourself (in Claude Code cloud, with `add_repo`), one at a
time since concurrent clones fail, then follow the contract repository's own
cloud setup instructions before starting the task. If an attach is refused, say
which and stop. Local sessions attach nothing and use the contract installed on
the machine; if it is not installed there, say so before starting.

## Lifecycle

- `main` is the only long-lived branch. Start feature branches from current
  `origin/main` and target pull requests at `main`.
- Work in a linked worktree; do not edit the primary checkout.
- Use an explicit source and destination for the first push:
  `git push -u origin <local-branch>:<remote-branch>`.
- Keep upstream `vendor/` sources untouched unless the change is an intentional
  submodule bump or plain-file source refresh recorded in `SOURCES.md`.
- Do not validate installer changes against live `~/.claude/skills` or
  `~/.agents/skills`. Use temporary directories through `SKILLS_CLAUDE_DIR` and
  `SKILLS_AGENTS_DIR`.
- Before handing off an installer or docs change, run `bash -n scripts/install.sh`
  and `scripts/test-install.sh`.

## Project map

- `vendor/` - upstream sources, stored as submodules or plain copied files.
- `skills/` - normalized installable entries, usually symlinks into `vendor/`.
- `scripts/install.sh` - installs selected third-party skills into Claude and/or
  agent-neutral discovery roots.
- `scripts/test-install.sh` - fixture tests for installer target selection,
  ownership preservation, and stale-link pruning.
- `SOURCES.md` - provenance, update workflow, and source-specific gotchas.

## Conventions

- Preserve authored upstream content. Local compatibility changes belong in
  wrappers under `skills/` or in repository docs, not in `vendor/`.
- A skill is installable only when the normalized entry exposes `SKILL.md`.
  Upstream files with other names need a wrapper directory or symlink, as with
  `vibe-code-security-audit`.
- `./scripts/install.sh` defaults to Claude for backward compatibility, unless
  this clone has a saved explicit target selection. Use `--target=agents` or
  `--target=both` when installing for agent-neutral discovery.
- The installer must not replace unowned symlinks, files, or directories.
  It may prune only stale links proven to point directly under this checkout's
  `skills/` directory.
- Claude-specific references are acceptable when they describe a Claude
  discovery root, upstream Claude behavior, or existing runtime compatibility.
