# l.rb

A lint runner. Run locally configured lint commands via a generic CLI with standard options/features.

```
$ l                     # all configured linters, the config's default paths
$ l -c                  # only files with uncommitted changes
$ l -c -a               # ... and autocorrect what can be corrected
$ l -c -r main          # only files changed against a ref
$ l -u -c               # only Rubocop, only changed files
$ l app/models/user.rb  # an explicit file list
$ l --help
```

## What It Does...

**Reads a `.l.yml` config:** each linter declares a `cmd`, an optional
  `autocorrect_cmd`, the file extensions it applies to, and an optional
  single-letter `cli_abbrev` that becomes its own CLI flag.

**Resolves which files to lint:** from explicit paths, or from git — `-c` for
  uncommitted changes, `-r REF` against a ref — filtered by each linter's
  extensions.

**Runs each linter on those files:** every linter runs even if an earlier one
  fails, and `l` exits non-zero if any of them did.

**Autocorrects on request:** `-a` swaps each linter's `cmd` for its
  `autocorrect_cmd`. **A linter with no `autocorrect_cmd` is skipped entirely
  under `-a`**, though it still prints its `Running <name>` header.

## Install

Open a terminal and run this command ([view source](https://raw.githubusercontent.com/redding/l.rb/main/install.sh)):

(installs to `$HOME/.local/bin`; set `PREFIX` to override, e.g. `PREFIX=/usr/local`)

```
$ curl -L https://raw.githubusercontent.com/redding/l.rb/main/install.sh | sh
```

## Usage

Given a `./.l.yml` in your project's root, e.g.:

```yaml
source_file_paths:
  - app
  - config
  - db
  - lib
  - script
  - test

ignored_file_paths:
  - test/fixtures

linters:
  - name: "Rubocop"
    cmd: "rubocop"
    autocorrect_cmd: "rubocop -a"
    extensions:
      - ".rb"
    cli_abbrev: "u"

  - name: "ES Lint"
    cmd: "./node_modules/.bin/eslint"
    extensions:
      - ".js"

  - name: "SCSS Lint"
    cmd: "scss-lint"
    extensions:
      - ".scss"
```

Then:

```
$ cd my/project
$ l -h
Usage: l [options] [FILES]

Options:
    -u, --[no-]rubocop               specifically run or don't run Rubocop
    -e, --[no-]es-lint               specifically run or don't run ES Lint
    -s, --[no-]scss-lint             specifically run or don't run SCSS Lint
    -c, --[no-]changed-only          only run source files with changes
    -r, --changed-ref VALUE          reference for changes, use with `-c` opt
    -a, --[no-]autocorrect           autocorrect any correctable violations
        --[no-]dry-run               output each linter command to $stdout without executing
    -l, --[no-]list                  list source files on $stdout
    -d, --[no-]debug                 run in debug mode
        --version
        --help
$ l
```

#### Debug Mode

```
$ l -d
[DEBUG] CLI init and parse...          (6.686 ms)
[DEBUG] 0 specified source files:
Running Rubocop
[DEBUG]   rubocop .


Running ES Lint
[DEBUG]   ./node_modules/.bin/eslint .


Running SCSS Lint
[DEBUG]   scss-lint .
```

This option, in addition to executing the linter command, outputs a bunch of detailed debug information.

#### Changed Only

```
$ l -d -c
[DEBUG] CLI init and parse...            (7.138 ms)
[DEBUG] Lookup changed source files...   (24.889 ms)
[DEBUG]   `git diff --no-ext-diff --name-only  -- . && git ls-files --others --exclude-standard -- .`
[DEBUG] 1 specified source files:
[DEBUG]   app/file1.rb
Running Rubocop
[DEBUG]   rubocop app/file1.rb


Running ES Lint


Running SCSS Lint
```

This runs a git command to determine which files have been updated (relative to `HEAD` by default) and only run the linters on those files.

You can specify a custom git ref to use instead:

```
$ l -d -c -r master
[DEBUG] CLI init and parse...            (6.933 ms)
[DEBUG] Lookup changed source files...   (162.297 ms)
[DEBUG]   `git diff --no-ext-diff --name-only master -- . && git ls-files --others --exclude-standard -- .`
[DEBUG] 2 specified source files:
[DEBUG]   app/file2.js
[DEBUG]   app/file3.scss


Running ES Lint
[DEBUG]   ./node_modules/.bin/eslint app/file2.js


Running SCSS Lint
[DEBUG]   scss-lint app/file3.scss
```

#### Dry-Run

```
$ l --dry-run
Running Rubocop
rubocop .


Running ES Lint
./node_modules/.bin/eslint .


Running SCSS Lint
scss-lint .
```

This option only outputs the linter command it would have run. It does not execute the linter command.

#### Autocorrect

```
$ l --dry-run -a
Running Rubocop
rubocop -a .
```

This option runs the optional `autocorrect_cmd` configured on the linters. If linters do not define an autocorrect cmd, they will not be run.

#### Specifically run or don't run individual linters

```
$ l --rubocop
Running Rubocop
rubocop .
```

```
$ l --no-es-lint
Running Rubocop
rubocop .


Running SCSS Lint
scss-lint .
```

Each linter gets a CLI option that allows you to toggle it on/off. If no options are given, all linters are run.

#### List

```
$ l -l
app/file1.rb
app/file2.js
app/file3.scss
```

This option, similar to `--dry-run`, does not execute any linter command. It lists out each source file it would execute to `$stdout`.

## Configuration

#### `source_file_paths:`

Optional. A list of paths to look for source files. Defaults to `["./"]`.


#### `ignored_file_paths:`

Optional. A list of source file paths to ignore. Defaults to `[]`.

#### `linters:`

Required. A list of linter configurations to run. Each linter will be run in the order it is listed.

#### `linters[name]:`

Required. A String name used to identify the linter.

#### `linters[cmd]:`

Required. The system command to use.

#### `linters[extensions]:`

Required. A list of file extensions to identify the files that should be linted.

#### `linters[cli_abbrev]:`

Optional. An String letter used as the abbreviated CLI flag for the linter. Defaults to the first letter of the linters `name:`. Cannot be `"c"`, `"r"`, `"l"`, or `"d"` as these conflict with other CLI options.

## Dependencies

[Ruby](https://www.ruby-lang.org/) `>= 2.5`, developed against the version in `.ruby-version`.

[Git](https://git-scm.com/).

## Uninstall

Open a terminal and run this command ([view source](https://raw.githubusercontent.com/redding/l.rb/main/uninstall.sh)):

```
$ curl -L https://raw.githubusercontent.com/redding/l.rb/main/uninstall.sh | sh
```

## Releasing

The version string lives in three places and they must match:

- `libexec/l.rb` — `VERSION`
- `install.sh` — `L_RELEASE`
- `release.sh` — `L_RELEASE`

To cut a release:

1. Check out `main` and make sure it is up to date. The version bump and
   changelog entry are committed straight to `main` and tagged there — they do
   not go through a pull request, and `release.sh` tags whatever commit is
   checked out.
2. Bump the version in all three files.
3. Add a `CHANGELOG.md` entry — a `## <version> / <date>` heading, then one
   line per change ending in its commit SHA.
4. Commit those changes.
5. Run `./release.sh`. It refuses to run against a dirty working tree, then
   tags the release and pushes the commits and the tag.

`install.sh` fetches the tarball for the tag, so the tag must exist before the
published install command resolves to the new version.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Running the tests

```
$ bundle install
$ bundle exec assert                            # the whole suite
$ bundle exec assert test/unit/runner_tests.rb  # one file
```

Tests run on the Ruby in `.ruby-version`. This repo is configured for
[t.rb](https://github.com/redding/t.rb) (`.t.yml`), so `t` and `t -c` work too
if you have it installed.
