# Zshell Fast Syntax Highlighting

59 commits that optimized standard `zsh-syntax-highlighting` to the point that it can edit `10kB`
functions with `zed`/`vared`. Also added:

1. Variable highlighting
1. Colorizing of `${(a)parameter[...]}` inside strings (normally only `$parameter` is colorized)
1. Fixed colorizing of function definition, like `abc() { ... }` – `abc` will not be red
1. Fixed colorizing of complex conditions inside `[[`, like `[[ "$a" || "$b" ]]`
1. Closing `]]` and `]` are highlighted


