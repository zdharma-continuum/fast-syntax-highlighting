# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
# Copyright (C) 2019 by Philippe Troin (F-i-f on GitHub)
#
# Tracks ssh command and emits message when one tries to pass port to hostspec.
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

emulate -LR zsh
setopt extended_glob warn_create_global typeset_silent

# This chroma guards that port number isn't passed in hostname (no :{port} occurs).

(( next_word = 2 | 8192 ))

local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"
local __style check_port=0 host_start_offset host_style user_style possible_host
local -a match mbegin mend completions_users completions_host

# First call, i.e. command starts, i.e. "grep" token etc.
(( __first_call )) && {
    FAST_HIGHLIGHT[chroma-ssh-counter]=0
    FAST_HIGHLIGHT[chroma-ssh-counter-all]=1
    FAST_HIGHLIGHT[chroma-ssh-message]=""
    FAST_HIGHLIGHT[chroma-ssh-skip-two]=0
    return 1
} || {
    # Following call, i.e. not the first one.

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
        return 1
    fi

    (( FAST_HIGHLIGHT[chroma-ssh-counter-all] += 1 ))

    if [[ "$__wrd" = -* ]]; then
        # Detected option, add style for it.
        [[ "$__wrd" = --* ]] && __style=${FAST_THEME_NAME}double-hyphen-option || \
                                __style=${FAST_THEME_NAME}single-hyphen-option
        if [[ "$__wrd" = (-b|-c|-D|-E|-e|-F|-I|-i|-J|-L|-l|-m|-O|-o|-p|Q|R|-S|-W|-w) ]]; then
            FAST_HIGHLIGHT[chroma-ssh-skip-two]=1
        fi
    else
        if (( FAST_HIGHLIGHT[chroma-ssh-skip-two] )); then
            FAST_HIGHLIGHT[chroma-ssh-skip-two]=0
        else
            # Count non-option tokens.
            (( FAST_HIGHLIGHT[chroma-ssh-counter] += 1 ))
            if [[ "${FAST_HIGHLIGHT[chroma-ssh-counter]}" -eq 1 ]]; then
                if [[ $__arg = (#b)(([^@]#)(@)|)(*) ]]
                then
                    [[ -n $match[2] ]] \
                        && {
                            user_style=
                            () {
                                # Zstyle clobbers reply for sure
                                zstyle -a ":completion:*:users" users completions_users
                            }
                            if (( $#completions_users )); then
                                [[ $match[2] = ${~${:-(${(j:|:)completions_users})}} ]] \
                                    && user_style=${FAST_THEME_NAME}correct-subtle \
                                    || user_style=${FAST_THEME_NAME}incorrect-subtle
                            elif (( $#userdirs )); then
                                [[ -n $userdirs[$match[2]] ]] \
                                    && user_style=${FAST_THEME_NAME}correct-subtle \
                                    || user_style=${FAST_THEME_NAME}incorrect-subtle
                            fi
                            [[ -n $user_style ]] \
                                && (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}-(mend[5]-mend[2]), __start >= 0 )) \
                                && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$user_style]}")
                        }
                    [[ -n $match[3] ]] \
                        && (( __start=__start_pos-${#PREBUFFER}+(mbegin[3]-mbegin[1]), __end=__end_pos-${#PREBUFFER}-(mend[5]-mend[3]), __start >= 0 )) \
                        && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}subtle-separator]}")

                    host_style=
                    case $match[4] in
                        (<->|<0-255>.<0-255>.<0-255>.<0-255>)
                            host_style=${FAST_THEME_NAME}mathnum
                            check_port=1
                            ;;
                        (([0-9a-fA-F][0-9a-fA-F:]#|)::([0-9a-fA-F:]#[0-9a-fA-F]|)|[0-9a-fA-F]##:[0-9a-fA-F:]#[0-9a-fA-F])
                            host_style=${FAST_THEME_NAME}mathnum
                            ;;
                        (*)
                            check_port=1
                            ;;
                    esac
                    possible_host=$match[4]
                    (( host_start_offset = mbegin[4] - mbegin[1], host_end_offset = 0 ))

                    if (( check_port )) && [[ $possible_host = (#b)(*)(:[0-9]##) ]]; then
                        (( __start=__start_pos-${#PREBUFFER}+(host_start_offset+mbegin[2]-mbegin[1]), __end=__end_pos-host_end_offset-${#PREBUFFER}, __start >= 0,
                           host_end_offset+=mend[2]-mend[1] )) \
                            && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}") \
                            && possible_host=$match[1] \
                            && FAST_HIGHLIGHT[chroma-ssh-message]+="Format of hostname incorrect, use -p to pass port number"

                    fi

                    if [[ -z $host_style ]]; then
                        () {
                            # Zstyle clobbers reply for sure
                            local mbegin mend match reply
                            zstyle -a ":completion:*:hosts" hosts completions_host
                        }
                        (( ! $#completions_host && $+_cache_hosts )) && completions_host=($_cache_hosts[*])
                        if (( $#completions_host )); then
                                [[ $possible_host = ${~${:-(${(j:|:)completions_host})}} ]] \
                                    && host_style=${FAST_THEME_NAME}correct-subtle \
                                    || host_style=${FAST_THEME_NAME}incorrect-subtle
                        fi
                    fi

                    [[ -n $host_style ]] \
                        && (( __start=__start_pos-${#PREBUFFER}+host_start_offset, __end=__end_pos-${#PREBUFFER}-host_end_offset, __start >= 0 )) \
                        && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$host_style]}")
                else
                    __style=${FAST_THEME_NAME}incorrect-subtle
                fi

                (( next_word = 1 ))

            fi
        fi
    fi

    if (( ${#${(z)BUFFER}} <= FAST_HIGHLIGHT[chroma-ssh-counter-all] )); then
        [[ -n "${FAST_HIGHLIGHT[chroma-ssh-message]}" ]] && zle -M "${FAST_HIGHLIGHT[chroma-ssh-message]}"
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
