# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
#
# This chroma does a narrow, obscure but prestigious parsing of fpath+=( elem1
# elem2 ... ) construct to provide *the* *future* contents of $fpath to
# -autoload.ch, so that it can detect functions in those provided directories
# `elem1', `elem2', etc. and highlight the functions with `correct-subtle'
# instead of `incorrect-subtle'. Basically all thit is for command-lines like:
#
# % fpath+=( `pwd` ); autoload my-fun-from-PWD

# Keep chroma-takever state meaning: until ; or similar (see $__arg_type below)
# The 8192 sum takes care that the next token will be routed to this chroma
(( next_word = 2 | 8192 ))

local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"
local -a deserialized

(( __first_call )) && {
    case $__wrd in
        (fpath=\()
            FAST_HIGHLIGHT[fpath_peq_mode]=1
            ;;
        (fpath+=\()
            FAST_HIGHLIGHT[fpath_peq_mode]=2
            ;;
        (FPATH=)
            FAST_HIGHLIGHT[fpath_peq_mode]=4
            ;;
        (FPATH+=)
            FAST_HIGHLIGHT[fpath_peq_mode]=8
            ;;
    esac
    if (( FAST_HIGHLIGHT[fpath_peq_mode] & 5 )); then
        FAST_HIGHLIGHT[chroma-fpath_peq-elements]="! ${FAST_HIGHLIGHT[chroma-fpath_peq-elements]}"
    fi
    return 1
} || {
    # Following call, i.e. not the first one

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    [[ "$__wrd" != ")" ]] && {
        deserialized=( "${(Q@)${(z@)FAST_HIGHLIGHT[chroma-fpath_peq-elements]}}" )
        [[ -z "${deserialized[1]}" && ${#deserialized} -eq 1 ]] && deserialized=()
        # Support ~ and $VAR, for [a-zA-Z_][a-ZA-Z0-9_]# characters in "VAR"
        deserialized+=( "${(Q)${${(j: :)__wrd}//(#b)((\$([0-9]##|[a-zA-Z_][a-zA-Z0-9_]#))|(\$\{([0-9]##|[a-zA-Z_][a-zA-Z0-9_]#)\})|(#s)~)/${(P)${${${${match[1]##\$\{(#c0,1)}%\}}:#\~}:-HOME}}}}" )
        FAST_HIGHLIGHT[chroma-fpath_peq-elements]="${(j: :)${(q@)deserialized}}"
    }

    return 1
}

(( this_word = next_word ))
_start_pos=$_end_pos

return 0

# vim:ft=zsh:et:sw=4
