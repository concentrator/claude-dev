# R091-T003 report

## Implementer

- Item 2: `install-dev.sh` `register` now replaces its own entry, since it skipped a hook already registered and an install would keep the old matcher.
