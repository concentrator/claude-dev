# Documentation framework

The global convention for every doc - feature docs, specs, rules, knowledge
entries. Grounded in Diataxis (diataxis.fr). Prose style is `writing.md`
(always loaded); this file governs typing, structure, and content. Feature
docs (`<docs>`) are its Reference application
(`layout.md § Docs`).

## Diataxis typing

Every doc is exactly one of these types; never mix them in one file. A
project's root `README.md`, its front page, may mix them.

| Type | Answers | Shape |
|---|---|---|
| Tutorial | "teach me, start to finish" | Ordered lesson |
| How-to | "help me do X" | Goal-directed steps |
| Reference | "describe how X is" | Lookup, no procedures |
| Explanation | "help me understand X" | Discussion, background |

A spec or feature doc is a **Reference**: it describes how the subject *is*.
Procedures belong in a How-to; do not put steps in a Reference.

Two further types live in their own subdirectories of the docs tree
(`layout.md § Docs`):

- **Reports** (`<docs>/reports/`): probe and test reports - each
  records the call, its output and the environment it ran in, from a
  run that could have failed (`verification-policy.md § Verification
  modality`). The one docs location where datetimes and tenant
  or client ids are allowed. A report is a probed claim's source
  (§ Sources); a probed claim without one has none. For a `probe`
  claim (§ Claims) the doc writer writes the report, copying the call,
  output and environment of the claim's task report entry. A report is
  never archived: the claims linking it outlive the task.
- **Adapted references** (`<docs>/references/`): external or codebase
  material rewritten to project format, carrying exactly what the
  docs need; a source URL is allowed inside.

## Reference discipline

- **Describe, don't instruct.** State facts and structure, not actions.
- **Complete and accurate for its scope**, structured for lookup (tables,
  fixed section order).
- **Mirror reality.** Only verified facts (§ Verification gate).
- **One doc per specific subject.** Narrow and 100% relevant beats broad
  and diluted; a variant split may repeat structure, but a shared fact
  still lives in one doc (§ Content quality).
- **Split by variant when the structure differs.** Two variants with
  genuinely different architecture get separate docs, not one doc
  straddling both with conditionals.

## Reference skeleton (fixed order)

| Section | Holds |
|---|---|
| 1. Overview | What the subject is and where it fits |
| 2. Model | Concept model + one diagram |
| 3. Elements | Table: element -> responsibility / definition |
| 4. Behavior | Runtime interactions, precedence, semantics |
| 5. Parameters | Table: name -> default -> meaning |
| 6. Reference data | Domain lookup tables (limits, fields, codes, paths) |
| 7. References | Sibling docs, report docs, and adapted references |

Omit a section only when the subject genuinely has nothing for it.
Tiebreak: a flag or field is a Parameter; the component it configures is
an Element.

## Detail bar

- Enumerate **every element of the subject** - parameter, input, field,
  option, endpoint, file - and define each: name, type/default, meaning.
  A feature doc's elements are those of the code it explains
  (`layout.md § Docs`): an external system's element that code neither
  takes nor sends is not one.
- For each component, cover both its inputs (configuration, parameters)
  and its outputs (results, logs, errors).
- Never paste an artifact (config dump, schema, sample output) without
  explaining it.
- Include verbatim the defaults consumers commonly break, with a note on
  what depends on them.
- "Autodiscoverable" detail is not optional. Only genuinely hidden
  internals may be deferred to a subject-matter expert, and that deferral
  is stated in the doc.

## Diagrams

- C4 model for infrastructure and system context; otherwise an entity
  diagram when the subject is state and relationships, a flow diagram
  when it is a process, both when genuinely both.
- Render inline (mermaid), in-repo; no external assets or hosted images.

## Formatting

- Lookups and comparisons -> tables, not prose.
- Enumerations -> lists, never inline comma-runs.
- Steps (Tutorials / How-tos) -> numbered, imperative, deterministic; no
  "maybe / consider" without a decision rule.
- Fenced code blocks; uniform terminology throughout.

## Content quality

- **Self-sufficient**: everything needed to act, no live access or
  external search. Bar: a fresh reader with only this doc handles the
  hardest in-scope case.
- **Exact, not vague**: concrete values (versions, names, paths,
  limits) - identities and constraints; derived tallies per
  `rules/writing-artifacts.md § One home per number`. Never "check the docs" in place
  of the fact.
- **Actionable over referential**: give the command or value, not a link
  to scrape.
- **Justify or drop**: each requirement states why, or is removed.
- **No dead ends**: no empty, stale, or broken links.
- **Snapshot, not history**: a doc states the subject's current
  behavior only - no development chronology, task or plan ids, round
  dates, or development details. Git holds history, plans hold
  planning, and a claim's source sits where § Sources puts it.
- **Closed link scope**: a doc links only sibling documents inside the
  docs tree, other files of the same project (`config/`, `scripts/`,
  `src/`), or external URLs - never plan files (live or archived),
  task reports, or `.claude/` paths. Those name artifacts that move,
  are archived, or are retired, so the citation drifts while still
  reading as precise. An `archive/` directory inside the docs tree is
  exempt, and a project's root `README.md` may cite the `.claude/`
  paths it describes. A project's docs gate checks this mechanically
  where the project has one.
- **Right content, right place**: exclude test/environment artifacts;
  include the real parameters.
- **DRY**: a shared fact lives in one doc; others cross-reference it
  (numbers especially - `rules/writing-artifacts.md § One home per number`).
- **Real examples**: an example is an executed call or case shown with its
  output, cited when kept - as a report doc (§ Diataxis typing);
  secrets as placeholders; never invented. It sits in the section it
  illustrates.

## Verification gate

No new or touched doc is complete until an **independent agent** - never
the author, for `<docs>`, `README.md` and the CHANGELOG the doc-writer
seat (`run.md § Seats`) - has run the three checks below over it and
every mismatch they list is fixed. The verifier is the docs-verifier
seat (`agents/dev-docs-verifier.md`, the `dev-docs-verifier` type) the
session - in a run, the runner (`run.md § Close` 3) - dispatches without
pausing to confirm - a doc the author also verified is unverified -
bounded by `verification-policy.md § Verifier isolation`. The prose class
sets the clearing review: rules, skills, and planning prose - the close
review (`branch-plan.md § Closing routine`; reviewer mandate:
`agents/code-reviewer.md`; a batch-scoped run: the batch-close full-diff
pass, `run.md § Batch close`); `<docs>` feature docs, `README.md` and
the CHANGELOG's `## [Unreleased]` entry (a released block is the
release's record, `release.md` 4) - the docs verifier.

The checks:

1. **Claims**: for a doc written from a plan's `## Claims` (§ Claims),
   each claim the plan lists against its task report entry and the
   link that ends it in the doc, the linked file read - for a `probe`
   claim the `<docs>/reports/` report, matching its entry; a CHANGELOG
   line, ending in no link, against its entry alone - and each `drop`
   claim's text gone from the doc. Otherwise each claim against its
   section's source (§ Sources), for a doc the writer touched the one
   its report names. The docs verifier probes nothing, and a claim its
   source does not confirm is listed.
2. **Coherence**: the text read alone - what is ambiguous to a reader
   holding only it, and where it contradicts itself. The first check
   asks whether the text is true, this one whether it is usable cold.
3. **Conformity**: the text against `writing.md`,
   `rules/writing-artifacts.md` and this framework.

All three run over the text the branch changed, plus the sentences
needed to read it. Check 1 also runs over the rest of a `<docs>` doc,
`README.md` or the CHANGELOG entry, since a claim's source can change
under a line no branch touches; there it lists only a claim its source
contradicts.

The three return one mismatch list, each entry naming the text and the
check it fails. The list is the verifier's: none of it is written into
a doc. A large doc splits across one verifier dispatch per section, the
split being the dispatcher's: a seat holds no Agent tool.

Either path is artifact-free: version-control history records that the
review ran; no separate stamp or ledger is kept.

## Sources

What a doc's claim is confirmed against:

- a probed claim: a report doc (§ Diataxis typing);
- a read claim: a source path and symbol or heading, a spec or vendor
  page, or an adapted reference;
- a claim resting on both: one of each.

A citation of a citation is no source, and an inferred claim has none.

Where the plan's `## Claims` lists claims (§ Claims), each claim the
doc writer writes ends in a link: to the file its task report entry's
`Source:` or `Test:` names, the symbol or test named in the link text,
or, for a `probe` claim, to the `<docs>/reports/` report written from
its entry (§ Diataxis typing). A CHANGELOG line ends in no link. For
a plan without `## Claims`, the doc writer's report names the source
per section (`agents/dev-doc-writer.md`), and the doc carries no
source cell, column or mark.

- Prefer a report over a read source.
- A version- or environment-specific fact says which version or
  environment it was confirmed against in its report doc or the doc
  writer's report, never as inline chronology.
- A recalled or documented fact that names a file, flag, or field is
  re-checked against the current system before it is relied on.

## Claims

A strict plan (`branch-plan.md § Body`) ends on two sections, each
holding `- none` when it has nothing to list; a normal plan has neither,
and its docs are written from the diff:

- `## Claims` - one line per claim the branch's docs make or drop,
  `- Item <n> (<kind>): <claim>`, `Item <n>` being the plan's nth
  checkbox, the item whose change the claim describes. The kind is one
  of:
  - `source` - a fact of the project's own code, proven by reading it;
  - `probe` - a fact of an external system, proven by a call to it;
    the planner gives it only to an item whose code calls that system;
  - `drop` - text the docs remove, proven by showing the behavior gone.
- `## Proven` - one line per statement the docs rely on that is
  already proven, `- <statement>: <evidence>`, the evidence a source
  path, a test or a `<docs>/reports/` report, never a task report: that
  lives only as long as its R (`branch-plan.md § Task report`).

The task report's `## Claims` repeats each claim, word for word, as an
entry whose fields hold its evidence; the planner writes the entries
with their fields blank, and a plan whose `## Claims` is `- none` gives
its report no `## Claims`:

    ## Claims
    - Item 1 (source): <claim>
      Source: <the file and symbol, or the test, that shows it>
    - Item 2 (probe): <claim>
      Call: <the call>
      Output:
        <its output, each line indented under the field>
      Environment: <where the call ran>
    - Item 3 (drop): <claim>
      Source: <the file and line, or the test, showing the behavior gone>

Any entry may add `Test: <the test pinning the claim>`. A claim wraps
at two spaces, in the plan and in its entry, and the two match on its
text with the wrapped lines joined by one space; a field sits at two
spaces, its value's own lines at three or more.

The implementer fills its item's entries in the commit that marks the
item `[x]` (`agents/dev-implementer.md § Steps`), a probe entry from
the second of its item's probes, the one confirming the values its
test pins.
`scripts/ci/check-plan-text.sh` fails a plan the branch adds without
either section, a claim whose entry the report lacks, and a done item's
entry with an empty field - one its kind needs or one it carries - a
value counting on the field's line or on lines indented under it.
