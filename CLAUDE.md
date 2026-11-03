# Project rules

## Git workflow (owner's standing rule)
- After every change: commit, push the working branch, then **merge it into `main` and push `main` right away**, so every change lands in `main` immediately.
- Before merging, `flutter analyze` and `flutter test` must pass. Never merge a red build into `main`.
- Prefer fast-forward merges; if `main` moved, rebase/merge it into the working branch first, re-run the checks, then merge.

## Checks
- `flutter analyze`
- `flutter test`
- Label reference test (needs the real printing plugin): `xvfb-run -a flutter test integration_test -d linux`. Any intentional label change must update the hashes in `integration_test/label_snapshot_test.dart` in the same commit.

## Context
- Plan and decisions: `REPORT.md` (Arabic). Keep its "حالة التنفيذ" table up to date after each phase.
