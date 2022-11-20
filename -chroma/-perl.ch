# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
#
# Chroma function for command `perl'. It highlights code passed to perl
# with -e option - does syntax check by calling `perl -ce', then highlights
# as correct or incorrect code.
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

local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"
local __style
integer __idx1 __idx2

(( __first_call )) && {
    # Called for the first time - new command.
    # FAST_HIGHLIGHT is used because it survives between calls, and
    # allows to use a single global hash only, instead of multiple
    # global variables.
    FAST_HIGHLIGHT[chrome-perl-got-eswitch]=0
    return 1
} || {
    # Following call, i.e. not the first one.

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
        return 1
    fi

    if [[ "$__wrd" = -* && ${FAST_HIGHLIGHT[chroma-perl-got-subcommand]} -eq 0 ]]; then
        __style=${FAST_THEME_NAME}${${${__wrd:#--*}:+single-hyphen-option}:-double-hyphen-option}

        if [[ "$__wrd" = "-e" || ("$__wrd" = -*e* && "$__wrd" != --*) ]]; then
            FAST_HIGHLIGHT[chrome-perl-got-eswitch]=1
        fi
    else
        __wrd="${__wrd//\`/x}"
        __arg="${__arg//\`/x}"
        __wrd="${(Q)__wrd}"
        if (( FAST_HIGHLIGHT[chrome-perl-got-eswitch] == 1 )); then
            FAST_HIGHLIGHT[chrome-perl-got-eswitch]=0
            if perl -ce "$__wrd" >/dev/null 2>&1; then
                # Add correct-subtle style
                (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}correct-subtle]}")
            else
                # Add incorrect-subtle style
                (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
            fi
        else
            # Pass-through to the big-loop outside
            return 1
        fi
    fi
}

# Add region_highlight entry (via `reply' array)
#
# This is a common place of adding such entry, but any above
# code can do it itself (and it does) and skip setting __style
# to disable this code.
[[ -n "$__style" ]] && (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style]}")

# We aren't passing-through, do obligatory things ourselves
(( this_word = next_word ))
_start_pos=$_end_pos

return 0

# vim:ft=zsh:et:sw=4
