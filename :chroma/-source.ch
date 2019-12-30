# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
#
# Chroma for `source' builtin - verifies if file to be sourced compiles
# correctly.
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
local __style __chars __home=${XDG_CACHE_HOME:-$HOME/.cache}/fsh
integer __idx1 __idx2

# First call, i.e. command starts, i.e. "grep" token etc.
(( __first_call )) && {
    FAST_HIGHLIGHT[chroma-src-counter]=0
    __style=${FAST_THEME_NAME}builtin

} || {
    # Following call, i.e. not the first one.

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
        return 1
    fi

    if [[ "$__wrd" = -* ]]; then
        # Detected option, add style for it.
        [[ "$__wrd" = --* ]] && __style=${FAST_THEME_NAME}double-hyphen-option || \
                                __style=${FAST_THEME_NAME}single-hyphen-option
    else
        # Count non-option tokens.
        (( FAST_HIGHLIGHT[chroma-src-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-src-counter] ))

        if (( FAST_HIGHLIGHT[chroma-src-counter] == 1 )); then
            command mkdir -p "$__home"
            command cp -f "${__wrd}" "$__home" 2>/dev/null && {
                zcompile "$__home"/"${__wrd:t}" 2>/dev/null 1>&2 && __style=${FAST_THEME_NAME}correct-subtle || __style=${FAST_THEME_NAME}incorrect-subtle
            }
        elif (( FAST_HIGHLIGHT[chroma-src-counter] == 2 )); then
            # Handle paths, etc. normally - just pass-through to the big
            # highlighter (the main FSH highlighter, used before chromas).
            return 1
        fi
    fi
}

# Add region_highlight entry (via `reply' array).
#
# This is a common place of adding such entry, but any above
# code can do it itself (and it does) and skip setting __style
# to disable this code.
[[ -n "$__style" ]] && (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style]}")

# We aren't passing-through (no return 1 occured), do obligatory things ourselves.
(( this_word = next_word ))
_start_pos=$_end_pos

return 0

# vim:ft=zsh:et:sw=4
