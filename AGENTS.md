# l.rb — notes for agents working on this repo

Notes for *developing* `l.rb`. For using the tool, see the README.

## The whole program is one file

`libexec/l.rb` is it — around 590 lines, no `lib/`, no gemspec. Install
symlinks `$PREFIX/bin/l` at that file and runs it directly.

Two constraints follow:

- **Stdlib only at runtime.** The file requires `benchmark`, `set`, and
  `yaml` and nothing else. `pry` and `assert` in the `Gemfile` are for
  development; a runtime `require` of a gem would break every install, since
  there is no bundle around the installed script.
- **Ruby floor is real.** The file is run by whatever Ruby the user's shell
  resolves, not a pinned one. `class ::Hash` is reopened near the bottom to
  backport a method for older interpreters — that is the shape a
  compatibility fix takes here.

## Layout of that file

| region | role |
|---|---|
| `module LdotRB` | entry point — `.run`, `.apply`, `.config`, `.bench`, `.help_msg` |
| `Config` | parses `./.l.yml`, holds CLI settings and the `Linter` list |
| `Linter` | one per config entry; builds the command string for a file list |
| `Runner` | resolves which files to lint, then runs each linter |
| `GitChangedFiles` | the `-c` / `-r` git integration |
| `RoundedMillisecondTime` | benchmarking helper |
| `CLIRB` | **vendored** option parser, copied from redding/cli.rb |
| `class ::Hash` | backport for older Rubies |

`CLIRB` is a verbatim copy carrying its own version comment. Fix bugs
upstream in redding/cli.rb and re-copy rather than editing it here, or the
next copy silently reverts the change.

## Requiring the file runs the CLI

The last lines are:

```ruby
unless ENV["LDOTRB_DISABLE_RUN"]
  # ... parse ARGV and run
end
```

`test/helper.rb` sets `LDOTRB_DISABLE_RUN` before requiring, which is the only
reason the suite can load the file without executing a lint run. Anything else
that requires `libexec/l` must do the same.

## Tests

```
$ bundle install
$ bundle exec assert                            # the whole suite
$ bundle exec assert test/unit/runner_tests.rb  # one file
```

The framework is [assert](https://github.com/redding/assert), not RSpec or
Minitest. `test/helper.rb` is auto-required.

- `test/unit/*_tests.rb` mirrors the classes above one-to-one.
- `test/support/` holds fixture files (`app/file1.rb`, `app/file2.js`, …) that
  the file-resolution logic actually globs over. **Adding a file there can
  change expectations in the config and runner tests** — it is fixture data,
  not scratch space.
- Stubbing is `Assert.stub(obj, :meth){ ... }`. It requires the receiver to
  `respond_to?` the method, so private `Kernel` methods like `system` cannot be
  stubbed directly — that is why command execution sits behind a named
  `execute_cmd` method rather than calling `system` inline.

Most tests drive `Runner` with `dry_run` or `list` stubbed true, so no
subprocess is spawned. If you change execution behavior, add coverage that
exercises the executing path — the default setup will not reach it.

## Maintenance notes

- The version string lives in three files and must match: `libexec/l.rb`
  (`VERSION`), `install.sh` (`L_RELEASE`), `release.sh` (`L_RELEASE`). The
  duplication is deliberate — `install.sh` fetches a release *tag*.
- `CHANGELOG.md` entries carry the commit SHA of each change.
- Release steps are in the README under `## Releasing`. Version bumps are
  committed on `main` and tagged there, not merged through a pull request.
- This repo has no CI. Run the suite locally before pushing; nothing else will.
- `.l.yml` here declares `linters:` with nothing under it, so running `l` in
  this repo lints nothing. `.t.yml` is configured, so `t` works.
