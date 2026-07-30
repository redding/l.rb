# l.rb — notes for agents and non-interactive shells

`l` runs the lint commands a project declares in its `.l.yml`. There is no
built-in knowledge of any particular linter: the config supplies the command
strings, and `l` decides which files to hand them.

## Always scope the run

`l` with no scope lints the config's default paths, which in a large repo
means every file a linter claims. Pass a scope:

- `l -c` — files with uncommitted changes
- `l -c -r <ref>` — files changed against a ref
- `l <file> [<file>...]` — an explicit list

This matters most for autocorrecting linters and formatters: an unscoped
`-a` run rewrites the whole tree and produces an unreviewable diff.

## `-c` reads the working tree, not the branch

`-c` means *uncommitted* changes. Once work is committed it reports nothing,
so a post-commit `l -c` is a no-op that looks like a pass. Use
`-c -r <base-branch>` to lint a branch's worth of changes, or name the files.

## `-a` only runs linters that declare an `autocorrect_cmd`

Each linter in `.l.yml` has a `cmd` and may have an `autocorrect_cmd`. Under
`-a` the autocorrect command is used — and **a linter with no
`autocorrect_cmd` is skipped for that run**. It still prints its `Running
<name>` header, so the output is indistinguishable from a linter that ran
and found nothing.

If a formatter seems not to be formatting, check whether its `.l.yml` entry
declares an `autocorrect_cmd` before looking anywhere else.

## Exit status reflects the result

`l` exits non-zero when any linter reported a problem, so it can gate a hook
or a CI step. Every linter still runs after one fails, so a single failure
does not suppress what the others would report.

Confirm what actually ran with `--dry-run`, which prints each command
without executing it. A linter that emits no command there did not run.

## Config lookup is per-directory

The config is `./.l.yml`, resolved from the current directory. Running `l`
from outside a project — or from a subdirectory whose parent holds the
config — will not find it.
