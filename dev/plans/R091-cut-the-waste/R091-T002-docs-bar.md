---
task: R091-T002
type: mnt
mode: normal
---

- [ ] Write less, but better: a doc declares its type and one subject, a
  reference keeps the skeleton with a full parameter spec table, no
  narration of the code and no inline source or test citations, paragraphs
  short; `check-caps.sh` fails a doc over 300 lines. Approach:
  `documentation.md` (top rule, § Detail bar, § Sources), the caps check.
- [ ] `/dev start` sets the docs structure up front: `index.md` plus one
  file per component or topic, linked from the index. Approach: `start.md`,
  `layout.md § Docs`.
- [ ] Docs are written once, at close; normal mode dispatches no docs
  verifier. Approach: `run.md § Seats`, `§ Close` 3, `branch-plan.md
  § Closing routine` 7.
- [ ] No gate pairs code files with docs: `check-doc-sync.sh`, its test,
  its `run-all.sh` entry and `MAINTENANCE.md § Doc-sync pairs` go.
  Approach: those, then README and DESIGN.md.
- [ ] Complete the branch: cleanup, mark plan complete, mark the task `[x]`
  in the R's `tasks.md`, commit.
