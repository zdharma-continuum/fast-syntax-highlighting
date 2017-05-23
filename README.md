[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=D6XDCHDSBDSDG)

# Zshell Fast Syntax Highlighting

60 commits that optimized standard `zsh-syntax-highlighting` to the point that it can edit `10 kB`
functions with `zed`/`vared` (optimizations done in
[history-search-multi-word](https://github.com/zdharma/history-search-multi-word)). Also added:

1. Variable highlighting

    ![variables](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/parameter.png)

1. Colorizing of `${(a)parameter[...]}` inside strings (normally only `$parameter` is colorized)

    ![in-string](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/in_string.png)

1. Fixed colorizing of function definition, like `abc() { ... }` – `abc` will not be red

    ![function](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/function.png)

1. Fixed colorizing of complex conditions inside `[[`, like `[[ "$a" || "$b" ]]`

    ![complex conditions](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/cplx_cond.png)

1. Closing `]]` and `]` are highlighted (see above)

1. Paths from `$CDPATH` aren't colorized unless the command is `cd`

Performance differencies can be observed at Asciinema recording, where `10 kB` function is being edited:

[![asciicast](https://asciinema.org/a/112367.png)](https://asciinema.org/a/112367)


## Installation

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

Add `zplugin load zdharma/fast-syntax-highlighting` to your `.zshrc` file. Zplugin will handle
cloning the plugin for you automatically the next time you start zsh. To update
issue `zplugin update zdharma/fast-syntax-highlighting` (`update-all` can also be used).

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
