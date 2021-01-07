# l.rb

A lint runner. Run locally configured lint commands via a generic CLI with standard options/features.


## Install

Open a terminal and run this command ([view source](https://git.io/l.rb--install)):

```
$ curl -L https://git.io/l.rb--install | sh
```

## Usage

(this assumes you've configured linters commands for Rubocop, ESLint, and SCSSLint)

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
        --[no-]dry-run               output each linter command to $stdout without executing
    -l, --[no-]list                  list source files on $stdout
    -d, --[no-]debug                 run in debug mode
        --version
        --help
$ l
```

#### Debug Mode

```
$ runlints -d
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
$ runlints -d -c
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
$ runlints -d -c -r master
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
$ runlints --dry-run
Running Rubocop
rubocop .


Running ES Lint
./node_modules/.bin/eslint .


Running SCSS Lint
scss-lint .
```

This option only outputs the linter command it would have run. It does not execute the linter command.

#### Specifically run or don't run individual linters

```
$ runlints --rubocop
Running Rubocop
rubocop .
```

```
$ runlints --no-es-lint
Running Rubocop
rubocop .


Running SCSS Lint
scss-lint .
```

Each linter gets a CLI option that allows you to toggle it on/off. If no options are given, all linters are run.

#### List

```
$ runlints -l
app/file1.rb
app/file2.js
app/file3.scss
```

This option, similar to `--dry-run`, does not execute any linter command. It lists out each source file it would execute to `$stdout`.

## Configuration

Add a `./.l.yml` in your project's root:

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
  - name: "Rubocop",
    cmd: "rubocop"
    extensions:
      - ".rb"
    cli_abbrev: "u"

  - name: "ES Lint",
    cmd: "./node_modules/.bin/eslint",
    extensions:
      - ".js"

  - name: "SCSS Lint",
    cmd: "scss-lint",
    extensions:
      - ".scss"
```

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

[Ruby](https://www.ruby-lang.org/) `~> 2.5`.

[Git](https://git-scm.com/).

## Uninstall

Open a terminal and run this command ([view source](http://git.io/l.rb---uninstall)):

```
$ curl -L http://git.io/l.rb---uninstall | sh
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
