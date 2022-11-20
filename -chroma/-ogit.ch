# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
# Copyright (c) 2018 plexigras
#
# The old chroma function for command `git'. It colorizes the part of command
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
local -a __lines_list chroma_git_remote_subcommands
chroma_git_remote_subcommands=(add rename remove set-head set-branches get-url set-url set-url set-url show prune update)

if (( __first_call )); then
    # Called for the first time - new command
    # FAST_HIGHLIGHT is used because it survives between calls, and
    # allows to use a single global hash only, instead of multiple
    # global variables
    FAST_HIGHLIGHT[chroma-git-counter]=0
    FAST_HIGHLIGHT[chroma-git-got-subcommand]=0
    FAST_HIGHLIGHT[chroma-git-subcommand]=""
    FAST_HIGHLIGHT[chrome-git-got-msg1]=0
    FAST_HIGHLIGHT[chrome-git-got-anymsg]=0
    FAST_HIGHLIGHT[chrome-git-occurred-double-hyphen]=0
    FAST_HIGHLIGHT[chroma-git-checkout-new]=0
    FAST_HIGHLIGHT[chroma-git-fetch-multiple]=0
    FAST_HIGHLIGHT[chroma-git-branch-change]=0
    FAST_HIGHLIGHT[chroma-git-option-with-argument-active]=0
    return 1
else
    # Following call, i.e. not the first one

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    if [[ "$__wrd" = "--" ]]; then
        FAST_HIGHLIGHT[chrome-git-occurred-double-hyphen]=1
        __style=${FAST_THEME_NAME}double-hyphen-option
    elif [[ "$__wrd" = -* && ${FAST_HIGHLIGHT[chroma-git-got-subcommand]} -eq 0 ]]; then
        # Options occuring before a subcommand
        if (( FAST_HIGHLIGHT[chroma-git-option-with-argument-active] == 0 )); then
            if [[ "$__wrd" = -[^[:space:]-]#C ]]; then
                FAST_HIGHLIGHT[chroma-git-option-with-argument-active]=2
            elif [[ "$__wrd" = -[^[:space:]-]#c ]]; then
                FAST_HIGHLIGHT[chroma-git-option-with-argument-active]=1
            fi
        fi
        return 1
    else
        # If at e.g. '>' or destination/source spec (of the redirection)
        if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
            return 1
        # If at main git option taking argument in a separate word (-C and -c)
        elif (( FAST_HIGHLIGHT[chroma-git-option-with-argument-active] > 0 && \
            0 == FAST_HIGHLIGHT[chroma-git-got-subcommand] ))
        then
            # Remember the value
            __idx2=${FAST_HIGHLIGHT[chroma-git-option-with-argument-active]}
            # Reset the is-argument mark-field
            FAST_HIGHLIGHT[chroma-git-option-with-argument-active]=0

            (( __idx2 == 2 )) && return 1
            # Other options' args (i.e. arg of -c) aren't routed to the big-loop
            # as they aren't paths and aren't handled in any special way there
        elif (( FAST_HIGHLIGHT[chroma-git-got-subcommand] == 0 )); then
            FAST_HIGHLIGHT[chroma-git-got-subcommand]=1

            # Check if the command is an alias - we want to highlight the
            # aliased command just like the target command of the alias
            .fast-run-command "git config --get-regexp 'alias.*'" chroma-git-alias-list "" $(( 10 * 60 ))
            # Grep for line: alias.{user-entered-subcmd}[[:space:]], and remove alias. prefix
            __lines_list=( ${${(M)__lines_list[@]:#alias.${__wrd}[[:space:]]##*}#alias.} )

            if (( ${#__lines_list} > 0 )); then
                # (*)
                # First remove alias name (#*[[:space:]]) and the space after it, then
                # remove any leading spaces from what's left (##[[:space:]]##), then
                # remove everything except the first word that's in the left line
                # (%%[[:space:]]##*, i.e.: "everything from right side up to any space")
                FAST_HIGHLIGHT[chroma-git-subcommand]="${${${__lines_list[1]#*[[:space:]]}##[[:space:]]##}%%[[:space:]]##*}"
            else
                FAST_HIGHLIGHT[chroma-git-subcommand]="$__wrd"
            fi
            if (( __start_pos >= 0 )); then
                # if subcommand exists
                LANG=C .fast-run-command "git help -a" chroma-git-subcmd-list "" $(( 10 * 60 ))
                # (s: :) will split on every space, but because the expression
                # isn't double-quoted, the empty elements will be eradicated
                # Some further knowledge-base: s-flag is special, it skips
                # empty elements and creates an array (not a concatenated
                # string) even when double-quoted. The normally needed @-flag
                # that logically breaks the concaetnated string back into array
                # in case of double-quoting has additional effect for s-flag:
                # it finally blocks empty-elements eradication.
                if [[ "${__lines_list[1]}" = See* ]]; then
                    # (**)
                    # git >= v2.20
                    __lines_list=( ${(M)${${${(M)__lines_list[@]:# [[:blank:]]#[a-z]*}##[[:blank:]]##}%%[[:blank:]]##*}:#${FAST_HIGHLIGHT[chroma-git-subcommand]}} )
                else
                    # (**)
                    # git < v2.20
                    __lines_list=( ${(M)${(s: :)${(M)__lines_list[@]:#  [a-z]*}}:#${FAST_HIGHLIGHT[chroma-git-subcommand]}} )
                fi

                # Above we've checked:
                # 1) If given subcommand is an alias (*)
                # 2) If the command, or command pointed by the alias, exists (**)
                # 3) There's little problem, git v2.20 outputs aliases in git help -a,
                #    which means that alias will be recognized as correct if it will
                #    point at another alias or on itself. That's a minor problem, a
                #    TODO for future planned optimization for v2.20 Git
                # 4) Notice that the above situation is better than the previous - the
                #    alias is being verified to point to a valid git subcommand
                # That's all that's needed to decide on the correctnes:
                if (( ${#__lines_list} > 0 )); then
                    __style=${FAST_THEME_NAME}subcommand
                else
                    __style=${FAST_THEME_NAME}incorrect-subtle
                fi
            fi
            # The counter includes the subcommand itself
            (( FAST_HIGHLIGHT[chroma-git-counter] += 1 ))
        else
            __wrd="${__wrd//\`/x}"
            __arg="${__arg//\`/x}"
            __wrd="${(Q)__wrd}"
            if [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "push" \
                || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "pull" \
                || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "fetch" ]] \
                && (( ${FAST_HIGHLIGHT[chroma-git-fetch-multiple]} == 0 )); then
                # if not option
                if [[ "$__wrd" != -* || "${FAST_HIGHLIGHT[chrome-git-occurred-double-hyphen]}" -eq 1 ]]; then
                    (( FAST_HIGHLIGHT[chroma-git-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-git-counter] ))
                    if (( __idx1 == 2 )); then
                        .fast-run-git-command "git remote" "chroma-git-remotes" ""
                    else
                        __wrd="${__wrd%%:*}"
                        .fast-run-git-command "git for-each-ref --format='%(refname:short)' refs/heads" "chroma-git-branches" "refs/heads"
                    fi
                    # if remote/ref exists
                    if [[ -n ${__lines_list[(r)$__wrd]} ]]; then
                        (( __start=__start_pos-${#PREBUFFER}, __end=__start_pos+${#__wrd}-${#PREBUFFER}, __start >= 0 )) && \
                            reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}correct-subtle]}")
                    # if ref (__idx1 == 3) does not exist and subcommand is push
                    elif (( __idx1 != 2 )) && [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "push" ]]; then
                        (( __start=__start_pos-${#PREBUFFER}, __end=__start_pos+${#__wrd}-${#PREBUFFER}, __start >= 0 )) && \
                            reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
                    # if not existing remote name, because not an URL (i.e. no colon)
                    elif [[ $__idx1 -eq 2 && $__wrd != *:* ]]; then
                        (( __start=__start_pos-${#PREBUFFER}, __end=__start_pos+${#__wrd}-${#PREBUFFER}, __start >= 0 )) && \
                            reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
                    fi
                # if option
                else
                    if [[ "$__wrd" = "--multiple" && "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "fetch" ]]; then
                        FAST_HIGHLIGHT[chroma-git-fetch-multiple]=1
                        __style=${FAST_THEME_NAME}double-hyphen-option
                    else
                        return 1
                    fi
                fi
            elif (( ${FAST_HIGHLIGHT[chroma-git-fetch-multiple]} )) \
                && [[ "$__wrd" != -* || "${FAST_HIGHLIGHT[chrome-git-occurred-double-hyphen]}" -eq 1 ]]; then
                .fast-run-git-command "git remote" "chroma-git-remotes" ""
                if [[ -n ${__lines_list[(r)$__wrd]} ]]; then
                    __style=${FAST_THEME_NAME}correct-subtle
                fi
            elif [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "commit" ]]; then
                match[1]=""
                match[2]=""
                # if previous argument is -m or current argument is --message=something
                if (( FAST_HIGHLIGHT[chrome-git-got-msg1] == 1 && ! FAST_HIGHLIGHT[chrome-git-got-anymsg] )) \
                    || [[ "$__wrd" = (#b)(--message=)(*) && "${FAST_HIGHLIGHT[chrome-git-occurred-double-hyphen]}" = 0 ]]; then
                    FAST_HIGHLIGHT[chrome-git-got-msg1]=0
                    FAST_HIGHLIGHT[chrome-git-got-anymsg]=1
                    if [[ -n "${match[1]}" ]]; then
                        __wrd="${(Q)${match[2]//\`/x}}"
                        # highlight (--message=)something
                        (( __start=__start_pos-${#PREBUFFER}, __end=__start_pos-${#PREBUFFER}+10, __start >= 0 )) && \
                            reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}double-hyphen-option]}")
                        # highlight --message=(something)
                        (( __start=__start_pos-${#PREBUFFER}+10, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && \
                            reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}double-quoted-argument]}")
                    else
                        (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && \
                            reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}double-quoted-argument]}")
                    fi
                    local __firstline=${__wrd%%$'\n'*}
                    if (( ${#__firstline} > 50 )); then
                        for (( __idx1 = 1, __idx2 = 1; __idx1 <= 50; ++ __idx1, ++ __idx2 )); do
                            while [[ "${__arg[__idx2]}" != "${__firstline[__idx1]}" ]]; do
                                (( ++ __idx2 ))
                                (( __idx2 > __asize )) && { __idx2=-1; break; }
                            done
                            (( __idx2 == -1 )) && break
                        done
                        if (( __idx2 != -1 )); then
                            if [[ -n "${match[1]}" ]]; then
                                (( __start=__start_pos-${#PREBUFFER}+__idx2, __end=__end_pos-${#PREBUFFER}-$#__wrd+$#__firstline-1, __start >= 0 )) && \
                                    reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
                            else
                                (( __start=__start_pos-${#PREBUFFER}+__idx2-1, __end=__end_pos-${#PREBUFFER}-$#__wrd+$#__firstline-1, __start >= 0 )) && \
                                    reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
                            fi
                        fi
                    fi
                # if before --
                elif [[ "${FAST_HIGHLIGHT[chrome-git-occurred-double-hyphen]}" = 0 ]]; then
                    if [[ "$__wrd" = -[^[:space:]-]#m ]]; then
                        FAST_HIGHLIGHT[chrome-git-got-msg1]=1
                        __style=${FAST_THEME_NAME}single-hyphen-option
                    else
                        return 1
                    fi
                # if after -- is file
                elif [[ -e "$__wrd" ]]; then
                    __style=${FAST_THEME_NAME}path
                else
                    __style=${FAST_THEME_NAME}incorrect-subtle
                fi
            elif [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "checkout" ]] \
                || [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "revert" ]] \
                || [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "merge" ]] \
                || [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "diff" ]] \
                || [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "reset" ]] \
                || [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "rebase" ]]; then

                # if doing `git checkout -b ...'
                if [[ "$__wrd" = -[^[:space:]-]#b && "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "checkout" ]]; then
                    FAST_HIGHLIGHT[chroma-git-checkout-new]=1
                    __style=${FAST_THEME_NAME}single-hyphen-option
                # if command is not checkout -b something
                elif [[ "${FAST_HIGHLIGHT[chroma-git-checkout-new]}" = 0 ]]; then
                    # if not option
                    if [[ "$__wrd" != -* || "${FAST_HIGHLIGHT[chrome-git-occurred-double-hyphen]}" = 1 ]]; then
                        (( FAST_HIGHLIGHT[chroma-git-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-git-counter] ))
                        if (( __idx1 == 2 )) || \
                            [[ "$__idx1" = 3 && "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "diff" ]]; then
                            # if is ref
                            if command git rev-parse --verify --quiet "$__wrd" >/dev/null 2>&1; then
                                __style=${FAST_THEME_NAME}correct-subtle
                            # if is file and subcommand is checkout or diff
                            elif [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "checkout" \
                                || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "reset" \
                                || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "diff" ]] && [[ -e ${~__wrd} ]]; then
                                __style=${FAST_THEME_NAME}path
                            elif [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "checkout" && \
                                    "1" = "$(command git rev-list --count --no-walk --glob="refs/remotes/${$(git \
                                        config --get checkout.defaultRemote):-*}/$__wrd")" ]]
                            then
                                __style=${FAST_THEME_NAME}correct-subtle
                            else
                                __style=${FAST_THEME_NAME}incorrect-subtle
                            fi
                        fi
                    # if option
                    else
                        return 1
                    fi
                # if option
                elif [[ "${FAST_HIGHLIGHT[chrome-git-occurred-double-hyphen]}" = 0 && "$__wrd" = -* ]]; then
                    return 1
                fi
            elif [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "remote" && "$__wrd" != -* ]]; then
                (( FAST_HIGHLIGHT[chroma-git-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-git-counter] ))
                if [[ "$__idx1" = 2 ]]; then
                    if (( ${chroma_git_remote_subcommands[(I)$__wrd]} )); then
                        FAST_HIGHLIGHT[chroma-git-remote-subcommand]="$__wrd"
                        __style=${FAST_THEME_NAME}subcommand
                    else
                        __style=${FAST_THEME_NAME}incorrect-subtle
                    fi
                elif [[ "$__idx1" = 3 && "$FAST_HIGHLIGHT[chroma-git-remote-subcommand]" = "add" ]]; then
                    .fast-run-git-command "git remote" "chroma-git-remotes" ""
                    if [[ -n ${__lines_list[(r)$__wrd]} ]]; then
                        __style=${FAST_THEME_NAME}incorrect-subtle
                    fi
                elif [[ "$__idx1" = 3 && -n "$FAST_HIGHLIGHT[chroma-git-remote-subcommand]" ]]; then
                    .fast-run-git-command "git remote" "chroma-git-remotes" ""
                    if [[ -n ${__lines_list[(r)$__wrd]} ]]; then
                        __style=${FAST_THEME_NAME}correct-subtle
                    else
                        __style=${FAST_THEME_NAME}incorrect-subtle
                    fi
                fi
            elif [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "branch" ]]; then
                if [[ "$__wrd" = --delete \
                    ||  "$__wrd" = --edit-description \
                    ||  "$__wrd" = --set-upstream-to=* \
                    ||  "$__wrd" = --unset-upstream \
                    ||  "$__wrd" = -[^[:space:]-]#d \
                    ||  "$__wrd" = -[^[:space:]-]#D ]]; then
                    FAST_HIGHLIGHT[chroma-git-branch-change]=1
                    return 1
                elif [[ "$__wrd" != -* ]]; then
                    .fast-run-git-command "git for-each-ref --format='%(refname:short)' refs/heads" "chroma-git-branches" "refs/heads"
                    if [[ -n ${__lines_list[(r)$__wrd]} ]]; then
                        __style=${FAST_THEME_NAME}correct-subtle
                    elif (( FAST_HIGHLIGHT[chroma-git-branch-change] )); then
                        __style=${FAST_THEME_NAME}incorrect-subtle
                    fi
                else
                    return 1
                fi
            elif [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "tag" ]]; then
                if [[ "${FAST_HIGHLIGHT[chroma-git-option-with-argument-active]}" -le 0 ]]; then
                    if [[ "$__wrd" =  -[^[:space:]-]#(u|m) ]]; then
                        FAST_HIGHLIGHT[chroma-git-option-with-argument-active]=1
                    elif [[ "$__wrd" = -[^[:space:]-]#F ]]; then
                        FAST_HIGHLIGHT[chroma-git-option-with-argument-active]=2
                    elif [[ "$__wrd" = -[^[:space:]-]#d ]]; then
                        FAST_HIGHLIGHT[chroma-git-option-with-argument-active]=3
                    elif [[ "$__wrd" = (--contains|--no-contains|--points-at|--merged|--no-merged) ]]; then
                        FAST_HIGHLIGHT[chroma-git-option-with-argument-active]=4
                    fi
                    if [[ "$__wrd" != -* ]]; then
                        (( FAST_HIGHLIGHT[chroma-git-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-git-counter] ))
                        if [[ ${FAST_HIGHLIGHT[chroma-git-counter]} -eq 2 ]]; then
                            .fast-run-git-command "git for-each-ref --format='%(refname:short)' refs/heads" "chroma-git-branches" "refs/heads"
                            .fast-run-git-command "+git tag" "chroma-git-tags" ""
                            [[ -n ${__lines_list[(r)$__wrd]} ]] && __style=${FAST_THEME_NAME}incorrect-subtle
                        elif [[ ${FAST_HIGHLIGHT[chroma-git-counter]} -eq 3 ]]; then
                        fi
                    else
                        return 1
                    fi
                else
                    case "${FAST_HIGHLIGHT[chroma-git-option-with-argument-active]}" in
                        (1) 
                            __style=${FAST_THEME_NAME}optarg-string
                            ;;
                        (2)
                            FAST_HIGHLIGHT[chroma-git-option-with-argument-active]=0
                            return 1;
                            ;;
                        (3)
                            .fast-run-git-command "git tag" "chroma-git-tags" ""
                            [[ -n ${__lines_list[(r)$__wrd]} ]] && \
                                __style=${FAST_THEME_NAME}correct-subtle || \
                                __style=${FAST_THEME_NAME}incorrect-subtle
                            ;;
                        (4)
                            if git rev-parse --verify --quiet "$__wrd" >/dev/null 2>&1; then
                                __style=${FAST_THEME_NAME}correct-subtle
                            else
                                __style=${FAST_THEME_NAME}incorrect-subtle
                            fi
                            ;;
                    esac
                    FAST_HIGHLIGHT[chroma-git-option-with-argument-active]=0
                fi
            else
                return 1
            fi
        fi
    fi
fi

# Add region_highlight entry (via `reply' array)
if [[ -n "$__style" ]]; then
    (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) \
        && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style]}")
fi

# We aren't passing-through, do obligatory things ourselves
(( this_word = next_word ))
_start_pos=$_end_pos

return 0

# vim:ft=zsh:et:sw=4
