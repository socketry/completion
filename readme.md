# Completion

Completion installs shell adapter scripts for command-line tools which expose a dedicated completion executable. It provides small per-command or generic shell shims, plus shared shell helpers for Bash, Fish, and Zsh.

[![Development Status](https://github.com/socketry/completion/workflows/Test/badge.svg)](https://github.com/socketry/completion/actions?workflow=Test)

## Motivation

Shell completion is useful, but each shell has different installation paths, script conventions, and interfaces for native path, directory, executable, and delegated completion. This gem provides a small command-line tool for installing those adapters consistently.

The command being completed is expected to provide a companion executable named `completion-<command>`. For example, `falcon` can expose completions using `completion-falcon`. This keeps completion support explicit and avoids running arbitrary commands just to discover whether they support completion.

## Usage

Please see the [project documentation](https://socketry.github.io/completion/) for more details.

  - [Getting Started](https://socketry.github.io/completion/guides/getting-started/index) - This guide explains how to install and use `completion` to add shell completion adapters for command-line tools.

## Releases

Please see the [project releases](https://socketry.github.io/completion/releases/index) for all releases.

### v0.0.2

  - Add `completion uninstall` for removing installed shell adapter scripts.
  - Add managed metadata markers to generated shell scripts and support `completion uninstall --all`.

### v0.0.1

  - Fix generic Fish completion installation by loading the adapter at shell startup and resolving completion executables from `PATH`.

## See Also

  - [Samovar](https://github.com/socketry/samovar) provides the command completion interface used by Samovar-based commands.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Running Tests

To run the test suite:

``` shell
bundle exec sus
```

### Making Releases

To make a new release:

``` shell
bundle exec bake gem:release:patch # or minor or major
```

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
