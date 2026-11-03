---
approved: yes
kind: mnt
---

# R091: Cut the waste

## Goal

Cut DEV's token cost by 1.5x to 2x and make it faster by dropping text nobody
reads: plan upkeep, per-step reports, docs that restate code, and context lost
at compaction. The procedure serves the outcome, never the reverse.

## Outcomes

1. In normal mode any seat may change the plan when the requirements stay
   the same, with no planner dispatch, cold read or approval.
2. In normal mode the session or the working implementer applies a small fix
   mid-branch; no new seat is dispatched for it.
3. In normal mode the task report holds at most one line per item, written
   after the item is checked; plans and reports carry no claims or evidence.
4. Strict mode keeps the full procedure.
5. Docs are written once, at close; normal mode runs no docs verifier.
6. A project sets its docs structure at start: an index, a file per topic.
7. A doc gives purpose, use, non-obvious facts and decisions, never a prose
   copy of the code; CI fails a doc over 300 lines.
8. No gate pairs code files with docs.
9. After a merge the session writes a short handoff and asks for `/clear`;
   the next session starts with it.
10. Each seat and mode file reads only what its step needs.

## Constraints

- A fix deletes before it adds a rule; built in-session, one PR per task.

## Design

Lean waste removal. `branch-plan.md`, `run.md` and the seats lose plan upkeep,
claims and per-change dispatch; `check-doc-sync.sh` gives way to a doc line
cap; `dev-session-brief.sh` injects the handoff.
