# Getting Started

This guide explains how to install and use `completion` to add shell completion adapters for command-line tools.

## Installation

Add the gem to your project:

~~~ bash
$ bundle add completion
~~~

Or install it yourself as:

~~~ bash
$ gem install completion
~~~

The command line executable is named `completion`:

~~~ bash
$ completion --help
~~~

## Core Concepts

`completion` installs shell adapter scripts. The adapters do not run the command being completed. Instead, they call a dedicated completion executable named `completion-<command>`.

For example, a command named `falcon` should provide:

~~~ text
falcon
completion-falcon
~~~

When the shell asks for completions for `falcon`, the installed adapter calls `completion-falcon` with the command-line arguments up to the cursor.

This convention also works for commands invoked by path:

~~~ text
falcon          -> completion-falcon
bin/falcon      -> bin/completion-falcon
./bin/falcon    -> ./bin/completion-falcon
/path/falcon    -> /path/completion-falcon
~~~

## Installing a Generic Adapter

Install a generic adapter for the current shell:

~~~ bash
$ completion install
~~~

The shell is detected from `ENV["SHELL"]`. The generic adapter checks whether a matching `completion-<command>` executable exists before handling completion for a command.

You can specify the shell explicitly:

~~~ bash
$ completion install --shell fish
~~~

Supported shells are:

- `bash`
- `fish`
- `zsh`

## Installing a Command Adapter

Install an adapter for a specific command:

~~~ bash
$ completion install --command falcon
~~~

This installs completion support only for `falcon`.

You can specify the shell and adapter directory explicitly:

~~~ bash
$ completion install --shell zsh --directory ~/.zsh/completions --command falcon
~~~

## Installed Files

Installation writes a small adapter script and shared shell helpers.

For Bash and Zsh, shared helpers are installed in the completion directory:

~~~ text
completion.bash
completion.zsh
~~~

For Fish, shared helpers are installed as autoloaded functions:

~~~ text
~/.config/fish/functions/__completion_complete.fish
~/.config/fish/functions/__completion_register.fish
~/.config/fish/functions/__completion_register_default.fish
~/.config/fish/functions/__completion_resolve.fish
~/.config/fish/functions/__completion_supported.fish
~~~

Fish command adapters are installed into:

~~~ text
~/.config/fish/completions
~~~

Fish generic adapters are installed into:

~~~ text
~/.config/fish/conf.d
~~~

## Generating an Adapter

You can generate an adapter script without installing it:

~~~ bash
$ completion generate --shell zsh --command falcon
~~~

Omit `--command` to generate the generic adapter:

~~~ bash
$ completion generate --shell zsh
~~~

## Providing a Completion Executable

The completion executable should print completion candidates to standard output.

Commands built with `samovar` can use `Command.complete`:

~~~ ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/my/application"

My::Application.complete
~~~

Completion candidates use tab-separated fields:

~~~ text
type	value	description	key=value
~~~

The first three fields are always the completion type, value, and description. Additional fields are optional metadata entries.

## Testing

You can test the completion executable directly:

~~~ bash
$ completion-falcon ""
~~~

You can also generate an adapter and inspect it:

~~~ bash
$ completion generate --shell fish --command falcon
~~~
