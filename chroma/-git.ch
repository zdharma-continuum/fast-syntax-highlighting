# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
#
# Chroma function for command `git'. It colorizes the part of command
# line that holds `git' invocation.
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
local -a __lines_list

(( __first_call )) && {
    # Called for the first time - new command
    # FAST_HIGHLIGHT is used because it survives between calls, and
    # allows to use a single global hash only, instead of multiple
    # global variables
    FAST_HIGHLIGHT[chroma-git-counter]=0
    FAST_HIGHLIGHT[chroma-git-got-subcommand]=0
    FAST_HIGHLIGHT[chroma-git-subcommand]=""
    FAST_HIGHLIGHT[chrome-git-got-msg1]=0
    __style=${FAST_THEME_NAME}command
} || {
    # Following call, i.e. not the first one

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    if [[ "$__wrd" = -* && ${FAST_HIGHLIGHT[chroma-git-got-subcommand]} -eq 0 ]]; then
        __style=${FAST_THEME_NAME}${${${__wrd:#--*}:+single-hyphen-option}:-double-hyphen-option}
    else
        if (( FAST_HIGHLIGHT[chroma-git-got-subcommand] == 0 )); then
            FAST_HIGHLIGHT[chroma-git-got-subcommand]=1
            FAST_HIGHLIGHT[chroma-git-subcommand]="$__wrd"
            __style=${FAST_THEME_NAME}reserved-word
            (( FAST_HIGHLIGHT[chroma-git-counter] += 1 ))
        else
            __wrd="${__wrd//\`/x}"
            __arg="${__arg//\`/x}"
            __wrd="${(Q)__wrd}"
            if [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "push" ]]; then
                [[ "$__wrd" != -* ]] && {
                    (( FAST_HIGHLIGHT[chroma-git-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-git-counter] ))
                    if (( __idx1 == 2 )); then
                        -fast-run-git-command "git remote" "chroma-git-remotes" ""
                        [[ -z ${__lines_list[(r)$__wrd]} ]] && __style=${FAST_THEME_NAME}unknown-token || __style=${FAST_THEME_NAME}reserved-word
                    elif (( __idx1 == 3 )); then
                        -fast-run-git-command "git for-each-ref --format='%(refname:short)' refs/heads" \
                                "chroma-git-branches" \
                                "refs/heads"
                        [[ -z ${__lines_list[(r)$__wrd]} ]] && __style=${FAST_THEME_NAME}unknown-token || __style=${FAST_THEME_NAME}reserved-word
                    fi
                } || __style=${FAST_THEME_NAME}${${${__wrd:#--*}:+single-hyphen-option}:-double-hyphen-option}
            elif [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "commit" ]]; then
                if (( FAST_HIGHLIGHT[chrome-git-got-msg1] == 1 )); then
                    FAST_HIGHLIGHT[chrome-git-got-msg1]=0
                    if (( ${#__wrd} <= 72 )); then
                        __style=${FAST_THEME_NAME}${${${__arg:#\"*}:+single-quoted-argument}:-double-quoted-argument}
                    else
                        for (( __idx1 = 1, __idx2 = 1; __idx1 <= 72; ++ __idx1, ++ __idx2 )); do
                            while [[ "${__arg[__idx2]}" != "${__wrd[__idx1]}" ]]; do
                                (( ++ __idx2 ))
                                (( __idx2 > __asize )) && { __idx2=-1; break; }
                            done
                            (( __idx2 == -1 )) && break
                        done
                        if (( __idx2 != -1 )); then
                            (( __start=__start_pos-${#PREBUFFER}, __end=__start_pos-${#PREBUFFER}+__idx2-1, __start >= 0 )) && \
                                reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}double-quoted-argument]}")
                            (( __start=__start_pos-${#PREBUFFER}+__idx2-1, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && \
                                reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}unknown-token]}")
                        fi
                    fi
                elif [[ "$__wrd" = "-m" ]]; then
                    FAST_HIGHLIGHT[chrome-git-got-msg1]=1
                fi
            elif [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "checkout" || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "revert" ]]; then
                [[ "$__wrd" != -* ]] && {
                    (( FAST_HIGHLIGHT[chroma-git-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-git-counter] ))
                    if (( __idx1 == 2 )); then
                        if git rev-parse --verify --quiet "$__wrd" >/dev/null 2>&1; then
                            __style=${FAST_THEME_NAME}builtin
                        else
                            __style=${FAST_THEME_NAME}unknown-token
                        fi
                    fi
                }
            fi
        fi
    fi
}

# Add region_highlight entry (via `reply' array)
[[ -n "$__style" ]] && (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style]}")

# We aren't passing-through, do obligatory things ourselves
(( this_word = next_word ))
_start_pos=$_end_pos

return 0

# vim:ft=zsh:et:sw=4
