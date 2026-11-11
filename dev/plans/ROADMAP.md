# Roadmap

Initiative index. Items: `R-001: description`; each entry owns
`R-XXX-<slug>/` with its `requirements.md`. A checkbox closes per
`skills/dev/plan.md § Approval and closure`.

- [x] R-001: Restructure planning layout - indexes at `.claude/` root,
      per-roadmap-entry plan dirs, task-id-prefixed branch plans, batch
      manifests dir.
- [x] R-002: Batch integration flow - batch integration branch, enforced
      checkpoint report, full-strength batch review, push + MR at accept.
- [x] R-003: Flatten the requirement level into roadmap entries -
      R-rooted chain with in-dir `requirements.md`, single closure point
      on verified acceptance criteria.
- [x] R-004: Parallel batch execution for DEV auto mode - dropped:
      will not implement.
- [x] R-005: Trim agentic verification cost - verification-depth policy,
      per-role model routing, branch-close folding, slimmer dispatch
      prompts, context diet for always-loaded rules.
- [x] R-006: Trunk-based, lean, self-enforcing config - protected
      `main`, CI-gated PRs, batch as the delivery unit, tag-on-trunk,
      CI + pre-push self-enforcement.
- [ ] R-007: Per-batch complexity level - `normal`/`high` dial over the
      verification levers (model tier, spec-check skip, close-folding,
      effort, loop rigor) on the batch unit; a stub for `/dev plan R-007`.
- [x] R-008: Wallarm reference skill - superseded: the Wallarm reference
      skills live in the `skills/` repo, not `~/.claude/skills/`.
- [x] R-009: Adopter-project TBD migration - already-DEV pre-TBD
      projects migrate to PR-only delivery; `start` establishes a
      protected trunk.
- [x] R-010: Frictionless planning-PR delivery - `plan/` MR/PRs
      auto-merge on a green gate (native host or agent fallback).
- [x] R-011: Delivery cadence - one branch = one coherent unit of work;
      VIBE applies-then-waits and delivers at a work boundary.
- [x] R-012: Writing quality - global convey-intent writing rule +
      Tier-2 review gate.
- [x] R-013: JS file-naming convention - `rules/js.md` kebab-case
      (PascalCase for class files) + a copyable CI filename check.
- [x] R-014: Per-initiative task indexes - each R-dir owns a
      lazily-created `tasks.md`; ROADMAP stays the cross-R index.
- [x] R-015: Embeddable self-contained DEV toolchain - superseded by
      the isolated DEV toolset (no vendoring).
- [x] R-016: Lean DEV planning & delivery - two planning rounds,
      right-sized multi-commit tasks, size-scaled close review.
- [x] R-017: migrating-to-dev legacy detection - inventory runs
      regardless of mode; legacy schemas detected and
      guided-canonicalized.
- [x] R-018: Bootstrap exception defined narrowly - only the initial
      `main`-creating commit before protection; `start` protects after
      it; migration delivers via branch + MR/PR.
- [x] R-019: Vendor embed onto a non-empty `.claude/` - mooted by the
      isolated DEV toolset (no vendoring).
- [x] R-020: Consolidate branch-close into `branch-plan.md` - absorbed
      by `finish.md` and its verify gate.
- [x] R-021: Isolated, self-contained DEV toolset - the `/dev` router over
      inert `skills/dev/` mode files; trunk discipline via the branch-guard
      hook; distribution via skill precedence, no vendoring.
- [x] R-022: Config conventions & guardrails - secrets gatekeeper hook,
      code-size gates, scaffold required-files, routine-commands
      convention.
- [x] R-023: Feature documentation layer - `.claude/docs/` per-feature
      docs between `DESIGN.md` and code; doc-first execution step +
      doc-to-code reconcile at close.
- [x] R-024: DEV confirmation and outcome gates - plan approval never
      auto-starts code; `finish` verifies before merge options; precise
      branch guard.
- [x] R-025: Explicit review checklist - superseded: the dimensions are
      checklist lines in the `code-reviewer` rubric.
- [x] R-026: Writing conventions - em dashes banned in every tracked
      file (Tier-1 check + one-time sweep); prose style as Tier-2
      review criteria.
- [x] R-027: Conflict-free Tier-2 ledger - per-commit stamp store
      replaced the appended ledger; retired with the ledger.
- [x] R-028: Self-enforcement layer hygiene - `scripts/test/run-all.sh`
      wired into CI and pre-push, blocking.
- [x] R-029: Retire the Tier-2 ledger - gate, store, and stamp step
      deleted; the five-concern Tier-2 review stays a branch-close step.
- [x] R-030: Docs-layer routing & adoption - CLAUDE.md doc-lookup
      routing + the migrate docs-adoption audit.
- [x] R-031: Standalone `/dev docs` command - docs audit/build/refresh
      runnable on any project (`companions/docs-adoption.md`).
- [x] R-032: Feature-doc detail bar - full input surface, provenance
      markers, tested examples (`layout.md § Docs`).
- [x] R-033: Documentation conventions (Diataxis) - global framework +
      independent-agent per-claim verification gate
      (`companions/documentation.md`); supersedes the earlier docs layer.
- [x] R-034: Branch-guard foreign-path scope - deny only paths inside
      the owning repo and not ignored; fail-open.
- [x] R-035: Atomic branch-close bookkeeping - task/R marks ride the
      final commit and land with the merge; close-out PR only for
      run-dependent criteria.
- [x] R-036: Branch-guard target scope - writes judged by the target
      path's owning repo, not the session cwd.
- [x] R-037: Branch-guard compound detection - the branch-create
      exemption covers `git -C` option groups.
- [x] R-038: Declared state-check command - one allowlisted,
      JSON-emitting MR/PR state check per host.
- [x] R-039: Single-home the /dev system - one owner per rule with
      pointers; twins single-sourced; execution files as cadence deltas.
- [x] R-040: Supervisor-orchestrated autonomous DEV - a repo-less
      supervisor drives one worker session per project, merges green
      pre-approved work within declared bounds, escalates the rest.
- [x] R-042: Planning-round PoCs - dropped: will not implement.
- [x] R-043: Ship the accretion check to adopters - the hardened
      `check-accretion.sh` + self-test, vendored by `install-dev.sh`,
      offered by `start` and `migrate`; markers the only tuning.
- [x] R-041: Docs reconcile (this repo) - archive the closed initiatives,
      compact `ROADMAP.md` and open plans to state the present, verify
      `check-plan-integrity` across the move, add the accretion check.
- [x] R-045: DEV artifacts root - planning artifacts move out of the
      guarded `.claude/` tree to a declared root (default `dev/`) a
      headless worker can write; `migrate` carries adopters over.
- [x] R-046: DEV system-source hygiene - the toolset's docs state its
      conventions, a doc-sync review concern owns induced staleness, the
      `§ Agent toolchain` syntax is re-homed, `check-plan-integrity` tested.
- [x] R-047: Branch-close routing - the close review dispatches on diff
      content, the verify gate and `finish § 2` name what clears each
      prose class, and the push-scoping contradiction is resolved.
- [x] R-044: Batch rollback-anchor identity - the `pre-B-XXX` tag carries
      its initiative, so batch ids stop colliding; a gate catches an
      anchor that outlived its batch where tags are visible.
- [x] R-049: Vendored-gate hygiene - NUL-delimited enumeration for the
      sibling `git ls-files` checks and a copyable vendored-gate runner.
      Won't fix: fails the proportionality test, no observed failure.
- [x] R-048: Batch branch identity - `batch/B-XXX` refs carry the same
      per-initiative collision the anchor rename fixed, and the branch
      is pushed at accept.
- [x] R-050: Context budget - bound the working window, make the session
      the delivery unit (task or branch in `code`, batch in `auto`), drop
      context-resident waste; a tracked tool measures the effect.
- [x] R-051: Verifier isolation - `scripts/test/` fixture git commands
      hit the host repo when `GIT_DIR` is absolute (`git -C` does not
      override it); the tests, `install-dev.sh`'s shipped one too, scrub it.
- [x] R-052: Branch discipline and commit target resolution - the
      cheapest fix for two branch-guard misfires: planning writes before
      it branches, and a commit's repo resolves from the session cwd.
- [x] R-053: Proportional engineering - a planning rule, not a gate: one
      observed failure earns one fix and one test; an unfired hazard needs
      explicit approval; the test suite is trimmed to the same standard.
- [x] R-054: Prune the local permission allowlist - durable tool classes,
      the batch-push deny carve-out and model override stay; one-shot
      literals and arbitrary-execution wildcards go; no regrowth check.
- [x] R-055: Archive an initiative when it closes - `finish.md § 4` opens
      the closure's plan MR/PR whenever the merge closed the initiative;
      the unarchived backlog is swept to `plans/archive/`.
- [x] R-056: Settings tiering and session defaults - durable repo-scoped
      permission rules move from the dropped `settings.local.json` to a
      tracked `.claude/settings.json`; `defaultMode` becomes `acceptEdits`.
- [x] R-057: Cap the close review - the `code-reviewer` agent (a second
      verifier only on a Critical) replaces `/code-review`, now manual-only;
      no subagent runs it or spawns more; a targeted reviewer set is defined.
- [x] R-058: Guard hardening - close the verified gaps the `acceptEdits`
      default leans on: prefix-match push denies, a regex-only secrets
      guard with no Tier-1 scan, a branch guard knowing only main/master.
- [x] R-059: Relax the commit-message rule - `git-workflow.md § Commit
      messages` keeps the subject constraints and allows a compact body,
      so change history lives in git, not in findings or plan files.
- [x] R-060: Milestone execution plans - `plans/milestone-<id>.md`, by
      `/dev plan milestone <id>`, records a cross-initiative order over
      existing task ids; scope stays in `ROADMAP.md`, `depends-on` wins.
- [x] R-061: Unified plan ids - `R<NNN>`, `R<NNN>-T<NNN>`, `R<NNN>-B<NNN>`
      for every new id; existing ids are legacy, frozen and valid; both
      shapes parse; the rule's home is `plan.md § ID format`.
- [x] R062: Headroom in plan.md - superseded: citing the layout tree
      from `plan.md` freed the room.
- [x] R063: Tier-2 review text and guard fail-closed - runnable review
      clauses citing their owners; hook guards that run from any
      directory and fail closed.
- [x] R064: Fixed dev/ home - `dev/` is the one home of DEV artifacts
      in every project, this repository included; the configurable
      artifacts root and its resolver are removed.
- [x] R065: Trim the session-loaded prose - a session loads only universal
      prose: `writing.md`'s DEV-only sections become a shipped path-scoped
      rule; `delegation.md`, `rules/git-workflow.md` fold into `CLAUDE.md`.
- [x] R066: Slim the DEV skill - the visual companion and pilot
      measurements leave `skills/dev/`, every rule keeps one home, stale
      text goes; per-command read cost drops, `plan.md` regains headroom.
- [x] R067: Shipped toolset portability - the self-tests `install-dev.sh`
      ships carry nothing a git host may reject; the accretion fixture's
      Cyrillic name, which blocked an adopter's push, leaves that block.
- [x] R068: Docs as snapshot - docs state current state: no chronology or
      planning ids, links only to sibling docs or external URLs, report
      and adapted-reference types, findings never linked from docs.
- [x] R069: Supervised-run hardening - a supervised run's lessons land in
      supervise.md and the supervisor runbook: prompt-clearing ownership,
      activity alarms, merge-evidence fallback, a pre-finish re-brief.
- [x] R070: Archival gate - the closing branch's final commit carries the
      archive move; a Tier-1 check fails a closed initiative outside
      archive/, `archival: deferred` with a reason the one exemption.
- [ ] R071: Install-shipped archival gate - install-dev.sh copies
      check-archival.sh and its run-all registration to adopters,
      asserted by install-dev.test.sh.
- [x] R072: Slim the per-task workflow - size-scaled close review,
      two-seat supervision (operator merges into the supervisor),
      proportional tests; supersedes the earlier close-review work.
- [x] R073: Planning moves to Jira - dropped: will not implement.
- [x] R074: Session-state hand-off enforcement - compaction lost intent
      to the summary: a context-fill warning in `dev-branch-state.sh`, a
      `Stop`-hook nudge for autonomous turns, the PreCompact block the floor.
- [x] R075: Installer delivery guard - a `--project` install refuses a
      dirty tree or a default-branch HEAD, naming the remedy (`--force`
      overrides); commits, branching, and MR/PR stay with the operator.
- [ ] R076: Global-config write fence - a guard denies writes into
      `~/.claude` from a session whose project root is elsewhere, routing
      the proposal to a report file in the writer's repo for triage.
- [x] R077: Ship the maintenance routine - the installer delivers the
      generic `MAINTENANCE.md` targets table for each project doc to
      carry, and the claim that projects carry the Routine matches it.
- [x] R078: Hand-off continuity - reading the hand-off after compaction
      stops being advisory: a `notes` key for facts no artifact owns, and
      a `SessionStart` hook injecting the last hand-off block on resume.
- [x] R079: Undated stamps - the agentic/supervised stamps go dateless,
      plan.md's contradiction on approval dates resolves, the one live
      dated stamp migrates.
- [x] R080: Work by seats - dropped: frozen unfinished; later initiatives
      carried its live work.
- [x] R081: Lean planning - the DEV chain stays, its cost drops:
      agents do only what was asked, short stable plan artifacts, plan
      modes, task reports, bounded loops, no code comments by default.
- [x] R082: Plan-text gate that bites - every project's CI enforces
      the short-plan rules, and the task report is the one home for
      findings, answers and probes.
- [x] R083: Evidence references replace provenance marks - a doc claim
      shows its evidence as a reference to a report or a source; the
      mark vocabulary and its governance go.
- [x] R084: One home per rule - the merge, the branch close, the project
      declarations and doc verification each get one definition;
      auto-merge, the ship question and verdict marks go.
- [x] R085: Code without comments - dropped: superseded by R088-T001.
- [x] R086: Agent contracts - each seat works from one step list, claims
      are proven by the implementer's probes before docs, and a convention
      binds only work created after it.
- [ ] R087: Seat contract follow-ups - the backlog the agent contracts
      left: prompt context, the docs path, rule restatements and the docs
      gate's scope.
- [ ] R088: Native first - DEV runs on Claude Code's native behavior and
      features, rules stop overriding defaults, and a weekly audit finds
      new conflicts.
- [ ] R089: Autonomous adopter runs - a new project runs DEV end to end in
      a cloud session under `auto` with `Supervisor: AI`, no human
      answering, at a cost in proportion to the work.
- [ ] R090: Dogfood benchmark - the framework equips each implementer with
      plan, style guide, spec and references, and fixture runs measure its
      time, quality and cost per configuration.
- [x] R091: Cut the waste - normal mode drops plan upkeep, claims and
      per-change seats, reports shrink to a line per item, docs get a
      structure and a cap, and a handoff carries context across `/clear`.
- [x] R092: Implementer model tiers - the planner tags an item Sonnet or
      Fable when the tier pays, Opus otherwise; Fable needs the user's
      approval and a red item escalates one tier.
