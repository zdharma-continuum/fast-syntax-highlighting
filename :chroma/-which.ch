# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
#
# Outputs (under prompt) result of query done with `which', `type -w',
# `whence -v', `whereis', `whatis'.
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
local __style __output __chars
integer __idx1 __idx2
local -a __results

# First call, i.e. command starts, i.e. "grep" token etc.
(( __first_call )) && {
    FAST_HIGHLIGHT[chroma-which-counter]=0
    FAST_HIGHLIGHT[chroma-which-counter-all]=1
    FAST_HIGHLIGHT[chroma-which-message]=""
    FAST_HIGHLIGHT[chroma-which-skip-two]=0
    __style=${FAST_THEME_NAME}command
    __output=""

# Following call (not first one).
} || {
    (( FAST_HIGHLIGHT[chroma-which-counter-all] += 1, __idx2 = FAST_HIGHLIGHT[chroma-which-counter-all] ))

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
        if [[ "$__wrd" = "-x" ]]; then
            FAST_HIGHLIGHT[chroma-which-skip-two]=1
        fi
    else
        # Count non-option tokens.
        if (( FAST_HIGHLIGHT[chroma-which-skip-two] )); then
            FAST_HIGHLIGHT[chroma-which-skip-two]=0
        else
            (( FAST_HIGHLIGHT[chroma-which-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-which-counter] ))
            if [[ "$__idx1" -eq 1 ]]; then
                __chars="{"
                __output="$(command which "$__wrd" 2>/dev/null)"
                FAST_HIGHLIGHT[chroma-which-message]+=$'\n'"command which: $__output"
                __output="$(builtin which "$__wrd" 2>/dev/null)"
                FAST_HIGHLIGHT[chroma-which-message]+=$'\n'"builtin which: ${${${${__output[1,100]}//$'\n'/;}//$'\t'/  }//$__chars;/$__chars}${__output[101,101]:+...}"
                __output="$(builtin type -w "$__wrd" 2>/dev/null)"
                FAST_HIGHLIGHT[chroma-which-message]+=$'\n'"type -w: $__output"
                __output="$(builtin whence -v "$__wrd" 2>/dev/null)"
                FAST_HIGHLIGHT[chroma-which-message]+=$'\n'"whence -v: $__output"
                __output="$(command whereis "$__wrd" 2>/dev/null)"
                FAST_HIGHLIGHT[chroma-which-message]+=$'\n'"whereis: $__output"
                __output="$(command whatis "$__wrd" 2>/dev/null)"
                __output="${${__output%%$'\n'*}//[[:blank:]]##/ }"
                FAST_HIGHLIGHT[chroma-which-message]+=$'\n'"whatis: $__output"
            fi
        fi
    fi

    if (( ${#${(z)BUFFER}} <= FAST_HIGHLIGHT[chroma-which-counter-all] )); then
        [[ -n "${FAST_HIGHLIGHT[chroma-which-message]}" ]] && zle -M "${FAST_HIGHLIGHT[chroma-which-message]#$'\n'}"
    fi
}

# Add region_highlight entry (via `reply' array).
#
# This is a common place of adding such entry, but any above code
# can do it itself and skip setting __style to disable this code.
[[ -n "$__style" ]] && (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style]}")

# We aren't passing-through (no return 1 occured), do obligatory things ourselves.
(( this_word = next_word ))
_start_pos=$_end_pos

return 0

# vim:ft=zsh:et:sw=4
