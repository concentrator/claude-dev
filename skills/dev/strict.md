# Strict mode

What a plan whose header reads `mode: strict` adds to `branch-plan.md`.
Only a strict plan's seats and session read this file.

## Planner

The planner proves the plan before writing it: it builds a throwaway
draft in the scratchpad, runs it until it produces the expected result,
and probes every undocumented surface it uses. A wire-level detail
(response envelope, field names, pagination keys) comes from those
probes, never from the repo's idiom; a claim it did not run is not
written as fact. Below the plan's items, `## Claims` lists each claim
the branch's docs will make or drop, with its item and kind, and
`## Proven` each statement they rely on that is already proven
(`companions/documentation.md § Claims`).

What the planner ran, and only that, goes to the task report's
`## Planner`, never the plan:

    ## Planner
    ### Probes
    #### <surface, e.g. POST /v2/route>
    Source: <doc path, spec URL or code the surface was read from>
    Request: <the call that worked>
    Response: <observed body, trimmed>
    Errors hit: <what failed and what fixed it>
    Trap: <behavior that would mislead an implementer>
    ### Drafts
    #### <the item it serves>
    Draft: <working snippet from the draft>
    Showed: <what its run produced, edge cases it hit included>

Each draft names the probes it relies on. The planner creates the task
report with the plan, in the same commit, as a skeleton: the title,
`## Claims` with a blank entry per claim the plan lists, and the
`## Implementer` and `## Review` headings, after its filled
`## Planner`. A cold-read gap's fix (`write-plan.md` step 6) lands in
`## Planner` too. A strict plan needs `cold-read: passed` to run.

## Task report

The seats fill the rest of the report in this form:

    # R0NN-T00N report

    ## Implementer
    ### Divergences
    - <item>: <where the code left the plan, why, and the result>
    ### Findings
    - [ ] <item>: <discovery outside the item's scope>
      Evidence: observed <output> | test <failing test> | contract <spec>

    ## Answers
    - Item <n>: <the user's answer to that item's halt>

    ## Review
    - [ ] <item>: <issue> (Critical | Important | Suggestion) - <file:line>
      Evidence: observed ... | test ... | contract ...

A checkbox without an `Evidence:` line of the three types fails
`scripts/ci/check-plan-text.sh`.

## Implementer

The draft, probes and warnings in `## Planner` are the planner's
claims: check them, don't trust them, and develop the draft into
production code with tests. Fill each of your item's entries under the
task report's `## Claims` with the evidence its kind takes
(`companions/documentation.md § Claims`). A probe reads only, or writes
on a test client: an account, tenant or environment of the external
system that your item or an `## Answers` entry names for tests, by
name, never by its credentials. A probe claim needing a write with no
test client named is a NEEDS_CONTEXT report, and a `## Proven`
statement is never probed. Whatever the plan's `type:`, an item with a
probe claim runs a probe, a failing test, a second probe confirming the
values the test pins, then the code.
