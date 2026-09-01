# claude-skills-third-party

Third-party Claude Code skills — other people's work, vendored and symlinked
into `~/.claude/skills/`. The counterpart to `~/projects/claude-skills`, which
holds skills written here.

Not a git repo (deliberately): `vendor/` contains upstream clones that manage
their own history.

## Layout

```
vendor/     upstream sources, untouched — clones, zip extracts, hand-copied dirs
skills/     one entry per installable skill; symlinks into vendor/
scripts/    install.sh
SOURCES.md  provenance: where each skill came from, how to update it
```

The indirection exists because upstream layouts vary — `bradfrost-skills`
nests skills under `skills/mental-health/`, `vibe-code-security-audit` ships a
lowercase `skill.md` at its root. `skills/` normalizes all of that into names
Claude Code can load directly.

## Install

```bash
./scripts/install.sh
```

Symlinks every `skills/*` entry to `~/.claude/skills/<name>`, and prunes links
into this collection that no longer resolve. Links owned by anything else
(`claude-skills`, `pinky-log`, `~/.agents/skills`) are reported, never touched.

Unlike `claude-skills`, there are no git hooks to auto-resync — **re-run
`./scripts/install.sh` after adding or updating a `vendor/` source.**

## Adding a skill

1. Put the source in `vendor/` — `git clone`, or extract the release/zip.
2. Symlink it into `skills/` under the name Claude Code should see:
   `ln -s ../vendor/<source>/path/to/<skill> skills/<skill>`
   (if upstream's entry file isn't `SKILL.md`, make `skills/<skill>/` a real
   directory and symlink `SKILL.md` into the source, as with
   `vibe-code-security-audit`).
3. Record it in `SOURCES.md`.
4. `./scripts/install.sh`

## Getting new third-party skills: fetch, then link

`npx skills add|update <repo>` (the [skills CLI](https://github.com/vercel-labs/skills))
is the **fetch** step — it downloads into `~/.agents/skills/` and links from
`~/.claude/skills/` itself. This repo is the **link** step. Two moves, in order:

1. `npx skills add <repo>` — or drop the source into `vendor/` by hand
2. make sure `vendor/` has the skill, symlink it into `skills/`, and run
   `./scripts/install.sh` — which re-points the CLI's link at this repo and
   prints `🔄 replacing existing symlink → <old target>` when it does

Stopping after step 1 is the only failure mode: the skill works, but it's owned
by the CLI in `~/.agents/` instead of by this collection.

⚠️ **`vendor/` does not update itself when the CLI fetches.** A `npx skills
update` refreshes `~/.agents/skills/`, not `vendor/`, so the linked copy here can
fall behind. Re-extract or copy into `vendor/` as part of step 2. (As of
2026-08-29 the vendored `limits-*` are newer than the `~/.agents` copies, not
older — the drift has run in that direction so far.)
