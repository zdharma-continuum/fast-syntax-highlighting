# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
#
# Chroma function for command `git'. It colorizes the part of command
# line that holds `git' invocation.

(( FAST_HIGHLIGHT[-git.ch-chroma-def] )) && return 1

FAST_HIGHLIGHT[-git.ch-chroma-def]=1

typeset -gA fsh__git__chroma__def
fsh__git__chroma__def=(
    "subcmd:NULL" "NULL_0_opt"
    "NULL_0_opt" "(-C|--exec-path=|--git-dir=|--work-tree=|--namespace=|--super-prefix=)
                   <<>> NO-OP // ::chroma/main-chroma-std-aopt-action
                   <<>> NO-OP // ::chroma/main-chroma-std-aopt-ARG-action
            || -c
                    <<>> __style=\${FAST_THEME_NAME}single-hyphen-option // NO-OP
                    <<>> __style=\${FAST_THEME_NAME}optarg-string // NO-OP
            || (--version|--help|--html-path|--man-path|--info-path|-p|--paginate|
		-P|--no-pager|--no-replace-objects|--bare)
                   <<>> NO-OP // ::chroma/main-chroma-std-aopt-action"


    "subcommands" "::chroma/-git-get-subcommands" # run a function (the :: causes this) and use `reply'
    #"subcommands" "(fetch|pull)" # run a function (the :: causes this) and use `reply'

    "subcmd-hook" "chroma/-git-check-if-alias"

    ##
    ## `FETCH'
    ##

    "subcmd:fetch" "FETCH_MULTIPLE_0_opt^ // FETCH_ALL_0_opt^ // FETCH_0_opt // REMOTE_GR_1_arg // REF_#_arg // FETCH_NO_MATCH_0_opt"

    # Special options (^ - has directives, currently - an :add and :del directive)
    "FETCH_MULTIPLE_0_opt^" "
                --multiple
                        <<>> __style=\${FAST_THEME_NAME}double-hyphen-option // NO-OP
                || --multiple:add
                        <<>> REMOTE_GR_#_arg
                || --multiple:del
                        <<>> REMOTE_GR_1_arg // REF_#_arg" # when --multiple is passed, then
                                        # there is no refspec argument, only remotes-ids
                                        # follow unlimited # of them, hence the # in the
                                        # REF_#_arg

    # Special options (^ - has directives - an :del-directive)
    "FETCH_ALL_0_opt^" "
                --all
                    <<>> __style=\${FAST_THEME_NAME}double-hyphen-option // NO-OP
                || --all:del
                    <<>> REMOTE_GR_1_arg // REF_#_arg" # --all can be only followed by options

    # FETCH_0_opt. FETCH-options (FETCH is an identifier) at position 0 ->
    #   -> before any argument
    "FETCH_0_opt" "
              (--depth=|--deepen=|--shallow-exclude=|--shallow-since=|--receive-pack=|
               --refmap=|--recurse-submodules=|-j|--jobs=|--submodule-prefix=|
               --recurse-submodules-default=)
                       <<>> NO-OP // ::chroma/main-chroma-std-aopt-action
                       <<>> NO-OP // ::chroma/main-chroma-std-aopt-ARG-action
           || (--help|--all|-a|--append|--unshallow|--update-shallow|--dry-run|-f|--force|
               -k|--multiple|-p|--prune|-n|--no-tags|-t|--tags|--no-recurse-submodules|
               -u|--update-head-ok|--upload-pack|-q|--quiet|-v|--verbose|--progress|
               -4|--ipv4|-6|--ipv6)
                   <<>> __style=\${FAST_THEME_NAME}single-hyphen-option // NO-OP"
                   # Above: note the two <<>>-separated blocks for options that have
                   # some arguments – the second pair of action/handler is being
                   # run when an option argument is occurred (first one: the option
                   # itself). If there is only one <<>>-separated block, then the option
                   # is set to be argument-less. The argument is a) -o/--option argument
                   # and b) -o/--option=argument.

    "REMOTE_GR_1_arg" "NO-OP // ::chroma/-git-remote-verify" # This definition is generic, reused later
    "REF_#_arg" "NO-OP // ::chroma/-git-ref-verify" # This too
    "REMOTE_GR_#_arg" "NO-OP // ::chroma/-git-remote-or-group-verify" # and this too
    # The hash `#' above denotes: an argument at any position
    # It will nicely match any following (above the first explicitly
    # numbered ones) arguments passed when using --multiple

    "FETCH_NO_MATCH_0_opt" "* <<>> __style=\${FAST_THEME_NAME}incorrect-subtle // NO-OP"

    ##
    ## push
    ##

    "subcmd:push" "PUSH_0_opt // REMOTE_1_arg // REF_#_arg"

    "PUSH_0_opt" "
              (--receive-pack=|--exec=|--repo=|--push-option=|--signed=|
                  --force-with-lease=|--signed=|--recurse-submodules=)
                   <<>> NO-OP // ::chroma/main-chroma-std-aopt-action
                   <<>> NO-OP // ::chroma/main-chroma-std-aopt-ARG-action
           || (--help|--all|--mirror|--tags|--follow-tags|--atomic|-n|--dry-run|
               --porcelain|--delete|--tags|--follow-tags|--signed|--no-signed|
               --atomic|--no-atomic|-o|--push-option|--force-with-lease|
               --no-force-with-lease|-f|--force|-u|--set-upstream|--thin|
               --no-thin|-q|--quiet|-v|--verbose|--progress|--no-recurse-submodules|
               --verify|--no-verify|-4|--ipv4|-6|--ipv6)
                   <<>> __style=\${FAST_THEME_NAME}single-hyphen-option // NO-OP"

    "REMOTE_1_arg" "NO-OP // ::chroma/-git-remote-verify" # This definition is generic, reused later

    ##
    ## `COMMIT'
    ##

    "subcmd:commit" "COMMIT_#_opt // FILE_#_arg"

    "COMMIT_#_opt" "
              (-m|--message=)
                       <<>> NO-OP // ::chroma/-git-commit-msg-opt-action
                       <<>> NO-OP // ::chroma/-git-commit-msg-opt-ARG-action
           || (--help|-a|--all|-p|--patch|--reset-author|--short|--branch|
               --porcelain|--long|-z|--null|-s|--signoff|-n|--no-verify|
               --allow-empty|--allow-empty-message|-e|--edit|--no-edit|
               --amend|--no-post-rewrite|-i|--include|-o|--only|--untracked-files|
               -v|--verbose|-q|--quiet|--dry-run|--status|--no-status|--no-gpg-sign)
                       <<>> NO-OP // ::chroma/main-chroma-std-aopt-action
           || (-C|--reuse-message=|-c|--reedit-message=|--fixup=|--squash=|
               -F|--file=|--author=|--date=|-t|--template=|--cleanup=|
               -u|--untracked-files=|-S|--gpg-sign=)
                       <<>> NO-OP // ::chroma/main-chroma-std-aopt-action
                       <<>> NO-OP // ::chroma/main-chroma-std-aopt-ARG-action"

    "FILE_#_arg" "NO-OP // chroma/-git-file-verify"

    ##
    ## Unfinished / old follow
    ##


    # `MERGE'
    "subcmd:merge" "E_0_opt_with_arg // E_0_opt_arg // E_1_arg"
    "E_0_opt_with_arg:(-m|--message=)" "return 1 // NO-OP"
    "E_0_opt_arg" "// ::-chroma-verify-commit-msg"
    "E_1_arg" "// ::(-chroma-git-rev-verify||-std-ch-path-verify)" # verify revision or if not succeed, a path

    # `MERGE'|`RESET'|`REBASE'
    "subcmd:(reset|rebase)" "Z_1_arg"
    "Z_1_arg" "// ::(-chroma-git-rev-verify||-std-ch-path-verify)" # verify revision or if not succeed, a path

    # `REVERT'
    "subcmd:revert" "P_1_arg"
    "P_1_arg" "// ::-chroma-git-rev-verify"

    # `DIFF'
    "subcmd:diff" "Q_1_arg // Q_2_arg"
    "Q_1_arg" "// ::(-chroma-git-rev-verify||-std-ch-path-verify)"
    "Q_2_arg" "// ::(-chroma-git-rev-verify||-std-ch-path-verify)"

    # `CHECKOUT'
    "subcmd:checkout" "R-*1-opt // R_1_arg || S_1_arg"
    "R-*1-opt:-b" "return 1 // ::-chroma-got--b" # mandatory (the *) -b option, occuring at 1st position
    "R_1_arg" "// ::-chroma-git-rev-averify"     # *-averify -> opposite functioning - exists -> incorrect, !exists -> correct


    # OR (main form of the checkout command)
    "S_1_arg" "// ::(-chroma-git-rev-verify||-chroma-git-remote-rev-verify||-std-ch-path-verify)"

    # `REMOTE'
    "subcmd:remote" "T-*1-arg // T_2_arg || U-*1-arg // U_2_arg || B_0_opt // B_0_arg"
    "T-*1-arg:add" "// NO-OP"
    "T_2_arg" "// ::-chroma-git-remote-averify-weak" # If 1st arg is add, then second arg is an opposite-good
                                                     # existence check, weak (bad result is highlighted)
    # OR
    "U-*1-arg:!chroma_git_remote_subcommands" "// ::-chroma-git-remote-subcommand" # Take subcommands from array
    "U_2_arg" "::-chroma-git-remote-verify"                                        # Verify the `git remote subcmd {arg}'

    # OR
    "B_#_opt" "// ::-chroma-git-incorrect-cmd-line"
    "B_#_arg" "// ::-chroma-git-incorrect-cmd-line"

    # `BRANCH'
    "subcmd:branch"  "V-*1-opt // V_1_arg || W_1_arg"            # New Git's main subcommand: branch
    "V-*1-opt:!branch_change_options" "::-chroma-git-branch-opt" # Alternative of (required: the *) options, from array `branch_change_options'
    "V_1_arg" "::-chroma-git-verify-ref"                         # 1st argument must be an existing branch name (i.e.
                                                                 # incorrect-subtle is being used)
    # OR
    "W_1_arg" "::-chroma-git-verify-ref-weak" # 1st argument can be an existing branch, that would be applying
                                              # the correct-subtle style

    # `TAG'
    "subcmd:tag" "A_0_opt_with_arg // A_0_opt_arg // A_1_arg" # 0 meaning: before any argument
    "A_0_opt_with_arg:(-u|-m|-F|-d|--contains|--no-contains|--points-at|--merged|--no-merged)" "return 1 // NO-OP"
    "A_0_opt_arg" "::-chroma-handle-tag-option-argument"
    "A_1_arg" "::-chroma-git-averify-ref-and-tag" # opposite (exists -> incorrect-subtle) verification of
                                                  # existence in all refs and all tags

)

# Called after entering just "git" on the command line
chroma/-git-first-call() {
    # Called for the first time - new command
    # FAST_HIGHLIGHT is used because it survives between calls, and
    # allows to use a single global hash only, instead of multiple
    # global variables
    FAST_HIGHLIGHT[chroma-git-counter]=0
    FAST_HIGHLIGHT[chroma-git-got-subcommand]=0
    FAST_HIGHLIGHT[chroma-git-subcommand]=""
    FAST_HIGHLIGHT[chrome-git-got-msg1]=0
    FAST_HIGHLIGHT[chrome-git-occurred-double-hyphen]=0
    FAST_HIGHLIGHT[chroma-git-checkout-new]=0
    FAST_HIGHLIGHT[chroma-git-fetch-multiple]=0
    FAST_HIGHLIGHT[chroma-git-branch-change]=0
    FAST_HIGHLIGHT[chroma-git-option-with-argument-active]=0
    return 1
}

chroma/-git-check-if-alias() {
    local _wrd="$1"
    local -a _result

    typeset -ga fsh__chroma__git__aliases
    _result=( ${(M)fsh__chroma__git__aliases[@]:#${_wrd}[[:space:]]##*} )
    chroma/main-chroma-print "Got is-alias-_result: $_result" >> /tmp/fsh-dbg
    [[ -n "$_result" ]] && \
	FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]="${${${_result#* }## ##}%% *}"
}

# A hook that returns the list of git's
# available subcommands in $reply
chroma/-git-get-subcommands() {
    local __svalue
    integer __ivalue
    LANG=C -fast-run-command "git help -a" chroma-${FAST_HIGHLIGHT[chroma-current]}-subcmd-list "" $(( 15 * 60 ))
    if [[ "${__lines_list[1]}" = See* ]]; then
        # (**)
        # git >= v2.20, the aliases in the `git help -a' command
        __lines_list=( ${${${${(M)__lines_list[@]:#([[:space:]][[:space:]]#[a-z]*|Command aliases)}##[[:space:]]##}//Command\ aliases/Command_aliases}} )
        __svalue="+${__lines_list[(I)Command_aliases]}"
        __lines_list[1,__svalue-1]=( ${(@)__lines_list[1,__svalue-1]%%[[:space:]]##*} )
    else
        # (**)
        # git < v2.20, add aliases through extra code
        __lines_list=( ${(s: :)${(M)__lines_list[@]:#  [a-z]*}} )

        __svalue=${#__lines_list}
        # This allows to check if the command is an alias - we want to
        # highlight the aliased command just like the target command of
        # the alias
        -fast-run-command "+git config --get-regexp 'alias.*'" chroma-${FAST_HIGHLIGHT[chroma-current]}-alias-list "[[:space:]]#alias." $(( 15 * 60 ))
    fi

    __tmp=${#__lines_list}
    typeset -ga fsh__chroma__git__aliases
    fsh__chroma__git__aliases=( ${__lines_list[__svalue+1,__tmp]} )
    [[ ${__lines_list[__svalue]} != "Command_aliases" ]] && (( ++ __svalue, __ivalue=0, 1 )) || (( __ivalue=1 ))
    __lines_list[__svalue,__tmp]=( ${(@)__lines_list[__svalue+__ivalue,__tmp]%%[[:space:]]##*} )
    reply=( "${__lines_list[@]}" )
}

# A generic action
chroma/-git-remote-verify() {
    local _wrd="$4"
    -fast-run-git-command "git remote" "chroma-git-remotes-$PWD" "" $(( 2 * 60 ))
    [[ -n ${__lines_list[(r)$_wrd]} ]] && {
        __style=${FAST_THEME_NAME}correct-subtle; return 0
    } || {
        [[ $_wrd != *:* ]] && { __style=${FAST_THEME_NAME}incorrect-subtle; return 1; }
    }
}

# A generic action
chroma/-git-ref-verify() {
    local _wrd="$4"
    _wrd="${_wrd%%:*}"
    -fast-run-git-command "git for-each-ref --format='%(refname:short)' refs/heads" "chroma-git-branches-$PWD" "refs/heads" $(( 2 * 60 ))
    [[ -n ${__lines_list[(r)$_wrd]} ]] && {
        __style=${FAST_THEME_NAME}correct-subtle; return 0
    } || {
        __style=${FAST_THEME_NAME}incorrect-subtle; return 1
    }
}

# A generic action
chroma/-git-remote-or-group-verify() {
    chroma/-git-remote-verify "$@" && return 0
    # The check for a group is to follow below
    integer _start="$2" _end="$3"
    local _scmd="$1" _wrd="$4"
}

# A generic action
chroma/-git-file-verify() {
    local _wrd="$4"

    [[ -f "$_wrd" ]] && __style=${FAST_THEME_NAME}correct-subtle || \
        __style=${FAST_THEME_NAME}incorrect-subtle
}

# An action for the commit's -m/--message options
chroma/-git-commit-msg-opt-action() {
    chroma/main-chroma-std-aopt-action "$@"
}

# An action for the commit's -m/--message options' argument
chroma/-git-commit-msg-opt-ARG-action() {
    integer _start="$2" _end="$3"
    local _scmd="$1" _wrd="$4"

    (( __start >= 0 )) || return

    # Match the message body in case of an --message= option
    if [[ "$_wrd" = (#b)(--message=)(*) && -n "${match[2]}" ]]; then
        _wrd="${(Q)${match[2]//\`/x}}"
        # highlight --message=>>something<<
        reply+=("$(( __start+10 )) $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}double-quoted-argument]}")
    fi

    if (( ${#_wrd} > 50 )); then
        for (( __idx1 = 1, __idx2 = 1; __idx1 <= 50; ++ __idx1, ++ __idx2 )); do
            # Use __arg from the fast-highlight-process's scope
            while [[ "${__arg[__idx2]}" != "${_wrd[__idx1]}" ]]; do
                (( ++ __idx2 ))
                (( __idx2 > __asize )) && { __idx2=-1; break; }
            done
            (( __idx2 == -1 )) && break
        done
        if (( __idx2 != -1 )); then
            if [[ -n "${match[1]}" ]]; then
                reply+=("$(( __start+__idx2 )) $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
            else
                reply+=("$(( __start+__idx2-1 )) $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
            fi
        fi
    fi
}

return 0

# vim:ft=zsh:et:sw=4
