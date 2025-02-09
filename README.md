<h1 align="center">
  ⚡ Zig Version Manager (<code>zvm</code>)
</h1>
<div align="center">⚡ Fast and simple zig version manager</div>
<br><br>
zvm is a command-line tool that allows you to easily install, manage, and switch between multiple versions of Zig.

## Features

- List available Zig versions.
- Install specific Zig versions.
- Switch between installed Zig versions.
- Set a default Zig version.


## Install

To install zvm with Homebrew, aka. `brew`, run the following commands:

```bash
brew tap hendriknielaender/zvm
brew install zvm
```

Now add this line to your `~/.bashrc`, `~/.profile`, or `~/.zshrc` file.

```bash
export PATH="$HOME/.zvm/current:$PATH"
```

## Usage
```bash
zvm list                # List all available Zig versions
zvm install <version>   # Install a specified Zig version
zvm use <version>       # Switch to a specified Zig version for the current session
zvm default <version>   # Set a specified version as the default
zvm current             # Display the currently active Zig version
zvm --help              # Displays help information
zvm --version           # Display zvm version
```

## Contributing
Contributions, issues, and feature requests are welcome!
