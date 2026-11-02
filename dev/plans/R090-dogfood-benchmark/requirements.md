---
approved: yes
kind: test
---

# R090: Dogfood benchmark

## Goal

Agents do good work when the framework prepares and equips them first: make
it do that, and measure it so models, settings and toolset changes can be
compared for efficiency, proven on one low-complexity Node.js fixture.

## Outcomes

1. Before work, the framework gives each implementer a plan covering the
   task's nuances, the code style guide and the spec; a complex task adds
   reference docs and examples of the expected result.
2. A human may answer and approve in planning; development runs unattended.
3. A fixture is a fixed list of requirements with a complexity level and a
   language, and an acceptance test suite the run session cannot read.
4. A run records planning time, the human's share apart, and development time.
5. A run records cost in total, per batch and per task, from a tool.
6. A run scores code by the hidden suite and by review against the guide and
   spec the implementer got, and docs by a reviewer against a checklist.
7. Each result names its fixture, toolset commit and configuration.
8. Two runs of the first fixture on one configuration stay within a spread
   per measure that the method states before they run.
9. Run results have one home, which every run updates.

## Constraints

- Fixtures live in a private repo; a run gets only its requirements.
- More fixtures, by complexity level and language, wait for outcome 8.

## Design

A held-out benchmark in the SWE-bench style. `skills/dev/` equips seats;
`skills/dogfooding/` runs and scores a fixture per configuration; the runs
table and `context-cost.py` carry the new measures; the fixtures repo is new.
