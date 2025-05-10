# 👼 HolyUtils: Unix Commands in HolyC
***(Just a meme)***

A collection of recreated Unix commands implemented in HolyC. This project aims to provide familiar Unix utilities for TempleOS environments.

## About

This project is inspired by [uutils](https://github.com/uutils/coreutils), a cross-platform reimplementation of GNU coreutils in Rust. HolyUtils aims to provide similar functionality but in HolyC for TempleOS and TempleOS-like environments.

### Disclaimer

HolyUtils is not affiliated with, endorsed by, or in any way officially connected with GNU, uutils, or any of their subsidiaries or affiliates. The name "HolyUtils" is used for descriptive purposes only. All Unix command names and their functionality are recreated independently for TempleOS environments.

## Building

### Prerequisites

- HolyC compiler (hcc)
- Make
- TempleOS or compatible environment

### Build Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/HolyUtils.git
   cd HolyUtils
   ```

2. Build all utilities:
   ```bash
   make
   ```
   This will create a `dist/` directory containing all compiled utilities.

3. Optional: Install utilities system-wide (requires root):
   ```bash
   sudo make install
   ```

### Makefile Targets

- `make` or `make all`: Build all utilities in the `dist/` directory
- `make clean`: Remove the `dist/` directory and all build artifacts
- `make install`: Install utilities to `/usr/local/bin/` (requires root)
- `make uninstall`: Remove utilities from `/usr/local/bin/` (requires root)

### Building Individual Utilities

To build a specific utility, you can use:
```bash
make dist/utility_name
```
For example:
```bash
make dist/ls
```

## Available Commands

### alias

The `alias` command allows users to create command aliases, similar to the Unix equivalent.

#### Features
- Create, update, and remove command aliases
- List all defined aliases
- Lookup specific alias values
- Help information with usage instructions

#### Usage
```
alias [name[='value']] [-help]
alias -r name
```

- With no arguments, all aliases are listed
- With just a name, the value of that alias is displayed
- With name='value', the alias is set to that value
- `-r name` removes the specified alias
- `-help` displays usage information

### ls

The `ls` command lists directory contents.

#### Features
- List files and directories
- Color-coded output (directories in different color)
- Support for long format listing (-l)
- Show hidden files (-a)
- Recursive directory listing (-R)
- Human-readable file sizes (-h)

#### Usage
```
ls [OPTION]... [FILE]...
```

### cat

The `cat` command concatenates and displays file contents.

#### Features
- Display file contents
- Number output lines (-n)
- Display line ends with $ (-E)
- Display TAB characters as ^I (-T)
- Squeeze multiple blank lines into one (-s)

#### Usage
```
cat [OPTION]... [FILE]...
```

### mkdir

The `mkdir` command creates directories.

#### Features
- Create one or more directories
- Create parent directories as needed (-p)
- Verbose output (-v)

#### Usage
```
mkdir [OPTION]... DIRECTORY...
```

### rm

The `rm` command removes files and directories.

#### Features
- Remove files
- Remove directories recursively (-r)
- Force removal without prompting (-f)
- Verbose output (-v)

#### Usage
```
rm [OPTION]... FILE...
```

### cp

The `cp` command copies files and directories.

#### Features
- Copy files to a destination
- Copy directories recursively (-r)
- Force overwrite of existing files (-f)
- Preserve file attributes when possible (-p)
- Verbose output (-v)

#### Usage
```
cp [OPTION]... SOURCE DEST
cp [OPTION]... SOURCE... DIRECTORY
```

### grep

The `grep` command searches for patterns in files.

#### Features
- Search files for text patterns
- Ignore case distinctions (-i)
- Show line numbers (-n)
- Display only count of matching lines (-c)
- Select non-matching lines (-v)
- Recursively search directories (-r)

#### Usage
```
grep [OPTION]... PATTERN [FILE]...
```

### mv

The `mv` command moves or renames files and directories.

#### Features
- Move files and directories
- Rename files and directories
- Force overwrite of existing files (-f)
- Verbose output (-v)

#### Usage
```
mv [OPTION]... SOURCE DEST
mv [OPTION]... SOURCE... DIRECTORY
```

### echo

The `echo` command displays a line of text.

#### Features
- Display text with or without newline (-n)
- Enable interpretation of backslash escapes (-e)
- Disable interpretation of backslash escapes (-E)
- Support for various escape sequences (\n, \t, \r, etc.)
- Support for octal and hexadecimal escape sequences

#### Usage
```
echo [OPTION]... [STRING]...
```

### printf

The `printf` command formats and prints data.

#### Features
- Format string support with various specifiers
- Support for width and precision
- Left-justification (-)
- Sign display (+)
- Space padding
- Zero padding (0)
- Alternate form (#)
- Support for integers, strings, characters, and pointers

#### Usage
```
printf FORMAT [ARGUMENT]...
```

### wc

The `wc` command counts lines, words, and bytes in files.

#### Features
- Count lines (-l)
- Count words (-w)
- Count bytes (-c)
- Print maximum line length (-L)
- Support for multiple files
- Print totals for multiple files

#### Usage
```
wc [OPTION]... [FILE]...
```

### head

The `head` command outputs the first part of files.

#### Features
- Output first N lines (-n)
- Output first N bytes (-c)
- Never print headers (-q)
- Always print headers (-v)
- Support for multiple files
- Read from stdin if no files specified

#### Usage
```
head [OPTION]... [FILE]...
```

### tail

The `tail` command outputs the last part of files.

#### Features
- Output last N lines (-n)
- Output last N bytes (-c)
- Follow file changes (-f)
- Never print headers (-q)
- Always print headers (-v)
- Support for multiple files
- Read from stdin if no files specified

#### Usage
```
tail [OPTION]... [FILE]...
```

### angshell

The `angshell` is a bash-like shell implementation in HolyC.

#### Features
- Command history with up/down arrow navigation
- Built-in commands (cd, pwd, exit, history)
- External command execution
- Command line editing
- Quoted string support
- Directory navigation

#### Built-in Commands
- `cd [DIR]` - Change directory (defaults to home directory)
- `pwd` - Print working directory
- `exit` - Exit the shell
- `history` - Display command history

#### Usage
```
angshell
```

## Implementation Details

Each command is implemented as a standalone HolyC file that can be included and used independently. Commands store their state in memory and are not persisted between sessions by default.

## Building and Running

The command files can be compiled and run in the TempleOS environment or any compatible HolyC compiler.

## Future Commands

Additional Unix commands may be added to this collection over time. 
