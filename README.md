[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=H4GZAACT2MQ3W)

```
 _____         _       ____              _                  _   _ _       _     _ _       _     _   _
|  ___|_ _ ___| |_    / ___| _   _ _ __ | |_ __ ___  __    | | | (_) __ _| |__ | (_) __ _| |__ | |_(_)_ __   __ _
| |_ / _` / __| __|___\___ \| | | | '_ \| __/ _` \ \/ /____| |_| | |/ _` | '_ \| | |/ _` | '_ \| __| | '_ \ / _` |
|  _| (_| \__ \ ||_____|__) | |_| | | | | || (_| |>  <_____|  _  | | (_| | | | | | | (_| | | | | |_| | | | | (_| |
|_|  \__,_|___/\__|   |____/ \__, |_| |_|\__\__,_/_/\_\    |_| |_|_|\__, |_| |_|_|_|\__, |_| |_|\__|_|_| |_|\__, |
                             |___/                                  |___/           |___/                   |___/
```

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Zshell Fast Syntax Highlighting](#zshell-fast-syntax-highlighting)
- [Updates (2018)](#updates-2018)
- [Installation](#installation)
    - [Zplugin](#zplugin)
    - [Antigen](#antigen)
    - [Oh-My-Zsh](#oh-my-zsh)
    - [Zgen](#zgen)
- [Customization](#customization)
  - [Secondary Theme](#secondary-theme)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Zshell Fast Syntax Highlighting

60 commits that optimized standard `zsh-syntax-highlighting` to the point that it can edit `10 kB`
functions with `zed`/`vared` (optimizations done in
[history-search-multi-word](https://github.com/zdharma/history-search-multi-word)).

Fast-Syntax-Highlighting has great granularity and a few crucial extensions, compare:

![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/highlight-much.png)

to regular:

![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/highlight-less.png)

It can be seen, FSH highlights `-c` contents (thanks to chroma-architecture), `(( ))` contents (thanks to
math-mode highlighting – yes it works in `zcalc`), `eval` contents (thanks to recursive highlighting), etc.

Other extensions:

1. Variable highlighting

    ![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/parameter.png)

2. Colorizing of `${(a)parameter[...]}` inside strings (normally only `$parameter` is colorized)

    ![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/in_string.png)

3. Fixed colorizing of function definition, like `abc() { ... }` – `abc` will not be red

    ![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/function.png)

4. Fixed colorizing of complex conditions inside `[[`, like `[[ "$a" || "$b" ]]`

    ![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/cplx_cond.png)

5. Closing `]]` and `]` are highlighted (see above)

6. Paths from `$CDPATH` aren't colorized unless the command is `cd`

7. Five 256-color themes, switched with `fast-theme {theme-name}` (also try `-t` option to obtain the below snippet).
   also note the ideal brackets highlighting in the `sidx=...`, `eidx=...` lines:

    ![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/theme.png)

8. Correct highlighting of descriptor-variables passed to `exec`:

    ![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/execfd_cmp.png)

9. Recursive `eval` and `$( )` highlighting, with secondary theme (two themes active at the same time!):

    ![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/eval_cmp.png)

10. New architecture – **chroma functions** – highlighting that is **specific** for given command. There
    are two chromas currently, for `git` (verifies correct remote & branch, also see below)  and `grep`
    (highlights regular expression):

    ![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/git_chroma.png)

11. Ideal highlighting of brackets (pairing, etc.) – no quoting can disturb the result:

    ![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/brackets.gif)

    Add `FAST_HIGHLIGHT[use_brackets]=1` to `.zshrc` to enable (**2018-07-31**: not needed anymore, this highlighting is active by default and can be disabled).

12. Highlighting of here-string:

    ![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/herestring.png)

Performance differencies can be observed at Asciinema recording, where `10 kB` function is being edited:

[![asciicast](https://asciinema.org/a/112367.png)](https://asciinema.org/a/112367)

# Updates (2018)
**2018-08-02**

Global aliases are now supported:

![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/global-alias.png)

**2018-08-01**

Hint – how to customize styles when using Zplugin and turbo mode:

```zsh
zplugin ice wait"1" atload"set_fast_theme"
zplugin light zdharma/fast-syntax-highlighting

set_fast_theme() {
    FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}paired-bracket]='bg=blue'
    FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}bracket-level-1]='fg=red,bold'
    FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}bracket-level-2]='fg=magenta,bold'
    FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}bracket-level-3]='fg=cyan,bold'
}
```

If you have set theme before an update of styles (e.g. recent addition of bracket highlighting)
then please repeat `fast-theme {theme}` call to regenerate theme files.

**2018-07-30**

Ideal highlighting of brackets (pairing, etc.) – no quoting can disturb the result:

![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/brackets.gif)

`FAST_HIGHLIGHT[use_brackets]=1` to enable this feature (**2018-07-31**: not needed anymore, this highlighting is active by default).

**2018-07-21**

Chroma architecture now supports aliases. You can have `alias mygit="git commit"` and when `mygit`
will be invoked everything will work as expected (Git chroma will be ran).

**2018-07-11**

There were problems with Ctrl-C not working when using FSH. After many days I've found a fix
for this, it's pushed to master.

Second, asynchronous path checking (useful on e.g. slow network drives, or when there are many files in directory)
is now optional. Set `FAST_HIGHLIGHT[use_async]=1` to enable it. This saves some users from Zshell crashes
– there's an unknown bug in Zsh.

**2018-06-09**

New chroma functions: `awk`, `make`, `perl`, `vim`. Checkout the [video](https://asciinema.org/a/186234),
it shows functionality of `awk` – compiling of code and NOT running it. Perl can do this too:
[video](https://asciinema.org/a/186098).

**2018-06-06**

FSH gained a new architecture – "chroma functions". They are similar to "completion functions", i.e. they
are defined **per-command**, but instead of completing that command, they colorize it. Two chroma exist,
for `Git` ([video](https://asciinema.org/a/185707), [video](https://asciinema.org/a/185811)) and for `grep`
([video](https://asciinema.org/a/185942)). Checkout
[example chroma](https://github.com/zdharma/fast-syntax-highlighting/blob/master/chroma/-example.ch) if you
would like to highlight a command.

![sshot](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/git_chroma.png)

**2018-06-01**

Highlighting of command substitution (i.e. `$(...)`) with alternate theme – two themes at once! It was just white before:

![sshot](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/cmdsubst.png)

To select which theme to use for `$(...)` set the key `secondary=` in [theme ini file](https://github.com/zdharma/fast-syntax-highlighting/blob/master/themes/free.ini#L7).
All shipped themes have this key set (only the `default` theme doesn't use second theme).

Also added correct highlighting of descriptor-variables passed to `exec`:

![sshot](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/execfd.png)

**2018-05-30**

For-loop is highlighted, it has separate settings in [theme file](https://github.com/zdharma/fast-syntax-highlighting/blob/master/themes/free.ini).

![sshot](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/for-loop.png)

**2018-05-27**

Added support for 256-color themes. There are six themes shipped with FSH. The command to
switch theme is `fast-theme {theme-name}`, it has a completion which lists available themes
and options. Checkout [asciinema recording](https://asciinema.org/a/183814) that presents
the themes.

**2018-05-25**

Hash holding paths that shouldn't be grepped (globbed) – blacklist for slow disks, mounts, etc.:

```zsh
typeset -gA FAST_BLIST_PATTERNS
FAST_BLIST_PATTERNS[/mount/nfs1/*]=1
FAST_BLIST_PATTERNS[/mount/disk2/*]=1
```

**2018-05-23**

Assign colorizing now spans to variables defined by `typeset`, `export`, `local`, etc.:

![sshot](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/typeset.png)

Also, `zcalc` has a separate math mode and specialized highlighting – no more light-red colors because of
treating `zcalc` like a regular command-line:

![sshot](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/zcalc.png)

**2018-05-22**

Array assignments were still boring, so I throwed in bracked colorizing:

![sshot](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/array-assign.png)

**2018-05-22**<a name="assign-update"></a>

Assignments are no more one-colour default-white. When used in assignment, highlighted are:

- variables (outside strings),
- strings (double-quoted and single-quoted),
- math-mode (`val=$(( ... ))`).

![sshot](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/assign.png)

**2018-01-06**

Math mode is highlighted – expressions `(( ... ))` and `$(( ... ))`. Empty variables are colorized as red.
There are 3 style names (fields of
[FAST_HIGHLIGHT_STYLES](https://github.com/zdharma/fast-syntax-highlighting/blob/master/fast-highlight#L34)
hash) for math-variable, number and empty variable (error): `mathvar`, `mathnum`, `matherr`. You can set
them (like the animation below shows) to change colors.

![animation](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/math.gif)

# Installation

**The plugin is "standalone"**, which means that only sourcing it is needed. So to
install, unpack `fast-syntax-highlighting` somewhere and add

```zsh
source {where-fsh-is}/fast-syntax-highlighting.plugin.zsh
```

to `zshrc`.

If using a plugin manager, then `Zplugin` is recommended, but you can use any
other too, and also install with `Oh My Zsh` (by copying directory to
`~/.oh-my-zsh/custom/plugins`).

### [Zplugin](https://github.com/psprint/zplugin)

Add `zplugin light zdharma/fast-syntax-highlighting` to your `.zshrc` file. Zplugin will handle
cloning the plugin for you automatically the next time you start zsh. To update
issue `zplugin update zdharma/fast-syntax-highlighting` (`update --all` can also be used).

Zplugin can load f-sy-h in turbo-mode, i.e. after prompt, to speed-up `.zshrc` processing:

```zsh
zplugin ice wait"1" # 1 second after prompt
zplugin light zdharma/fast-syntax-highlighting
```

### Antigen

Add `antigen bundle zdharma/fast-syntax-highlighting` to your `.zshrc` file. Antigen will handle
cloning the plugin for you automatically the next time you start zsh.

### Oh-My-Zsh

1. `cd ~/.oh-my-zsh/custom/plugins`
2. `git clone https://github.com/zdharma/fast-syntax-highlighting.git`
3. Add `fast-syntax-highlighting` to your plugin list

### Zgen

Add `zgen load zdharma/fast-syntax-highlighting` to your `.zshrc` file in the same place you're doing
your other `zgen load` calls in.

# Customization

`fast-theme` tool is used to select a theme. There are 6 shipped themes, they can be listed with `fast-theme -l`.
Themes are basic [INI files](https://github.com/zdharma/fast-syntax-highlighting/tree/master/themes) where each
key is a *style*.
Besides shipped themes, user can point this tool to any other theme, by simple `fast-theme ~/mytheme.ini`. To
obtain template to work on when creating own theme, issue `fast-theme --copy-shipped-theme {theme-name}`.

To alter just a few styles and not create a whole new theme, use **overlay**. What is overlay? It is in the same
format as full theme, but can have only a few styles defined, and these styles will overwrite styles in main-theme.
Example overlay file:

```ini
; overlay.ini
[base]
commandseparator = yellow,bold
comment          = 17

[command-point]
function       = green
command        = 180
```

File name `overlay.ini` is treated specially.

When specifing path, following short-hands can be used:

```
XDG:    = ~/.config/fsh (respects $XDG_CONFIG_HOME env var)
LOCAL:  = /usr/local/share/fsh/
HOME:   = ~/.fsh/
OPT:    = /opt/local/share/fsh/
```

So for example, issue `fast-theme XDG:overlay` to load `~/.config/fsh/overlay.ini` as overlay. The `.ini`
extension is optional.

## Secondary Theme

Each theme has key `secondary`, e.g. for theme `free`:

```ini
; free.ini
[base]
default          = none
unknown-token    = red,bold
; ...
; ...
; ...
secondary        = zdharma
```

Secondary theme (`zdharma` in the example) will be used for highlighting of argument for `eval`
and of `$( ... )` interior (i.e. of interior of command substitution). Basically, recursive
highlighting uses alternate theme to make the highlighted code distinct:

![sshot](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/cmdsubst.png)

In the above screen-shot the interior of `$( ... )` uses different colors than the rest of the
code. Example for `eval`:

![image](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/eval_cmp.png)

First line doesn't use recursive highlighting, highlights `eval` argument as regular string.
Second line switches theme to `zdharma` and does full recursive highlighting of eval argument.
