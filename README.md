[![paypal](https://img.shields.io/badge/-Donate-yellow.svg?longCache=true&style=for-the-badge)](https://www.paypal.me/ZdharmaInitiative)
[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=D54B3S7C6HGME)
[![patreon](https://img.shields.io/badge/-Patreon-orange.svg?longCache=true&style=for-the-badge)](https://www.patreon.com/psprint)
<br/>New: You can request a feature when donating, even fancy or advanced ones get implemented this way. [There are
reports](DONATIONS.md) about what is being done with the money received.

# Fast Syntax Highlighting (F-Sy-H)

Feature rich syntax highlighting for Zsh.

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/highlight-much.png"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>

### Table of Contents

- [News](#news)
- [Installation](#installation)
- [Features](#features)
- [Performance](#performance)
- [IRC Channel](#irc-channel)

### Other Contents
- [License](https://github.com/zdharma/fast-syntax-highlighting/blob/master/LICENSE)
- [Changelog](https://github.com/zdharma/fast-syntax-highlighting/blob/master/CHANGELOG.md)
- [Theme Guide](https://github.com/zdharma/fast-syntax-highlighting/blob/master/THEME_GUIDE.md)
- [Chroma Guide](https://github.com/zdharma/fast-syntax-highlighting/blob/master/CHROMA_GUIDE.adoc)

# News

* 15-06-2019
  - A new architecture for defining the highlighting for **specific commands**: it now
    uses **abstract definitions** instead of **top-down, regular code**. The first effect
    is the highlighting for the `git` command it is now **maximally faithful**, it
    follows the `git` command almost completely.
    [Screencast](https://asciinema.org/a/253411)

# Installation

### Manual

Clone the Repository.

```zsh
git clone https://github.com/zdharma/fast-syntax-highlighting ~/path/to/fsh
```

And add the following to your `zshrc` file.
```zsh
source ~/path/to/fsh/fast-syntax-highlighting.plugin.zsh
```

### Zinit

Add the following to your `zshrc` file.

```zsh
zinit light zdharma/fast-syntax-highlighting
```

Here's an example of how to load the plugin together with a few other popular
ones with the use of
[Turbo](https://zdharma.org/zinit/wiki/INTRODUCTION/#turbo_mode_zsh_62_53),
i.e.: speeding up the Zsh startup by loading the plugin right after the first
prompt, in background:

```zsh
zinit wait lucid for \
 atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    zdharma/fast-syntax-highlighting \
 blockf \
    zsh-users/zsh-completions \
 atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions
```

### Antigen

Add the following to your `zshrc` file.

```zsh
antigen bundle zdharma/fast-syntax-highlighting
```

### Zgen

Add the following to your `.zshrc` file in the same place you're doing
your other `zgen load` calls in.

```zsh
zgen load zdharma/fast-syntax-highlighting
```


### Oh-My-Zsh

Clone the Repository.

```zsh
git clone https://github.com/zdharma/fast-syntax-highlighting.git \
  ~ZSH_CUSTOM/plugins/fast-syntax-highlighting
```

And add `fast-syntax-highlighting` to your plugin list.

# Features

### Themes

Switch themes via `fast-theme {theme-name}`.

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/theme.png"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>

Run `fast-theme -t {theme-name}` option to obtain the snippet above.

Run `fast-theme -l` to list available themes.

### Variables

Comparing to the project `zsh-users/zsh-syntax-highlighting` (the upper line):

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/parameter.png"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/in_string.png"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>

### Brackets

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/brackets.gif"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>

### Conditions

Comparing to the project `zsh-users/zsh-syntax-highlighting` (the upper line):

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/cplx_cond.png"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>

### Strings

Exact highlighting that recognizes quotings.

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/ideal-string.png"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>


### here-strings

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/herestring.png"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>

### `exec` descriptor-variables

Comparing to the project `zsh-users/zsh-syntax-highlighting` (the upper line):

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/execfd_cmp.png"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>

### for-loops and alternate syntax (brace `{`/`}` blocks)

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/for-loop-cmp.png"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>

### Function definitions

Comparing to the project `zsh-users/zsh-syntax-highlighting` (the upper 2 lines):

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/function.png"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>

### Recursive `eval` and `$( )` highlighting

Comparing to the project `zsh-users/zsh-syntax-highlighting` (the upper line):

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/eval_cmp.png"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>

### Chroma functions

Highlighting that is specific for a given command.

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/git_chroma.png"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>

The [chromas](https://github.com/zdharma/fast-syntax-highlighting/tree/master/chroma)
that are enabled by default can be found
[here](https://github.com/zdharma/fast-syntax-highlighting/blob/master/fast-highlight#L166).

### Math-mode highlighting

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/math.gif"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>

### Zcalc highlighting

<div style="width:100%;background-color:black;border:3px solid black;border-radius:6px;margin:5px 0;padding:2px 5px">
  <img
    src="https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/zcalc.png"
    alt="image could not be loaded"
    style="color:red;background-color:black;font-weight:bold"
  />
</div>

# Performance
Performance differences can be observed in this Asciinema recording, where a `10 kB` function is being edited.

<div style="width:100%;background-color:#121314;border:3px solid #121314;border-radius:6px;margin:5px 0;padding:2px 5px">
  <a href="https://asciinema.org/a/112367">
    <img src="https://asciinema.org/a/112367.png" alt="asciicast">
  </a>
</div>

## IRC Channel

Channel `#zinit@freenode` is a support place for all author's projects. Connect to:
[chat.freenode.net:6697](ircs://chat.freenode.net:6697/%23zinit) (SSL) or [chat.freenode.net:6667](irc://chat.freenode.net:6667/%23zinit)
 and join #zinit.

Following is a quick access via Webchat [![IRC](https://kiwiirc.com/buttons/chat.freenode.net/zinit.png)](https://kiwiirc.com/client/chat.freenode.net:+6697/#zinit)
