# Chroma Guide

## Keywords
- `chroma` - a shorthand for `chroma function`,
- `big loop` - main highlighting code, a loop over tokens and at least 2 large structular constructs (big `if` and `case`);
  it is advanced, e.g. parses `case` statement, here-string,
- `chroma function` - a plugin function that is called when specified command occurs (e.g. when user enters `git`)
  without requiring any action from the `big loop`,
- `token` - result of splitting whole command line (i.e. BUFFER) into bits separated by spaces, called tokens.

## Overall Functioning 

1. Big loop is working – token by token processes command line, changes states (e.g. enters state "inside case
   statement") and in the end decides on color of the token currently processed.

2. Big loop occurs a command that has a chroma, e.g. `git`.

3. Big loop enters "chroma" state, calls associated chroma.

4. Chroma takes care of "chroma" state, ensures will be set also for next token.

5. "chroma" state is active, so all following tokens are routed to the chroma.

6. When finished processing any single token by the associated chroma, it returs 0
   (shell-truth) to request no further processing by the big loop.

7. It can also return 1 so that single, current token will be passed into big-loop
   for processing.

## Chroma Function Arguments

- $1 - 0 or 1, denoting if it's the first call to the chroma, or a following one,

- $2 - the current token, also accessible by $__arg from the upper scope -
       basically a private copy of $__arg; the token can be eg.: "grep",

- $3 - a private copy of $_start_pos, i.e. the position of the token in the
       command line buffer, used to add region_highlight entry (see man),
       because Zsh colorizes by *ranges* applied onto command line buffer (e.g.
       `from-10 to-13 fg=red`),

- $4 - a private copy of $_end_pos from the upper scope; denotes where token
       ends (at which index in the string, the command line).


