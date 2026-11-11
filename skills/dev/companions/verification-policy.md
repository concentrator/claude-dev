# Verification depth policy

Companion to `SKILL.md`, consulted by the runner (`run.md`) when
deciding how much verification each commit and batch warrants. The aim
is to trim agentic verification cost without dropping below the
floor that keeps the default branch safe. Sections below define the
knobs the runner has and when to apply them.

## Effort mechanics

Model and effort route per seat: each definition's frontmatter carries
`model:` where the seat pins a model and `effort:` where it pins an
effort (`low`/`medium`/`high`/`xhigh`/`max`; `agents/code-reviewer.md`
pins `medium`), the roster being `run.md § Seats`. A dispatch overrides
either through the Agent tool's `model` and `effort` parameters, which
is why the implementer's tier and the review's cost are the dispatch's
(§ Models) and the definitions' values the default; a key neither sets
inherits the session's - `effortLevel` the default rather than the
ceiling.

## Close folding

A branch is **small** iff its committed plan file satisfies all three
conditions, evaluated by reading the plan file at branch close - no agent
judgment:

1. **≤ 3 non-final commit checkboxes** in the plan body.
2. **No `architecture-changing: true` header.**
3. **No `probe` claim** in its `## Claims` (`documentation.md § Claims`):
   such a branch keeps its spec review, the close review, before the
   docs and their gate (`run.md § Close` 1, 3).

**Consequence:** a small branch skips the per-branch `code-reviewer` pass.
Its one review is the batch full-diff review at batch close. The runner
passes the list of folded branches into the batch full-diff review
dispatch (`batch.md § Batch close` 1).

**Invariants** - unaffected, per `batch.md § Per-branch close`:
the doc-writer pass and its gate (`run.md § Close` 3), the final commit
and the green gate hold for every branch; branches above the threshold
keep the full per-branch review.

**Scope:** this rule applies to a batch-scoped run only; a task-scoped
run closes in full (`skills/dev/branch-plan.md § Closing routine`).

## Verification modality

Verification follows the claim, not the artifact: an observable claim's
ground truth is a live run - the implementer's probe, recorded in the
task report, which the docs verifier checks (`documentation.md
§ Verification gate`) -
and a claim about source is checked against source
(`documentation.md § Sources`). A live run does not
relax independence - whoever authored the thing does not also certify
that its run passed, and that holds beyond docs: code, plans, and
gates alike.

**A run must be able to fail.** An execution whose inputs cannot
distinguish the claimed behavior from its fallback is a demonstration,
not a verification, and it certifies nothing. Choose inputs that would
have produced a different result had the claim been wrong: a cell
claiming a cache carries certain keys is not verified by a
hand-written cache containing them, and a default-valued config proves
nothing about a row describing the default. Where the discriminating
run is impossible, say so and name the source read
(`documentation.md § Sources`) rather than running something easier in
its place.

**A check must count the unit it claims to check.** An exemption drawn
per file does not exempt an entry; a count taken per line does not
count occurrences. Both pass their own execution
while answering a question other than the one asked, so state the unit
before trusting a green result, and prove a new check bites by making
it fail on a known instance first.

**A negative search is evidence only from an instrument whose failure
differs from its no-match.** The `grep` these sessions invoke wraps
`ugrep -I`: on a file it judges binary it prints nothing and exits 1,
byte-identical to a genuine no-match, so an empty result proves
nothing about that file. A search whose empty result is the claim
runs as `git grep`, which reports a binary match instead of hiding
it, or as `grep -a`; a recursive search over untracked paths adds
`--no-ignore-files`, since the same wrapper also skips gitignored
files and `git grep` never reads them.

## Verifier isolation

A verifier probing repo-touching behavior (git, hooks, filesystem
mutation) works in a throwaway repo with a scrubbed git environment -
`GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE` unset - never against the
live repo: those variables override cwd and are inherited, so a
cwd-isolated fixture is not isolated. Destructive git (`reset --hard`,
`clean`, ref deletion) is never a verifier's to run, cleanup of its
own mess included - a verifier that needs cleanup stops and reports.

## Comprehension check

The dispatcher's read of a strict plan (`write-plan.md` step 6).
Dispatch the cold reader (`agents/dev-cold-reader.md`, the
`dev-cold-reader` type) once, passing only the values its `§ Inputs`
names, never the planning conversation. Its gaps go to a planner once,
whose fixes land in the report's `## Planner`; the plan is not read
again, and the header records `cold-read: passed` (`branch-plan.md
§ Header`). Normal plans take no read.

## Models

A seat's model is its definition's (`run.md § Seats`); the rules a
definition cannot hold stay here.

**Implementer tier.** The implementer's model follows its plan item's
tag, read from the item's text, and the runner sets it on the dispatch:
`(sonnet)` → `sonnet`, `(fable)` → `fable`, untagged → `opus`, the
model `agents/dev-implementer.md` pins. No predicate infers a tag, and
no tier sets the implementer's effort.

- `(sonnet)` fits a fully specified, local item: named files, a
  testable outcome, no design choice left.
- `(fable)` fits an item where a wrong result costs more than the price
  gap: concurrency or state, security or data integrity, a cross-module
  design choice the plan leaves open, a bug of unknown cause.

**Escalation.** An item still red after its fix attempt reruns once, a
fresh implementer on the next tier up - `sonnet` to `opus`, `opus` to
`fable` - from the branch's last commit. A rise to `fable` waits for
the user's yes. A red rerun, a declined rise or a red `fable` item
halts.

**Review cost.** The project sets it with a `review: <model> <effort>`
line in `CLAUDE.md § Conventions` - `review: opus high`, say - and the
runner sets both on every `code-reviewer` dispatch (`run.md § Close` 1,
`batch.md § Batch close` 1). With no `review:` line the dispatch sets neither,
and `agents/code-reviewer.md`'s pins hold.

**Capacity fallback.** A pinned model can be rate-limited, which is not
a fact about the work. A dispatch that fails on capacity falls back to
the next model down - a `fable` dispatch to `opus`, an `opus` dispatch
to `sonnet` - and the substitution is recorded in the batch report or
branch findings: dispatched model, substitute, reason. It is a
documented degrade, not a decision to negotiate per batch, and not
grounds to halt delivery.

The record states what the substitution costs: cheap where
deterministic gates pin acceptance, the larger call where the
reviewer's judgment is the whole check (authored prose, documented
behaviour).
