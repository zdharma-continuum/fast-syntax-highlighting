# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
#
# Chroma function for command `git'. It colorizes the part of command
# line that holds `git' invocation.
#

(( next_word = 2 | BIT_chroma ))

local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"
local __style
integer __idx

(( __first_call )) && {
    FAST_HIGHLIGHT[chroma-git-counter]=1
    FAST_HIGHLIGHT[chroma-git-got-subcommand]=0
    __style=${FAST_THEME_NAME}command
    (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style]}")
} || {
    # Increase position counter, save it in handy parameter __idx
    (( FAST_HIGHLIGHT[chroma-git-counter] += 1, __idx = FAST_HIGHLIGHT[chroma-git-counter] ))

    # Didn't get subcommand yet?
    if (( FAST_HIGHLIGHT[chroma-git-got-subcommand] == 0 )); then
        [[ "$__wrd" = -* ]] && return 1 # pass-through options
        FAST_HIGHLIGHT[chroma-git-got-subcommand]=1
        __style=${FAST_THEME_NAME}reserved-word
        (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style]}")
    fi
}

# We aren't passing-through, do obligatory things ourselves
(( this_word = next_word ))
_start_pos=$_end_pos

return 0

# vim:ft=zsh:et:sw=4
