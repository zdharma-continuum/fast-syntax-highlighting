# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
#
# Chroma function for `sh' shell. It colorizes string passed with -c option.
#
# $1 - 0 or 1, denoting if it's first call to the chroma, or following one
# $2 - the current token, also accessible by $__arg from the above scope -
#      basically a private copy of $__arg
# $3 - a private copy of $_start_pos, i.e. the position of the token in the
#      command line buffer, used to add region_highlight entry (see man),
#      because Zsh colorizes by *ranges* in command line buffer
# $4 - a private copy of $_end_pos from the above scope
#

(( next_word = 2 | 8192 ))

local __first_call=$1 __wrd=$2 __start_pos=$3 __end_pos=$4
local __style
integer __idx1 __idx2
local -a __lines_list

(( __first_call )) && {
    # Called for the first time - new command
    FAST_HIGHLIGHT[chrome-git-got-c]=0
    return 1
} || {
    # Following call, i.e. not the first one

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ $__arg_type = 3 ]] && return 2

    if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
        return 1
    fi

    __wrd=${${${(Q)__wrd}#[\"\']}%[\"\']}
    if [[ $__wrd = -* && $__wrd != -*c* ]]; then
        __style=${FAST_THEME_NAME}${${${__wrd:#--*}:+single-hyphen-option}:-double-hyphen-option}
    else
        if (( FAST_HIGHLIGHT[chrome-git-got-c] == 1 )); then
            for (( __idx1 = 1, __idx2 = 1; __idx2 <= __asize; ++ __idx1 )); do
                [[ ${__arg[__idx2]} = ${__wrd[__idx1]} ]] && break
                while [[ ${__arg[__idx2]} != ${__wrd[__idx1]} ]]; do
                    (( ++ __idx2 ))
                    (( __idx2 > __asize )) && { __idx2=0; break; }
                done
                (( __idx2 == 0 )) && break
                [[ ${__arg[__idx2]} = ${__wrd[__idx1]} ]] && break
            done

            FAST_HIGHLIGHT[chrome-git-got-c]=0
            (( _start_pos-__PBUFLEN >= 0 )) && \
                -fast-highlight-process "$PREBUFFER" "${__wrd}" "$(( __start_pos + __idx2 - 1 ))"
        elif [[ $__wrd = -*c* ]]; then
            FAST_HIGHLIGHT[chrome-git-got-c]=1
        else
            return 1
        fi
    fi
}

# Add region_highlight entry (via `reply' array)
[[ -n $__style ]] && (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style]}")

# We aren't passing-through, do obligatory things ourselves
(( this_word = next_word ))
_start_pos=$_end_pos

return 0

# vim:ft=zsh:et:sw=4
