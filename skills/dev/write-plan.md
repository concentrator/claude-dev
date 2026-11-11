# Writing Plans

Generate a branch plan (`<plans>/R<NNN>-<slug>/<task-id>-<slug>.md`)
from a task in its initiative's `tasks.md`. Invoked within the detail
round (`/dev plan R<NNN>`), or per task via `/dev plan <task-id>` /
`all`. `/dev plan <slug>` adjusts a plan that already exists, which is
`plan.md § Adjusting existing plans`.

## Inputs

The session's own, which settle step 2 - the slug, the branch prefix
and the plan file:

- Task ID (e.g. `R008-T001`; legacy `T-014`) from the parent R's
  `<plans>/R<NNN>-<slug>/tasks.md`
- Task tag: `[feat] | [fix] | [refactor] | [doc] | [test] | [mnt]`

The planner's set is `agents/dev-planner.md § Inputs`.

## Steps

Steps 1 and 3 to 5 belong to one planner dispatched per task
(`agents/dev-planner.md`); its step 1 runs once the session has
settled step 2. The session keeps steps 2, 6 and 7 and writes no plan
text itself.

1. **Resolve chain** - the planner's (`agents/dev-planner.md § Steps`
   1).
2. **Propose slug and mode** (`git-workflow.md § Trunk` rules;
   `branch-plan.md § Modes`); confirm both with the user. The mode is
   `normal` unless the user picks `strict`. The slug names both the plan
   branch and the plan file `<plans>/R<NNN>-<slug>/<task-id>-<slug>.md`,
   so it is settled and the branch created before the dispatch, which
   names that file. A small change settled its slug at `brainstorm.md`
   step 2, and its branch is the task's own, already cut
   (`plan.md § Where plans live in git`).
3. **Decompose work**, a strict plan proven first - the planner's
   (`agents/dev-planner.md § Steps` 2 and 3).
4. **Add header** - the planner's (`agents/dev-planner.md § Steps` 4).
5. **Add the mandatory final item**, write the task report skeleton and
   commit both - the planner's (`agents/dev-planner.md § Steps` 5 to
   7).
6. **Cold read**, strict mode only, per
   `companions/verification-policy.md § Comprehension check`: one read
   of the plan, its task report, the docs and the code. Each gap it
   reports goes to the planner once, whose fix lands in the report's
   `## Planner`; the plan is not read again, and the header then
   records `cold-read: passed`. The session commits that header edit on
   the branch carrying the plan. A plan whose `depends-on` names an
   unmerged task is read at its start instead.
7. **Confirm with user**, who also approves each `(fable)` item
   (`branch-plan.md § Body`): the session drops a declined item's tag
   from the plan, committed on the branch carrying it, so that item
   runs on Opus. Under `release-routine: yes` the session then adds
   the plan's branch to the open release plan, if one exists, as the
   `templates.md § Release plan` entry the closing routine marks,
   committed on the branch carrying the plan. It delivers the committed
   plan through `finish.md § 3`: its short-lived plan MR/PR
   (`plan.md § Where plans live in git`) takes the decision any branch
   takes. A small change's
   plan is not delivered alone: it stays committed on the task's
   branch (`plan.md § Planning rounds`), where the session commits the
   user's confirmation as `approved: yes` in its header
   (`branch-plan.md § Header`), the record `/dev run` admits it by.

## Soft cap

Per `branch-plan.md § Size cap` (warn/split thresholds live there).

## Bulk mode (`/dev plan all`)

The same dispatch, once per open task lacking a plan: the tasks are
independent, so the planners run in parallel on the one plan branch
the session cut for all of them. Strict plans take their read (step 6)
first; then the user reviews all slugs and plans in one pass, and they
are delivered as one plan MR/PR.

## Out of scope

- Per-commit implementation - the execution skill (`feat`,
  `fix`, `refactor`) handles iteration.
- Initiative / task creation - separate `/dev plan` targets.
