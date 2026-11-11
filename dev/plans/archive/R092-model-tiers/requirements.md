---
approved: yes
kind: mnt
---

# R092: Implementer model tiers

## Goal

Pay for the implementer's model in proportion to the item: a cheaper model
where it will not fail, the strongest where a wrong result costs more than
the price, Opus otherwise. A tier is chosen only when it pays.

## Outcomes

1. The planner runs on Opus.
2. The planner tags a branch-plan item `(sonnet)` or `(fable)` only with a
   one-clause reason in the item; an untagged item runs on Opus.
3. `(sonnet)` fits a fully specified, local item: named files, a testable
   outcome, no design choice left.
4. `(fable)` fits an item where a wrong result costs more than the price
   gap: concurrency or state, security or data integrity, a cross-module
   design choice the plan leaves open, a bug of unknown cause.
5. The user approves each `(fable)` item with the plan; an item not approved
   runs on Opus.
6. An item still red after its fix attempt reruns once on the next tier up,
   then halts; a rise to Fable asks the user first.
7. No tier sets the implementer's effort.
8. The mechanical-commit predicate and the `(judgment-heavy)` tag are gone.

## Constraints

- A fix deletes before it adds a rule; built in-session, one PR.
- The capacity fallback, a tier down on a rate limit, stays as it is.

## Design

A difficulty-routed cascade: the planner routes each item to a tier, a
failure escalates one tier. `verification-policy.md § Models` holds the
tiers; `dev-planner.md` tags, `write-plan.md` and `run.md` ask for Fable.
