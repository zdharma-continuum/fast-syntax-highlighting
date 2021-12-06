# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
#
# Chroma for vim, shows last opened files under prompt.
#
# $1 - 0 or 1, denoting if it's first call to the chroma, or following one
#
# $2 - the current token, also accessible by $__arg from the above scope -
#      basically a private copy of $__arg; the token can be eg.: "grep"
#
# $3 - a private copy of $_start_pos, i.e. the position of the token in the
#      command line buffer, used to add region_highlight entry (see man),
#      because Zsh colorizes by *ranges* in command line buffer
#
# $4 - a private copy of $_end_pos from the above scope
#

(( next_word = 2 | 8192 ))

local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"
local __style __chars
integer __idx1 __idx2
local -a __viminfo

# First call, i.e. command starts, i.e. "grep" token etc.
(( __first_call )) && {
    (( ${+commands[vim]} )) && __style=${FAST_THEME_NAME}command || __style=${FAST_THEME_NAME}unknown-token

    { __viminfo=( ${(f)"$(<$HOME/.viminfo)"} ); } >> /dev/null
    __viminfo=( "${${(M)__viminfo[@]:#>*}[@]:t}" )
    __viminfo=( "${__viminfo[@]:#COMMIT_EDITMSG}" )
    zle -M "Last opened:"$'\n'"${(F)__viminfo[1,5]}"
} || {
    # Pass almost everything to big loop
    return 1
}

# Add region_highlight entry (via `reply' array).
#
# This is a common place of adding such entry, but any above
# code can do it itself (and it does, see other chromas) and
# skip setting __style to disable this code.
[[ -n "$__style" ]] && (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style]}")

# We aren't passing-through (no return 1 occured), do obligatory things ourselves.
(( this_word = next_word ))
_start_pos=$_end_pos

return 0

# vim:ft=zsh:et:sw=4
