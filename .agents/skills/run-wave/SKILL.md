---
name: run-wave
description: Orchestrate a migration wave of parallel child sessions over units.yaml.
---

# Run a wave

The wave plan lives in `.migration/units.yaml` (`waves`: 0 foundation,
1a width 5, 1b width 13, 2 orchestration). Integration branch:
`migration-run-N`.

1. Run Lakebridge analyze + per-unit transpile exactly as in
   `demo-ops/ORCHESTRATOR_PROMPT.md` step 2; commit drafts to the run branch.
2. Run wave 0 (foundation) yourself: convert `00_foundation`, load `core.*`
   from `/Volumes/<catalog>/landing/raw`.
3. Launch one child session per unit in the wave, each on branch
   `unit/<name>` from the run branch, with the migrate-unit skill. Never exceed
   the wave width.
4. Child PRs merge into `migration-run-N`. After the wave merges, run wave 2
   (orchestration), then the verifier.
5. Respect `AGENTS.md`: children never touch legacy/golden/seed/validation and
   never merge to `main`.
