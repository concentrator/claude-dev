# Layout

The repository's actual tree - every directory and fixed-name file, a
collection of same-kind files as one pattern line (`skills/dev/layout.md
§ Layout file`). The repository is cloned outside the config
directory, so harness state never enters it.

```
claude-dev/
├── dev-instructions.md           # global instructions (shipped; @imported by the installed CLAUDE.md)
├── writing.md                    # universal writing conventions (@imported by CLAUDE.md)
├── .gitignore                    # ignore rules for local overrides, secrets, bytecode
├── .env.example                  # worker-host tokens; `.env` is never tracked
├── README.md                     # overview and install
├── REQUIREMENTS.md               # foundational requirements
├── DESIGN.md                     # architecture (≤1000 words)
├── LAYOUT.md                     # the repository's tree (this file)
├── MAINTENANCE.md                # sanity routine + Tier-2 AI review
├── .github/                      # the Tier-1 CI gate
│   └── workflows/ci.yml          # Tier-1 mechanical CI gate (on PRs)
├── .githooks/                    # advisory local gate (core.hooksPath)
│   └── pre-push                  # advisory local Tier-1 mirror
├── hooks/                        # Claude Code hooks, wired in settings.json
│   ├── dev-branch-guard.sh       # PreToolUse: no trunk mutations, no lost work
│   ├── dev-branch-state.sh       # UserPromptSubmit: branch/tree state
│   ├── dev-hook-once.sh          # a project copy skips what the global settings run, sourced
│   ├── dev-session-brief.sh      # SessionStart: live tree re-brief
│   ├── dev-secrets-guard.sh      # PreToolUse: secrets guard
│   └── secret-patterns.sh        # the secret predicate, sourced
├── scripts/                      # installer, checks, tests, host tooling
│   ├── ci/                       # Tier-1 checks + run-all.sh
│   │   ├── branch-diff.sh        # a branch's base, added lines and changed paths, sourced by the checks
│   │   ├── check-*.sh            # the Tier-1 checks, one per file
│   │   ├── code-size-allow.txt   # check-code-size.sh exemptions, one path per line
│   │   └── run-all.sh            # the Tier-1 gate: every check, fails if any fails
│   ├── context-cost.py           # session context cost + attribution
│   ├── forge-keys.sh             # forge key exchange, the operator's half (sourced by provision-worker.sh)
│   ├── install-dev.sh            # toolset installer (global or --project, full or --minimal)
│   ├── install-manifest.sh       # what an install owns in its target, sourced by install-dev.sh
│   ├── preflight-permissions.sh  # the /dev run permission pre-flight
│   ├── provision-worker.sh       # stands up the worker host, run on the operator's machine
│   ├── rest-ci-wait.sh           # the CI wait for a GitHub host whose CLI has REST only
│   ├── rest-merge.sh             # the merge for a GitHub host whose CLI has REST only
│   ├── rest-state-check.sh       # the state check for a GitHub host whose CLI has REST only
│   ├── test/                     # script tests + run-all.sh
│   │   ├── *.test.sh             # script and hook tests, one per subject
│   │   └── run-all.sh            # the test aggregator: every *.test.sh, fails if any fails
│   ├── worker-credentials.sh     # worker forge keys and CLI auth, run on the VM
│   ├── worker-setup.sh           # worker host system setup, run on the VM
│   └── worker-workspace.sh       # worker repositories and per-project settings, run on the VM
├── .claude/                      # this repository's project settings and instructions
│   ├── CLAUDE.md                 # this repository's instructions: its declarations
│   └── settings.json             # project tier, tracked
├── dev/                          # DEV artifacts
│   ├── plans/                    # planning hierarchy
│   │   ├── ROADMAP.md            # cross-R index: skills/dev/plan.md
│   │   ├── R<NNN>-<slug>/        # one dir per roadmap entry (initiative-time)
│   │   │   ├── requirements.md   # initiative requirements
│   │   │   ├── tasks.md          # this initiative's task index (lazy)
│   │   │   ├── R<NNN>-T<NNN>-<slug>.md          # branch plans, one per task
│   │   │   ├── R<NNN>-T<NNN>-<slug>.report.md # task report
│   │   │   └── batches/          # R<NNN>-B<NNN> manifests + reports (lazy)
│   │   └── archive/              # closed initiatives, frozen history
├── docs/                         # the docs home (.claude/CLAUDE.md § Layout)
│   └── reports/                  # probe and test reports a doc claim cites, plus the dogfood runs' record
├── rules/                        # path-scoped convention rules
│   ├── claude-md.md              # CLAUDE.md maintenance rules (shipped)
│   ├── writing-artifacts.md      # DEV-artifact writing rules (**/*.md; shipped)
│   ├── code-comments.md          # code-comment rule (code and data files; shipped)
│   └── skills.md                 # SKILL.md maintenance rules
├── agents/                       # the run's seat definitions (skills/dev/run.md § Seats)
│   ├── code-reviewer.md          # branch-close quality review agent
│   └── dev-*.md                  # one per dispatched seat
└── skills/                       # the DEV toolset and the skills beside it
    ├── dev/                      # the DEV toolset
    │   ├── SKILL.md              #   the router
    │   ├── *.md                  # modes and process rules, routed by SKILL.md
    │   └── companions/           # declarations, docs framework, verification policy, runbook
    ├── systematic-debugging/     # bundled dependency skills (installer ships these)
    │   └── SKILL.md              #   the skill, its technique files beside it
    ├── dispatching-parallel-agents/SKILL.md    # bundled
    ├── dogfooding/               # dogfood run of the toolset, this repository's own
    │   ├── SKILL.md              #   purpose, triggers, inputs, outputs, companions' order
    │   └── companions/           #   requirements, preparation, brief, monitoring, finishing, pitfalls
    └── worker-host/              # GCP worker host runbook, this repository's own
        ├── SKILL.md              #   the four scripts and where each runs
        └── companions/           #   provisioning order, pitfalls
```
