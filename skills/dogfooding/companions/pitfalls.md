# Known pitfalls

Each cost real time on 2026-10-29. The fix column is what this skill or its
brief now does about it; the toolset fixes belong in `claude-dev`'s backlog.

| Pitfall | What happened | Fix |
| --- | --- | --- |
| Repository invisible | `add_repo` returned not found for a private repository; the GitHub App did not cover it | `preparation.md` step 2; public visibility alone fixes reads, not pushes |
| Wrong GitHub identity | The connected GitHub user was not the repository owner | Reconnect as the owner, or invite the connected user with write access and still cover the repository with the app |
| Child in `default` mode | The review session was in `default`, so `auto` was refused for the child; the child then blocked on its first Write | `preparation.md` step 3: switch the review session first; only the owner can switch it, in the app |
| Summary never arrived | The run's `send_message` was refused: the review session was not trusted to reach other sessions | `preparation.md` step 6: answer the trust card once per review session, before the run |
| Installer refused | `auto` mode refused `install-dev.sh` as external code, and a manual copy as a bypass; no hooks or skill loaded | `preparation.md` step 4 installs from the environment's setup script; `brief.md` step 1 checks the install and records what is absent |
| Merges refused | Every merge was refused as "Merge Without Review", even after review and green CI | `brief.md` step 2 records the refusal and the run goes on as the toolset directs; the review session merges; toolset backlog: ship the merge allow rule |
| Stacked merge landed on a branch | Merging PR 2 while its base was the scaffold branch put it there, not on `main` | `finishing.md` step 3: retarget to `main` first |
| `gh pr` unusable | Cloud `gh` is REST only; the declared `gh pr view` and `gh pr checks` fail with 403 | `brief.md` step 2 records each failure; the project declares the REST forms of `skills/dev/companions/toolchain.md` § State check, § CI wait and § Merge |
| Tag impossible | `git push` of a tag and `gh api git/refs` both refused by the proxy | `finishing.md` step 5, by hand |
| Branch deletion refused | `git push --delete` is classed as destructive | Leave branches; the owner cleans up |
| Safety-net check-in failed | The `send_later` reminder fired with access denied after the session restarted | Re-arm the check-in after any worker restart, or rely on `get_session` polls from the skill |
| Effort not settable | `create_session` has no effort parameter | The system prompt addition asks for high effort; record the served model from `get_session` |
