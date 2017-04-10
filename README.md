# Zshell Fast Syntax Highlighting

59 commits that optimized standard `zsh-syntax-highlighting` to the point that it can edit `10kB`
functions with `zed`/`vared`. Also added:

1. Variable highlighting

    ![variables](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/parameter.png)

1. Colorizing of `${(a)parameter[...]}` inside strings (normally only `$parameter` is colorized)

    ![in-string](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/in_string.png)

1. Fixed colorizing of function definition, like `abc() { ... }` – `abc` will not be red

    ![function](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/function.png)

1. Fixed colorizing of complex conditions inside `[[`, like `[[ "$a" || "$b" ]]`

    ![complex conditions](https://raw.githubusercontent.com/zdharma/fast-syntax-highlighting/master/images/cplx_cond.png)

1. Closing `]]` and `]` are highlighted (see above)

