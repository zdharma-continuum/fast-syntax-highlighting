# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
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
local __style __chars __val __style2
integer __idx1 __idx2

# First call, i.e. command starts, i.e. "grep" token etc.
(( __first_call )) && {
    FAST_HIGHLIGHT[chroma-awk-counter]=0
    FAST_HIGHLIGHT[chroma-awk-f-seen]=0
    return 1
} || {
    # Following call, i.e. not the first one.

    if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
        return 1
    fi

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    if [[ "$__wrd" = -* ]]; then
        # Detected option, add style for it.
        [[ "$__wrd" = --* ]] && __style=${FAST_THEME_NAME}double-hyphen-option || \
                                __style=${FAST_THEME_NAME}single-hyphen-option
        [[ "$__wrd" = "-f" ]] && FAST_HIGHLIGHT[chroma-awk-f-seen]=1
    else
        # Count non-option tokens.
        (( FAST_HIGHLIGHT[chroma-awk-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-awk-counter] ))

        # First non-option token is the pattern (regex), we will
        # highlight it.
        if (( FAST_HIGHLIGHT[chroma-awk-counter] == 1 && FAST_HIGHLIGHT[chroma-awk-f-seen] == 0 )); then
            if print -r -- "${(Q)__wrd}" | gawk --source 'BEGIN { exit } END { exit 0 }' -f - >/dev/null 2>&1; then
                __style2="${FAST_THEME_NAME}subtle-bg"
            else
                __style2="${FAST_THEME_NAME}incorrect-subtle"
            fi

            (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && \
                reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style2]}")
            
            # Highlight keywords
            FSH_LIST=()
            : "${__wrd//(#m)(BEGIN|END|FIELDWIDTHS|RS|ARGC|ARGV|ENVIRON|NF|NR|IGNORECASE|FILENAME|if|then|else|while|toupper|tolower|function|print|sub)/$(( fsh_sy_h_append($MBEGIN, $MEND) ))}";
            for __val in "${FSH_LIST[@]}" ; do
                [[ ${__wrd[${__val%%;;*}]} = [a-zA-Z0-9_] || ${__wrd[${__val##*;;}+1]} = [a-zA-Z0-9_] ]] && continue
                __idx1=$(( __start_pos + ${__val%%;;*} ))
                __idx2=__idx1+${__val##*;;}-${__val%%;;*}+1
                (( __start=__idx1-${#PREBUFFER}, __end=__idx2-${#PREBUFFER}-1, __start >= 0 )) && \
                    reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}reserved-word]},${FAST_HIGHLIGHT_STYLES[$__style2]}")
            done

            # Highlight regex characters
            __chars="*+\\)(\{\}[]^"
            __idx1=__start_pos
            __idx2=__start_pos
            while [[ "$__wrd" = (#b)[^$__chars]#([\\][\\])#((+|\*|\[|\]|\)|\(|\^|\}|\{)|[\\](+|\*|\[|\]|\)|\(|\^|\{|\}))(*) ]]; do
                if [[ -n "${match[3]}" ]]; then
                    __idx1+=${mbegin[3]}-1
                    __idx2=__idx1+${mend[3]}-${mbegin[3]}+1
                    (( __start=__idx1-${#PREBUFFER}, __end=__idx2-${#PREBUFFER}, __start >= 0 )) && \
                        reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}mathnum]},${FAST_HIGHLIGHT_STYLES[$__style2]}")
                    __idx1=__idx2
                else
                    __idx1+=${mbegin[5]}-1
                fi
                __wrd="${match[5]}"
            done
        elif (( FAST_HIGHLIGHT[chroma-awk-counter] >= 2 || FAST_HIGHLIGHT[chroma-awk-f-seen] == 1 )); then
            FAST_HIGHLIGHT[chroma-awk-f-seen]=0
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
