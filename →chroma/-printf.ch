# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
#
# Highlights the special sequences like "%s" in string passed to `printf'.
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
local __style __val
integer __idx1 __idx2

# First call, i.e. command starts, i.e. "grep" token etc.
(( __first_call )) && {
    FAST_HIGHLIGHT[chroma-printf-counter]=0
    FAST_HIGHLIGHT[chroma-printf-counter-all]=1
    FAST_HIGHLIGHT[chroma-printf-message]=""
    FAST_HIGHLIGHT[chroma-printf-skip-two]=0
    return 1
# Following call (not first one).
} || {
    if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
        return 1
    fi
    (( FAST_HIGHLIGHT[chroma-printf-counter-all] += 1, __idx2 = FAST_HIGHLIGHT[chroma-printf-counter-all] ))

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    if [[ "$__wrd" = -* ]]; then
        if [[ "$__wrd" = "-v" ]]; then
            FAST_HIGHLIGHT[chroma-printf-skip-two]=1
        fi
        return 1
    else
        # Count non-option tokens.
        if (( FAST_HIGHLIGHT[chroma-printf-skip-two] )); then
            FAST_HIGHLIGHT[chroma-printf-skip-two]=0
            return 1
        else
            (( FAST_HIGHLIGHT[chroma-printf-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-printf-counter] ))
            if [[ "$__idx1" -eq 1 ]]; then
                [[ "$__wrd" = \"* ]] && (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) \
                    && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}double-quoted-argument]}")
                [[ "$__wrd" = \'* ]] && (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) \
                    && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}single-quoted-argument]}")
                FSH_LIST=() # use fsh_sy_h_append function to write to FSH_LIST
                : "${__wrd//(#m)\%[\#\+\ 0-]#[0-9]#([.][0-9]#)(#c0,1)[diouxXfFeEgGaAcsb]/$(( fsh_sy_h_append($MBEGIN, $MEND) ))}";
                for __val in "${FSH_LIST[@]}" ; do
                    __idx1=$(( __start_pos + ${__val%%;;*} ))
                    __idx2=__idx1+${__val##*;;}-${__val%%;;*}+1
                    (( __start=__idx1-${#PREBUFFER}, __end=__idx2-${#PREBUFFER}-1, __start >= 0 )) && \
                        reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}mathnum]}")
                done
            else
                return 1
            fi
        fi
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
