# Planning templates

Requirement docs at every level state desired behavior - forward-looking,
present-tense, normative - never a history of shipped work. The R/T plan
hierarchy records who did what when; `REQUIREMENTS.md` records what must
remain true, unlinked from initiative ids.

## Foundational `.claude/REQUIREMENTS.md`

```
---
approved: pending
---

# Project requirements

## Vision           - one paragraph
## Goals            - top-level (3–7)
## Non-goals        - explicit out-of-scope
## Audience         - primary / secondary users
## Success criteria - how we'll know it worked
## Constraints      - technical / organizational / time
## Open questions
```

## Per-initiative `<plans>/R<NNN>-<slug>/requirements.md`

In rules, skills, and docs, write it path-qualified wherever bare
`requirements.md` could be read against root `REQUIREMENTS.md`.

One shape for every `kind:`. The title names the parent R - the file
has no id of its own. The goal and outcomes come from the user: no
implementation detail unless the user supplied it, and no checkboxes,
links, dates, PR refs or measured values
(`scripts/ci/check-plan-text.sh`). Outcomes are the initiative's
acceptance criteria, numbered, read for meaning, not wording.

`## Design` names the standard the initiative follows and the
components it changes: the planned change, never code. `DESIGN.md`
describes only the present architecture. The whole file, design
included, stays within 40 lines (`scripts/ci/check-plan-text.sh`). The
shape round writes this file alone; the task list waits for the detail
round (`plan.md § Planning rounds`).

```
---
approved: pending
kind: feat | bug | refactor | doc | test | mnt
---

# R001: <short title>

## Goal                - what the user wants to get, and why
## Inputs and outputs  - optional
## Outcomes            - numbered; what is true when done
## Constraints         - optional; only specifics the user supplied
## Design              - optional; the standard followed, the components
                         changed
```

## Per-initiative `tasks.md`

```
# R001 tasks - <short title>

Why: <one or two lines>

## Open

- [ ] **R001-T001 [tag]**: <what to do, one or two lines>

- <backlog line, one line>
```

The file holds this template and nothing else: no preamble, ordering
prose or notes. Tasks run in list order. A backlog line is an unnumbered
`- ` bullet on one line after the task entries; a wrapped one fails
`scripts/ci/check-plan-text.sh`.

A task says what to do, never how: no probe results, numbers, dates or
links. Another initiative or task is cited by its id
(`rules/writing-artifacts.md § Name things by their durable id`).

## Roadmap entry

`- [ ] R001: <title> - <what the initiative delivers>`, at most three
lines.

## Release plan `release-vX.Y.Z.md`

Created by `/dev plan release` (requires ≥1 closed task since the last
release). One checkbox per planned branch, which `write-plan.md` step 7
adds; the `[x]` is a closing-routine bookkeeping mark
(`branch-plan.md § Closing routine`; auto and untracked
modes place marks per `batch.md § Batch close` / `finish § 4`). The
`release` skill halts while planned entries remain `[ ]` unless the user
confirms dropping them.

```
# Release vX.Y.Z

## Scope     - one-line theme of the release

## Branches  - one checkbox per planned branch
- [ ] feat/<slug> (R008-T001): description
- [ ] fix/<slug> (R008-T002): description

## Notes     - deferred or dropped scope, with reason
```

## Milestone plan `milestone-<id>.md`

Created by `/dev plan milestone <id>` for a milestone spanning several
initiatives (rules: `plan.md § Milestone plans`). Every entry is an
existing task id; waves follow the tasks' `depends-on` edges. Once
every entry is `[x]`, the same command offers the file for
`<plans>/archive/` (`plan.md § Archival`).

```
# Milestone <id>

## Boundary  - cite the `ROADMAP.md § Milestones` row; never restate it

## Order     - one wave per heading, members runnable in parallel
### Wave 1
- R008-T001 (<slug>): description
- R009-T002 (<slug>): description
### Wave 2
- R008-T003 (<slug>): description - after R008-T001

## Gaps      - work still blocking the milestone, each as a task id

## Notes     - deferred scope, with reason
```
