# vim:ft=zsh:et:sw=4
(( next_word = 2 | 8192 ))
local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"

if (( __first_call )); then
    chroma/-git.ch $*
    return 1
fi
[[ "$__arg_type" = 3 ]] && return 2

if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
    return 1
fi

if [[ "$__wrd" != -* ]] && (( FAST_HIGHLIGHT[chroma-git-got-subcommand] == 0 )); then
    .fast-run-command "git config --get-regexp 'alias.*'" chroma-git-alias-list "" $(( 5 * 60 ))
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
    if [[ "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "browse" \
        || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "ci-status" \
        || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "compare" \
        || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "create" \
        || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "delete" \
        || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "fork" \
        || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "issue" \
        || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "pr" \
        || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "pull-request" \
        || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "release" \
        || "${FAST_HIGHLIGHT[chroma-git-subcommand]}" = "sync" ]]; then
            FAST_HIGHLIGHT[chroma-git-got-subcommand]=1
            (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) \
                && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}subcommand]}")
            (( FAST_HIGHLIGHT[chroma-git-counter] += 1 ))
            (( this_word = next_word ))
            _start_pos=$4
            return 0
    fi
fi

chroma/-git.ch $*
