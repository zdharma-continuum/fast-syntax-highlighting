# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
#
# Tracks autoload command - highlights function names if they exist somewhere
# in $fpath. Also warns that the autoloaded function is already defined.
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
local -a __results __deserialized __noshsplit

# First call, i.e. command starts, i.e. "grep" token etc.
(( __first_call )) && {
    FAST_HIGHLIGHT[chroma-autoload-counter]=0
    FAST_HIGHLIGHT[chroma-autoload-counter-all]=1
    FAST_HIGHLIGHT[chroma-autoload-message]=""
    #FAST_HIGHLIGHT[chroma-autoload-message-shown]=""
    [[ -z ${FAST_HIGHLIGHT[chroma-autoload-message-shown-at]} ]] && FAST_HIGHLIGHT[chroma-autoload-message-shown-at]=0
    FAST_HIGHLIGHT[chroma-autoload-elements]=""
    __style=${FAST_THEME_NAME}command

} || {
    if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
        return 1
    fi
    (( FAST_HIGHLIGHT[chroma-autoload-counter-all] += 1, __idx2 = FAST_HIGHLIGHT[chroma-autoload-counter-all] ))

    # Following call, i.e. not the first one.

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    if [[ "$__wrd" = [-+]* ]]; then
        # Detected option, add style for it.
        [[ "$__wrd" = --* ]] && __style=${FAST_THEME_NAME}double-hyphen-option || \
                                __style=${FAST_THEME_NAME}single-hyphen-option
    else
        # Count non-option tokens.
        (( FAST_HIGHLIGHT[chroma-autoload-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-autoload-counter] ))

        if [[ $__wrd != (\$|\"\$)* && $__wrd != (/|\"/|\'/)* && $__wrd != \`* ]]; then
            __results=( ${^fpath}/$__wrd(N) )
            __deserialized=( "${(Q@)${(z@)FAST_HIGHLIGHT[chroma-fpath_peq-elements]}}" )
            __results+=( ${^__deserialized}/$__wrd(N) )
            [[ "${#__results}" -gt 0 ]] && {
                __style=${FAST_THEME_NAME}correct-subtle
                __deserialized=( "${(Q@)${(z@)FAST_HIGHLIGHT[chroma-autoload-elements]}}" )
                [[ -z "${__deserialized[1]}" && ${#__deserialized} -eq 1 ]] && __deserialized=()
                # Cannot use ${abc:+"$abc"} trick with ${~...}, so handle most
                # cases of the possible shwordsplit through an additional array
                __noshsplit=( ${~__wrd} )
                __deserialized+=( "${(j: :)__noshsplit}" )
                FAST_HIGHLIGHT[chroma-autoload-elements]="${(j: :)${(q@)__deserialized}}"
                # Make the function defined for big-loop's *main-type mechanism
                __fast_highlight_main__command_type_cache[${(j: :)__noshsplit}]="function"
            } || __style=${FAST_THEME_NAME}incorrect-subtle
        fi

        if (( ${+functions[${(Q)__wrd}]} )); then
            FAST_HIGHLIGHT[chroma-autoload-message]+="Warning: Function ${(Q)__wrd} already defined (e.g. loaded)"$'\n'
        fi
    fi

    # Display only when processing last autoload argument
    if (( ${#${(z)BUFFER}} == FAST_HIGHLIGHT[chroma-autoload-counter-all] )); then
        # Display only if already shown message differs or when it timeouts
        if [[ ${FAST_HIGHLIGHT[chroma-autoload-message]} != ${FAST_HIGHLIGHT[chroma-autoload-message-shown]} ||
                $(( EPOCHSECONDS - FAST_HIGHLIGHT[chroma-autoload-message-shown-at] )) -gt 7
        ]]; then
            FAST_HIGHLIGHT[chroma-autoload-message-shown]=${FAST_HIGHLIGHT[chroma-autoload-message]}
            FAST_HIGHLIGHT[chroma-autoload-message-shown-at]=$EPOCHSECONDS
            zle -M "${FAST_HIGHLIGHT[chroma-autoload-message]}"
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
