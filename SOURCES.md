# Sources

Provenance for everything under `vendor/`. Nothing in `vendor/` is edited —
local changes belong upstream or in a wrapper under `skills/`.

| Skill(s) | Upstream | Pinned at | Update by | License |
|---|---|---|---|---|
| `vibe-code-security-audit` | `github.com/mrhakimov/vibe-code-security-audit` (submodule, https) | `c99d6f7` (2026-04-03) | `git -C vendor/vibe-code-security-audit pull`, then `git add` the gitlink | not stated upstream |
| `limits-*` (5 skills, `skills/mental-health/`) | `github.com/bradfrost/skills` (**public** as of 2026-09-01; submodule) | `f05e016` | `git -C vendor/bradfrost-skills pull`, then `git add` the gitlink | not stated upstream |
| `find-skills` | unknown — references https://skills.sh/, likely `vercel-labs/agent-skills` | copied into `~/.claude/skills` 2026-07-23 | none (re-fetch from skills.sh) — still plain files | not stated |
| `i-have-adhd` | `github.com/hellatan/i-have-adhd` (submodule, https) | `cbe69fb` | `git -C vendor/i-have-adhd pull`, then `git add` the gitlink | MIT (declared in frontmatter) |

## Git structure (private repo `hellatan/ai-skills-third-party`)

This collection is now a **private** git repo so cloud instances can clone it and
run `scripts/install.sh` — local symlinks alone can't be fetched. Vendored
sources are committed two ways:

- **Submodules** (their own upstream repos, https URLs so cloud clones need no SSH
  key): `vendor/bradfrost-skills` (→ `bradfrost/skills`, converted 2026-09-01 once
  it went public), `vendor/i-have-adhd`, `vendor/vibe-code-security-audit`. Clone
  with `git clone --recurse-submodules`, or `git submodule update --init` after.
- **Plain files** (no standalone repo yet): `vendor/find-skills` (no known repo).
  Convert to a submodule if/when it becomes a standalone reachable repo.

Converting bradfrost to a submodule reverted `limits-setup`'s `description`
frontmatter to upstream (it had a local edit — "START HERE…" vs upstream's
`/setup-brad-frost-skills` reference); body identical, all trigger phrases intact.

### Git workflow: main-only, PRs against `main` (Dale's call, 2026-09-01)

> Future-you asking "why the fuck is it this way?": **you chose this.** Here's why.

`main` is the only long-lived branch — no `develop`, no gitflow. This is a
personal vendoring collection, not an app, so promotion PRs and a staging branch
buy nothing. But direct-push-to-`main` is also **off** (this repo isn't in
`block-push-to-protected.py`'s 3-repo allowlist, and we chose not to add it).
So every change lands via a **feature branch → PR against `main`**, edited in a
worktree (the primary-checkout edit hook enforces the worktree). You picked PR
review over direct commits here; that's the whole reason it's not just
`git push origin main`.

## Notes

- **`vibe-code-security-audit` ships `skill.md`, lowercase.** Claude Code looks
  for `SKILL.md`. This Mac's filesystem is case-insensitive so it would happen
  to work, but `skills/vibe-code-security-audit/` is a real directory whose
  `SKILL.md` and `README.md` are symlinks into the clone — correct on any
  filesystem, and the clone stays pristine.
- **`i-have-adhd` is `disable-model-invocation: true`** — user-invocable only
  (`/i-have-adhd`), so it never appears in the model's auto-discovered skill list.
- **The `limits-*` skills carry executable payloads** (`hooks/quiet-hours.sh`,
  `hooks/sessions-gate.sh`, `bin/ai-limits`). Symlinking a skill does not run
  them; `limits-setup` wires them into `settings.json` only if you run it.
- **`limits-endings` is an always-on skill** ("Use always, in every session").
  It reshapes every response in every session. Install deliberately.

## 2026-08-29 — version check when this repo took over `limits-*`

`~/.agents/skills/` (skills CLI, 2026-08-26 18:24) vs `vendor/bradfrost-skills`
(extract refreshed 2026-08-28 16:50): the vendored copy is **two days newer** on
all three shared skills, so the takeover was an upgrade, not a downgrade.
Concretely — `limits-setup` gained the numbered "(1 of 6)" interview script and a
`~/.config/ai-limits/` config path, `bin/ai-limits` changed by 68 diff lines, and
`limits-endings` gained a `hooks/` directory the CLI copy never had.

`limits-sessions` was never installed by the CLI at all; it's live now.
