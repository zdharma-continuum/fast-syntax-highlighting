# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
#
# Chroma function for command `git'. It colorizes the part of command
# line that holds `git' invocation.

(( FAST_HIGHLIGHT[-git.ch-chroma-def] )) && return 1

FAST_HIGHLIGHT[-git.ch-chroma-def]=1

typeset -gA fsh__git__chroma__def
fsh__git__chroma__def=(
    ##
    ## No subcommand
    ##
    ## {{{

    subcmd:NULL "NULL_0_opt"
    NULL_0_opt "(-C|--exec-path=|--git-dir=|--work-tree=|--namespace=|--super-prefix=)
                   <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                   <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action
            || -c
                    <<>> __style=\${FAST_THEME_NAME}single-hyphen-option // NO-OP
                    <<>> __style=\${FAST_THEME_NAME}optarg-string // NO-OP
            || (--version|--help|--html-path|--man-path|--info-path|-p|--paginate|
		-P|--no-pager|--no-replace-objects|--bare)
                   <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"


    "subcommands" "::→chroma/-git-get-subcommands" # run a function (the :: causes this) and use `reply'
    #"subcommands" "(fetch|pull)" # run a function (the :: causes this) and use `reply'

    "subcmd-hook" "→chroma/-git-check-if-alias"

    "subcommands-blacklist" "mv,other"

    ## }}}

    ##
    ## `FETCH'
    ##
    ## {{{

    subcmd:fetch "FETCH_MULTIPLE_0_opt^ // FETCH_ALL_0_opt^ // FETCH_0_opt //
                  REMOTE_GR_1_arg // REF_#_arg // NO_MATCH_#_opt"

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
                                        # REMOTE_GR_#_arg

    # Special options (^ - has directives - an :del-directive)
    "FETCH_ALL_0_opt^" "
                --all
                    <<>> __style=\${FAST_THEME_NAME}double-hyphen-option // NO-OP
                || --all:del
                    <<>> REMOTE_GR_1_arg // REF_#_arg" # --all can be only followed by options

    # FETCH_0_opt. FETCH-options (FETCH is an identifier) at position 0 ->
    #   -> before any argument
    FETCH_0_opt "
              (--depth=|--deepen=|--shallow-exclude=|--shallow-since=|--receive-pack=|
               --refmap=|--recurse-submodules=|-j|--jobs=|--submodule-prefix=|
               --recurse-submodules-default=|-o|--server-option=|--upload-pack|
               --negotiation-tip=)
                       <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                       <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action
           || (--help|--all|-a|--append|--unshallow|--update-shallow|--dry-run|-f|--force|
               -k|--keep|--multiple|-p|--prune|-n|--no-tags|-t|--tags|--no-recurse-submodules|
               -u|--update-head-ok|-q|--quiet|-v|--verbose|--progress|
               -4|--ipv4|-6|--ipv6)
                   <<>> __style=\${FAST_THEME_NAME}single-hyphen-option // NO-OP"
                   # Above: note the two <<>>-separated blocks for options that have
                   # some arguments – the second pair of action/handler is being
                   # run when an option argument is occurred (first one: the option
                   # itself). If there is only one <<>>-separated block, then the option
                   # is set to be argument-less. The argument is a) -o/--option argument
                   # and b) -o/--option=argument.

    REMOTE_GR_1_arg "NO-OP // ::→chroma/-git-verify-remote-or-group" # This definition is generic, reused later
    "REF_#_arg" "NO-OP // ::→chroma/-git-verify-ref" # This too
    "REMOTE_GR_#_arg" "NO-OP // ::→chroma/-git-verify-remote-or-group" # and this too
    # The hash `#' above denotes: an argument at any position
    # It will nicely match any following (above the first explicitly
    # numbered ones) arguments passed when using --multiple

    # A generic action
    NO_MATCH_\#_opt "* <<>> __style=\${FAST_THEME_NAME}incorrect-subtle // NO-OP"
    NO_MATCH_\#_arg "__style=\${FAST_THEME_NAME}incorrect-subtle // NO-OP"

    ## }}}

    ##
    ## PUSH
    ##
    ## {{{

    subcmd:push "PUSH_0_opt // REMOTE_1_arg // REF_#_arg // NO_MATCH_#_opt"

    PUSH_0_opt "
              (--receive-pack=|--exec=|--repo=|--push-option=|--signed=|
                  --force-with-lease=|--signed=|--recurse-submodules=)
                   <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                   <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action
           || (--help|--all|--mirror|--tags|--follow-tags|--atomic|-n|--dry-run|
               --porcelain|--delete|--tags|--follow-tags|--signed|--no-signed|
               --atomic|--no-atomic|-o|--push-option|--force-with-lease|
               --no-force-with-lease|-f|--force|-u|--set-upstream|--thin|
               --no-thin|-q|--quiet|-v|--verbose|--progress|--no-recurse-submodules|
               --verify|--no-verify|-4|--ipv4|-6|--ipv6)
                   <<>> __style=\${FAST_THEME_NAME}single-hyphen-option // NO-OP"

    REMOTE_1_arg "NO-OP // ::→chroma/-git-verify-remote" # This definition is generic, reused later

    ### }}}

    ##
    ## PULL
    ##
    ## {{{

    subcmd:pull "PULL_0_opt // REMOTE_1_arg // REF_#_arg // NO_MATCH_#_opt"

    PULL_0_opt "
              (--recurse-submodules=|-S|--gpg-sign=|--log=|-s|--strategy=|-X|
               --strategy-option=|--rebase=|--depth=|--deepen=|--shallow-exclude=|
               --shallow-since=|--negotiation-tip|--upload-pack|-o|--server-option=|
               --no-recurse-submodules=)
                   <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                   <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action
           || (--help|-q|--quiet|-v|--verbose|--progress|--no-recurse-submodules|
               --commit|--no-commit|--edit|--no-edit|--ff|--no-ff|--ff-only|
               --log|--no-log|--signoff|--no-signoff|--stat|-n|--no-stat|--squash|
               --no-squash|--verify-signatures|--no-verify-signatures|--summary|
               --no-summary|--allow-unrelated-histories|-r|--rebase|--no-rebase|
               --autostash|--no-autostash|--all|-a|--append|--unshallow|
               --update-shallow|-f|--force|-k|--keep|--no-tags|-u|--update-head-ok|
               --progress|-4|--ipv4|-6|--ipv6|--recurse-submodules)
                   <<>> __style=\${FAST_THEME_NAME}single-hyphen-option // NO-OP"

    ## }}}

    ##
    ## COMMIT
    ##
    ## {{{

    subcmd:commit "COMMIT_#_opt // FILE_#_arg // NO_MATCH_#_opt"

    "COMMIT_#_opt" "
              (-m|--message=|--message|-am)
                       <<>> NO-OP // ::→chroma/-git-commit-msg-opt-action
                       <<>> NO-OP // ::→chroma/-git-commit-msg-opt-ARG-action
           || (--help|-a|--all|-p|--patch|--reset-author|--short|--branch|
               --porcelain|--long|-z|--null|-s|--signoff|-n|--no-verify|
               --allow-empty|--allow-empty-message|-e|--edit|--no-edit|
               --amend|--no-post-rewrite|-i|--include|-o|--only|--untracked-files|
               -v|--verbose|-q|--quiet|--dry-run|--status|--no-status|--no-gpg-sign)
                       <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
           || (-C|--reuse-message=|-c|--reedit-message=|--fixup=|--squash=|
               -F|--file=|--author=|--date=|-t|--template=|--cleanup=|
               -u|--untracked-files=|-S|--gpg-sign=)
                       <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                       <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action"

    # A generic action
    "FILE_#_arg" "NO-OP // ::→chroma/-git-verify-file"

    ## }}}

    ##
    ## MERGE
    ##
    ## {{{

    subcmd:merge "MERGE_0_opt // COMMIT_#_arg"
    MERGE_0_opt
           "(-m)
                       <<>> NO-OP // ::→chroma/-git-commit-msg-opt-action
                       <<>> NO-OP // ::→chroma/-git-commit-msg-opt-ARG-action
            (-S|--gpg-sign=|--log=|-e|--strategy=|-X|--strategy-option=|-F|
             --file)
                       <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                       <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action
         || (--help|--commit|--no-commit|-e|--edit|--no-edit|--ff|--no-ff|--ff-only|
             --log|--no-log|--signoff|--no-signoff|-n|--stat|--no-stat|--squash|
             --no-squash|--verify-signatures|--no-verify-signatures|--summary|
             --no-summary|-q|--quiet|-v|--verbose|--progress|--no-progress|
             --allow-unrelated-histories|--rerere-autoupdate|--no-rerere-autoupdate|
             --abort|--continue)
                       <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"
    COMMIT_\#_arg "NO-OP // ::→chroma/-git-verify-commit"

    ## }}}

    ##
    ## RESET
    ##
    ## {{{

    subcmd:reset "RESET_0_opt^ // RESET_0_opt // RESET_#_arg // NO_MATCH_#_opt"
    "RESET_0_opt^" "
        (--soft|--mixed|--hard|--merge|--keep)
                    <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
     || (--soft|--mixed|--hard|--merge|--keep):del
                    <<>> RESET_0_opt // RESET_#_arg
     || (--soft|--mixed|--hard|--merge|--keep):add
                    <<>> RESET_1_arg // NO_MATCH_#_arg
        "

    RESET_0_opt "
        (-q|-p|--patch)
                    <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    RESET_1_arg "NO-OP // ::→chroma/-git-verify-commit"

    "RESET_#_arg" "NO-OP // ::→chroma/-git-RESET-verify-commit-or-file"


    ## }}}

    ##
    ## REVERT
    ##
    ## {{{

    subcmd:revert "REVERT_SEQUENCER_0_opt^ // REVERT_0_opt // REVERT_#_arg // NO_MATCH_#_opt"
    REVERT_0_opt "
                (-m|--mainline|-S|--gpg-sign=|--strategy=|-X|--strategy-option=)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action
             || (-e|--edit|--no-edit|-n|--no-commit|-s|--signoff)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    "REVERT_SEQUENCER_0_opt^" "
                (--continue|--quit|--abort)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                || (--continue|--quit|--abort):del
                        <<>> REVERT_0_opt // REVERT_#_arg
                || (--continue|--quit|--abort):add
                        <<>> NO_MATCH_#_arg"

    "REVERT_#_arg" "NO-OP // ::→chroma/-git-verify-commit"

    ## }}}

    ##
    ## DIFF
    ##
    ##  TODO: When a second argument is also a path and it points to a directory, then
    ##        git appends the previous file name to it – good to implement this too
    ## {{{

    subcmd:diff "DIFF_NO_INDEX_0_opt^ // DIFF_0_opt // COMMIT_FILE_DIR_#_arg // NO_MATCH_#_opt"

    "DIFF_NO_INDEX_0_opt^" "
                --no-index
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
             || --no-index:del
                        <<>> COMMIT_FILE_DIR_#_arg
             || --no-index:add
                        <<>> FILE_1_arg // FILE_2_arg // NO_MATCH_#_arg"
    DIFF_0_opt "
                (-U|--unified=|--anchored=|--diff-algorithm=|--stat=|--dirstat|
                 --submodule=|--color=|--color-moved=|--color-moved-ws=|--word-diff=|
                 --word-diff-regex=|--color-words=|--ws-error-highlight=|--abbrev=|
                 -B|--break-rewrites=|-M|--find-renames=|-C|--find-copies=|-l|
                 --diff-filter=|-S|-G|--find-object=|--relative=|-O|--relative=|
                 --inter-hunk-context=|--ignore-submodules=|--src-prefix=|--dst-prefix=|
                 --line-prefix=)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action
             || (-p|--patch|-u|-s|--no-patch|--raw|--patch-with-raw|--indent-heuristic|
                 --no-indent-heuristic|--minimal|--patience|--histogram|--stat|
                 --compact-summary|--numstat|--shortstat|--dirstat|--summary|
                 --patch-with-stat|-z|--name-only|--name-status|--submodule|--no-color|
                 --color-moved|--word-diff|--color-words|--no-renames|--check|
                 --full-index|--binary|--abbrev|--break-rewrites|--find-renames|
                 --find-copies|--find-copies-harder|-D|--pickaxe-all|--pickaxe-regex|
                 --irreversible-delete|-R|--relative|-a|--text|--ignore-cr-at-eol|
                 --ignore-space-at-eol|-b|--ignore-space-change|-w|--ignore-all-space|
                 --ignore-blank-lines|-W|--function-context|--exit-code|--quiet|
                 --ext-diff|--no-ext-diff|--textconv|--no-textconv|--ignore-submodules|
                 --no-prefix|--ita-invisible-in-index|-1|--base|-2|--ours|-3|--theirs|
                 -0|--cached)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    # A generic action
    "COMMIT_FILE_DIR_#_arg" "NO-OP // ::→chroma/-git-verify-commit-or-file-or-dir"

    # A generic action
    "FILE_1_arg" "NO-OP // ::→chroma/-git-verify-file"

    # A generic action
    "FILE_2_arg" "NO-OP // ::→chroma/-git-verify-file"

    ## }}}

    ##
    ## ADD
    ##
    ## {{{

    subcmd:add "ADD_0_opt // FILE_OR_DIR_#_arg // NO_MATCH_#_opt"

    ADD_0_opt "
                --chmod=
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action
             || (-v|--verbose|-f|--force|-i|--interactive|-n|--dry-run|
                 -p|--patch|-e|--edit|--all|--no-all|-A|--all|--no-all|
                 --ignore-removal|--no-ignore-removal|-u|--update|-N|
                 --intent-to-add|--refresh|--ignore-errors|--ignore-missing|
                 --renormalize|--no-warn-embedded-repo)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    FILE_OR_DIR_#_arg "NO-OP // ::→chroma/-git-verify-file-or-dir"

    ## }}}

    ##
    ## CHECKOUT
    ##
    ## {{{

    subcmd:checkout "CHECKOUT_BRANCH_0_opt^ //
                        CHECKOUT_0_opt // FILE_OR_DIR_OR_BRANCH_OR_COMMIT_1_arg // FILE_#_arg //
                        FILE_#_arg // NO_MATCH_#_opt"

    "CHECKOUT_BRANCH_0_opt^" "
                (-b|-B|--orphan)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
             || (-b|-B|--orphan):del
                        <<>> FILE_OR_DIR_OR_BRANCH_OR_COMMIT_1_arg // FILE_#_arg // FILE_#_arg
             || (-b|-B|--orphan):add
                        <<>> NEW_BRANCH_1_arg // COMMIT_2_arg // NO_MATCH_#_arg"

    NEW_BRANCH_1_arg "NO-OP // ::→chroma/-git-verify-correct-branch-name"

    COMMIT_2_arg "NO-OP // ::→chroma/-git-verify-commit"

    CHECKOUT_0_opt "
                --conflict=
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action
             || (-q|--quiet|--progress|--no-progress|-f|--force|--ours|--theirs|
                 -b|-B|-t|--track|--no-track|-l|--detach|--orphan|
                 --ignore-skip-worktree-bits|-m|--merge|-p|--patch|
                 --ignore-other-worktrees|--no-ignore-other-worktrees)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    # A generic action
    COMMIT_1_arg "NO-OP // ::→chroma/-git-verify-commit"

    # Unused
    FILE_OR_BRANCH_OR_COMMIT_1_arg "NO-OP // ::→chroma/-git-file-or-ubranch-or-commit-verify"
    FILE_OR_DIR_OR_BRANCH_OR_COMMIT_1_arg "NO-OP // ::→chroma/-git-file-or-dir-or-ubranch-or-commit-verify"

    ## }}}

    ##
    ## REMOTE
    ##
    ## {{{

    subcmd:remote "REMOTE_0_opt // REMOTE_ADD_1_arg // REMOTE_RENAME_1_arg // REMOTE_REMOVE_1_arg //
                     REMOTE_SET_HEAD_1_arg // REMOTE_SET_BRANCHES_1_arg //
                     REMOTE_GET_URL_1_arg // REMOTE_SET_URL_1_arg // REMOTE_SHOW_1_arg //
                     REMOTE_PRUNE_1_arg // REMOTE_UPDATE_1_arg"

    REMOTE_0_opt "(-v|--verbose)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    REMOTE_ADD_1_arg "add ::::: __style=${FAST_THEME_NAME}subcommand // NO-OP <<>>
                         add:REMOTE_ADD_OPTS_1_opt // REMOTE_A_NAME_2_arg //
                         REMOTE_A_URL_3_arg // NO_MATCH_#_opt // NO_MATCH_#_arg"

    REMOTE_RENAME_1_arg "rename ::::: __style=${FAST_THEME_NAME}subcommand // NO-OP <<>>
                         add:REMOTE_2_arg // REMOTE_A_NAME_3_arg // NO_MATCH_#_opt // NO_MATCH_#_arg"

    REMOTE_REMOVE_1_arg "remove ::::: __style=${FAST_THEME_NAME}subcommand // NO-OP <<>>
                         add:REMOTE_2_arg // NO_MATCH_#_opt // NO_MATCH_#_arg"

    REMOTE_SET_HEAD_1_arg "set-head ::::: __style=${FAST_THEME_NAME}subcommand // NO-OP <<>>
                         add:REMOTE_2_arg // BRANCH_3_arg //
                         REMOTE_SET_HEAD_OPTS_1_opt // REMOTE_SET_HEAD_OPTS_2_opt //
                         NO_MATCH_#_opt // NO_MATCH_#_arg"

    REMOTE_SET_BRANCHES_1_arg "set-branches ::::: __style=${FAST_THEME_NAME}subcommand // NO-OP <<>>
                         add:REMOTE_SET_BRANCHES_OPTS_1_opt // REMOTE_2_arg //
                         BRANCH_#_arg // NO_MATCH_#_opt"

    REMOTE_GET_URL_1_arg "get-url ::::: __style=${FAST_THEME_NAME}subcommand // NO-OP <<>>
                         add:REMOTE_GET_URL_OPTS_1_opt // REMOTE_2_arg //
                         NO_MATCH_#_opt // NO_MATCH_#_arg"

    REMOTE_SET_URL_1_arg "set-url ::::: __style=${FAST_THEME_NAME}subcommand // NO-OP <<>>
                         add:REMOTE_SET_URL_OPTS_1_opt^ //
                         REMOTE_2_arg // REMOTE_A_URL_3_arg // REMOTE_A_URL_4_arg //
                         NO_MATCH_#_opt // NO_MATCH_#_arg"

    REMOTE_SHOW_1_arg "show ::::: __style=${FAST_THEME_NAME}subcommand // NO-OP <<>>
                         add:REMOTE_SHOW_OPTS_1_opt // REMOTE_#_arg // NO_MATCH_#_opt"

    REMOTE_PRUNE_1_arg "prune ::::: __style=${FAST_THEME_NAME}subcommand // NO-OP <<>>
                         add:REMOTE_PRUNE_OPTS_1_opt // REMOTE_#_arg // NO_MATCH_#_opt"

    REMOTE_UPDATE_1_arg "update ::::: __style=${FAST_THEME_NAME}subcommand // NO-OP <<>>
                         add:REMOTE_UPDATE_OPTS_1_opt // REMOTE_GR_#_arg // NO_MATCH_#_opt"

    REMOTE_ADD_OPTS_1_opt "
                    (-t|-m|--mirror=)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action
                 || (-f|--tags|--no-tags)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    REMOTE_SET_HEAD_OPTS_1_opt "
                    (-a|--auto|-d|--delete)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    REMOTE_SET_HEAD_OPTS_2_opt "
                    (-a|--auto|-d|--delete)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    REMOTE_SET_BRANCHES_OPTS_1_opt "
                    --add
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    REMOTE_GET_URL_OPTS_1_opt "
                    (--push|--all)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    "REMOTE_SET_URL_OPTS_1_opt^" "
                    --push|--add|--delete
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                 || (--add|--delete):del
                        <<>> REMOTE_A_URL_4_arg"

    REMOTE_SHOW_OPTS_1_opt "
                    -n
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    REMOTE_PRUNE_OPTS_1_opt "
                    (-n|--dry-run)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    REMOTE_UPDATE_OPTS_1_opt "
                    (-p|--prune)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    REMOTE_A_NAME_2_arg "NO-OP // ::→chroma/-git-verify-correct-branch-name"
    REMOTE_A_NAME_3_arg "NO-OP // ::→chroma/-git-verify-correct-branch-name"
    REMOTE_A_URL_3_arg "NO-OP // ::→chroma/main-chroma-std-verify-url"
    REMOTE_A_URL_4_arg "NO-OP // ::→chroma/main-chroma-std-verify-url"
    BRANCH_3_arg "NO-OP // ::→chroma/-git-verify-branch"
    BRANCH_\#_arg "NO-OP // ::→chroma/-git-verify-branch"
    REMOTE_2_arg "NO-OP // ::→chroma/-git-verify-remote"
    REMOTE_\#_arg "NO-OP // ::→chroma/-git-verify-remote"

    ## }}}

    ##
    ## LOG
    ##

    subcmd:log "LOG_0_opt // LOG_1_arg // FILE_#_arg // NO_MATCH_#_opt"

    LOG_0_opt "
                (--decorate=|--decorate-refs=|--decorate-refs-exclude=|-L|-n|--max-count=|
                 --skip=|--since=|--after=|--until=|--before=|--author=|--committer=|
                 --grep-reflog=|--grep=|--min-parents=|--max-parents=|--branches=|--tags=|
                 --remotes=|--glob=|--exclude=|--no-walk=|--pretty=|--format=|--encoding=|
                 --expand-tabs=|--notes=|--show-notes=|--date=|--show-linear-break=|-U|
                 --unified=|--anchored=|--diff-algorithm=|--stat=|--dirstat=|--submodule=|
                 --color=|--color-moved=|--color-moved-ws=|--word-diff=|--word-diff-regex=|
                 --color-words=|--ws-error-highlight=|--abbrev=|-B|--break-rewrites=|-M|
                 --find-renames=|-C|--find-copies=|-l|--diff-filter=|-S|-G|--find-object=|
                 --relative=|-O|--relative=|--inter-hunk-context=|--ignore-submodules=|
                 --src-prefix=|--dst-prefix=|--line-prefix=)
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action

             || (--follow|--decorate|--no-decorate|--source|--use-mailmap|--full-diff|
                 --log-size|--all-match|--invert-grep|-i|--regexp-ignore-case|--basic-regexp|
                 -E|--extended-regexp|-F|--fixed-strings|-P|--perl-regexp|--remove-empty|
                 --merges|--no-merges|--no-min-parents|--no-max-parents|--first-parent|
                 --not|--all|--branches|--tags|--remotes|--reflog|--single-worktree|
                 --ignore-missing|--bisect|--stdin|--cherry-mark|--cherry-pick|--left-only|
                 --right-only|--cherry|-g|--walk-reflogs|--merge|--boundary|--simplify-by-decoration|
                 --full-history|--dense|--sparse|--simplify-merges|--ancestry-path|--date-order|
                 --author-date-order|--topo-order|--reverse|--no-walk|--do-walk|--pretty|
                 --abbrev-commit|--no-abbrev-commit|--oneline|--expand-tabs|--no-expand-tabs|
                 --notes|--no-notes|--show-notes|--no-standard-notes|--show-signature|
                 --relative-date|--parents|--children|--left-right|--graph|--show-linear-break|
                 -c|--cc|-m|-r|-t|-p|-u|--patch|-s|--no-patch|--raw|--patch-with-raw|
                 --indent-heuristic|--no-indent-heuristic|--minimal|--patience|--histogram|
                 --stat|--compact-summary|--numstat|--shortstat|--dirstat|--summary|
                 --patch-with-stat|-z|--name-only|--name-status|--submodule|--color|--no-color|
                 --color-moved|--word-diff|--color-words|--no-renames|--check|--full-index|
                 --binary|--abbrev|--break-rewrites|--find-renames|
                 --find-copies|--find-copies-harder|-D|--irreversible-delete|
                 --pickaxe-all|--pickaxe-regex|-R|--relative|-a|--text|--ignore-cr-at-eol|
                 --ignore-space-at-eol|-b|--ignore-space-change|-w|--ignore-all-space|
                 --ignore-blank-lines|-W|--function-context|--ext-diff|--no-ext-diff|
                 --textconv|--no-textconv|--ignore-submodules|--no-prefix|
                 --ita-invisible-in-index)
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    LOG_1_arg "NO-OP // ::→chroma/-git-verify-rev-range-or-file"

    ##
    ## TAG
    ##

    subcmd:tag "TAG_D_0_opt^ // TAG_L_0_opt^ // TAG_V_0_opt^ // TAG_0_opt^"

    "TAG_0_opt^" "
                (-u|--local-user=|--cleanup=)
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action
             || -m
                            <<>> NO-OP // ::→chroma/-git-commit-msg-opt-action
                            <<>> NO-OP // ::→chroma/-git-commit-msg-opt-ARG-action
             || (-F|--file)
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                            <<>> NO-OP // ::→chroma/-git-verify-file
             || (-a|--annotate|-s|--sign|-f|-e|--edit)
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
             || (-u|--local-user=|--cleanup=|-m|-F|--file|-a|--annotate|-s|--sign|
                 -f|-e|--edit):add
                            <<>> TAG_NEW_1_arg // COMMIT_2_arg // NO_MATCH_#_arg //
                            NO_MATCH_#_opt"

    TAG_NEW_1_arg "NO-OP // ::→chroma/-git-verify-correct-branch-name"

    TAG_1_arg "NO-OP // ::→chroma/-git-verify-tag-name"

    "TAG_D_0_opt^" "
                (-d)
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
             || -d:add
                            <<>> TAG_#_arg // NO_MATCH_#_opt
             || -d:del
                            <<>> TAG_0_opt // TAG_NEW_1_arg // COMMIT_2_arg"

    "TAG_#_arg" "NO-OP // ::→chroma/-git-verify-tag-name"

    "TAG_L_0_opt^" "
                (-l)
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
             || -l:add
                            <<>> TAG_L_0_opt // TAG_PAT_#_arg // NO_MATCH_#_opt
             || -l:del
                            <<>> TAG_0_opt // TAG_NEW_1_arg // COMMIT_2_arg"

    TAG_L_0_opt "
                (-n|--contains|--no-contains|--points-at|--column=|--sort=|--format=|
                 --color=)
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action
             || (--column|--no-column|--create-reflog|--merged|--no-merged|--color|-i)
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    "TAG_PAT_#_arg" "NO-OP // ::→chroma/main-chroma-std-verify-pattern"

    "TAG_V_0_opt^" "
                (-v)
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
             || -v:add
                            <<>> TAG_V_0_opt // TAG_#_arg // NO_MATCH_#_opt
             || -v:del
                            <<>> TAG_0_opt // TAG_NEW_1_arg // COMMIT_2_arg"

    TAG_V_0_opt "
                --format=
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action
                            <<>> NO-OP // ::→chroma/main-chroma-std-aopt-ARG-action"

    ##
    ## All remaining subcommands
    ##
    ## {{{

    "subcmd:*" "CATCH_ALL_#_opt"
    "CATCH_ALL_#_opt" "* <<>> NO-OP // ::→chroma/main-chroma-std-aopt-SEMI-action"

    ## }}}
)

# Called after entering just "git" on the command line
→chroma/-git-first-call() {
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
    FAST_HIGHLIGHT[chroma-git-reset-etc-saw-commit]=0
    FAST_HIGHLIGHT[chroma-git-reset-etc-saw-file]=0
    return 1
}

→chroma/-git-check-if-alias() {
    local _wrd="$1"
    local -a _result

    typeset -ga fsh__chroma__git__aliases
    _result=( ${(M)fsh__chroma__git__aliases[@]:#${_wrd}[[:space:]]##*} )
    →chroma/main-chroma-print "Got is-alias-_result: $_result"
    [[ -n "$_result" ]] && \
	FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]="${${${_result#* }## ##}%% *}"
}

# A hook that returns the list of git's
# available subcommands in $reply
→chroma/-git-get-subcommands() {
    local __svalue
    integer __ivalue
    LANG=C .fast-run-command "git help -a" chroma-${FAST_HIGHLIGHT[chroma-current]}-subcmd-list "" $(( 15 * 60 ))
    if [[ "${__lines_list[1]}" = See* ]]; then
        # (**)
        # git >= v2.20, the aliases in the `git help -a' command
        __lines_list=( ${${${${(M)__lines_list[@]:#([[:space:]](#c3,3)[a-zA-Z0-9_]*|Command aliases)}##[[:space:]]##}//(#s)Command\ aliases(#e)/Command_aliases}} )
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
        .fast-run-command "+git config --get-regexp 'alias.*'" chroma-${FAST_HIGHLIGHT[chroma-current]}-alias-list "[[:space:]]#alias." $(( 15 * 60 ))
    fi

    __tmp=${#__lines_list}
    typeset -ga fsh__chroma__git__aliases
    fsh__chroma__git__aliases=( ${__lines_list[__svalue+1,__tmp]} )
    [[ ${__lines_list[__svalue]} != "Command_aliases" ]] && (( ++ __svalue, __ivalue=0, 1 )) || (( __ivalue=1 ))
    __lines_list[__svalue,__tmp]=( ${(@)__lines_list[__svalue+__ivalue,__tmp]%%[[:space:]]##*} )
    reply=( "${__lines_list[@]}" )
}

# A generic handler
→chroma/-git-verify-remote() {
    local _wrd="$4"
    .fast-run-git-command "git remote" "chroma-git-remotes-$PWD" "" 10
    [[ -n ${__lines_list[(r)$_wrd]} ]] && {
        __style=${FAST_THEME_NAME}correct-subtle; return 0
    } || {
        [[ $_wrd != *:* ]] && { __style=${FAST_THEME_NAME}incorrect-subtle; return 1; }
    }
}

# A generic handler - checks if given ref is correct
→chroma/-git-verify-ref() {
    local _wrd="$4"
    _wrd="${_wrd%%:*}"
    .fast-run-git-command "git for-each-ref --format='%(refname:short)' refs/heads" "chroma-git-refs-$PWD" "refs/heads" 10
    [[ -n ${__lines_list[(r)$_wrd]} ]] && \
        { __style=${FAST_THEME_NAME}correct-subtle; return 0; } || \
        { __style=${FAST_THEME_NAME}incorrect-subtle; return 1; }
}

# A generic handler - checks if given remote or group is correct
→chroma/-git-verify-remote-or-group() {
    →chroma/-git-verify-remote "$@" && return 0
    # The check for a group is to follow below
    integer _start="$2" _end="$3"
    local _scmd="$1" _wrd="$4"
}

# A generic handler - checks whether the file exists
→chroma/-git-verify-file() {
    integer _start="$2" _end="$3" __pos __start __end
    local _wrd="$4" bg

    [[ -f $_wrd ]] && {
        (( __start=_start, __end=_end, __start >= 0 )) && \
            reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}correct-subtle]}")
        bg=${(M)FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}correct-subtle]%bg=*}
        ((1))
    } || {
        (( __start=_start, __end=_end, __start >= 0 )) && \
            reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
        bg=${(M)FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]%bg=*}
    }

    [[ -n ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path_pathseparator]} && \
        ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path]} != \
        ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path_pathseparator]}
    ]] && \
        for (( __pos = 1; __pos <= (_end-_start); __pos++ )) {
            [[ ${_wrd[__pos]} == "/" ]] && {
                [[ ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path_pathseparator]} = *bg=* ]] && {
                    (( __start=_start+__pos-__PBUFLEN, __start >= 0 )) && \
                    reply+=("$(( __start - 1 )) $__start ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path_pathseparator]}")
                    ((1))
                } || {
                    (( __start=_start+__pos-__PBUFLEN, __start >= 0 )) && \
                    reply+=("$(( __start - 1 )) $__start ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path_pathseparator]}${bg:+,$bg}")
                }
            }
        }
}

# A generic handler - checks whether the file exists
→chroma/-git-verify-file-or-dir() {
    integer _start="$2" _end="$3" __pos __start __end retval
    local _wrd="$4" bg

    __style=
    [[ -f $_wrd || -d $_wrd ]] && {
        (( __start=_start, __end=_end, __start >= 0 )) && \
            reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}correct-subtle]}")
        bg=${(M)FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}correct-subtle]%bg=*}
        ((1))
    } || {
        (( __start=_start, __end=_end, __start >= 0 )) && \
            reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
        bg=${(M)FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]%bg=*}
        retval=1
    }

    [[ -n ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path_pathseparator]} && \
        ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path]} != \
        ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path_pathseparator]}
    ]] && \
        for (( __pos = 1; __pos <= (_end-_start); __pos++ )) {
            [[ ${_wrd[__pos]} == "/" ]] && {
                [[ ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path_pathseparator]} = *bg=* ]] && {
                    (( __start=_start+__pos-__PBUFLEN, __start >= 0 )) && \
                    reply+=("$(( __start - 1 )) $__start ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path_pathseparator]}")
                    ((1))
                } || {
                    (( __start=_start+__pos-__PBUFLEN, __start >= 0 )) && \
                    reply+=("$(( __start - 1 )) $__start ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path_pathseparator]}${bg:+,$bg}")
                }
            }
        }
    return $retval
}

→chroma/-git-verify-branch() {
    local _wrd="$4"
    .fast-run-git-command "git for-each-ref --format='%(refname:short)'" "chroma-git-branches-$PWD" "refs/heads" 10
    if [[ -n ${__lines_list[(r)$_wrd]} ]] {
        __style=${FAST_THEME_NAME}correct-subtle; return 0
    } elif [[ -n ${__lines_list[(r)origin/$_wrd]} ]] {
        __style=${FAST_THEME_NAME}correct-subtle; return 0
    } else {
        __style=${FAST_THEME_NAME}incorrect-subtle; return 1
    }
}

→chroma/-git-verify-also-unfetched-ref() {
    local _wrd="$4"
    .fast-run-git-command "git config --get checkout.defaultRemote" \
                            "chroma-git-defaultRemote-$PWD" "" 10
    local remote="${__lines_list[1]:-origin}"
    .fast-run-git-command "git rev-list --count --no-walk
                            --glob=\"refs/remotes/$remote/$_wrd\"" \
                                "chroma-git-unfetched-ref-$PWD" "" 10

    (( __lines_list[1] )) && { __style=${FAST_THEME_NAME}correct-subtle; return 0; } || \
        { __style=${FAST_THEME_NAME}incorrect-subtle; return 1; }
}

# A generic handler
→chroma/-git-file-or-ubranch-or-commit-verify() {
    →chroma/-git-verify-commit "$@" && return
    →chroma/-git-verify-file "$@" && return
    →chroma/-git-verify-branch "$@" && return
    →chroma/-git-verify-also-unfetched-ref "$@"
}

# A generic handler
→chroma/-git-file-or-dir-or-ubranch-or-commit-verify() {
    →chroma/-git-verify-commit "$@" && return
    →chroma/-git-verify-file-or-dir "$@" && return
    →chroma/-git-verify-branch "$@" && return
    →chroma/-git-verify-also-unfetched-ref "$@"
}

# A generic handler
→chroma/-git-verify-correct-branch-name() {
    local _wrd="$4"
    →chroma/-git-verify-commit "$@" && \
        { __style=${FAST_THEME_NAME}incorrect-subtle; return 0; }

    →chroma/-git-verify-remote "$@" && \
        { __style=${FAST_THEME_NAME}incorrect-subtle; return 0; }

    [[ "$_wrd" != ./* && "$_wrd" != *..* && "$_wrd" != *[~\^\ $'\t']* &&
        "$_wrd" != */ && "$_wrd" != *.lock && "$_wrd" != *\\* ]] && \
        { __style=${FAST_THEME_NAME}correct-subtle; return 0; } || \
        { __style=${FAST_THEME_NAME}incorrect-subtle; return 1; }
}

# A generic handler that checks if given commit reference is correct
→chroma/-git-verify-commit() {
    local _wrd="$4"
    __lines_list=()
    .fast-run-git-command --status "git rev-parse --verify --quiet \"$_wrd\"" \
                        "chroma-git-commits-$PWD-$_wrd" "" $(( 1.5 * 60 ))
    if (( __lines_list[1] == 0 )); then
        __style=${FAST_THEME_NAME}correct-subtle
        return 0
    fi
    __style=${FAST_THEME_NAME}incorrect-subtle
    return 1
}

# A generic handler that checks if given commit reference
# is correct or if it's a file that exists
→chroma/-git-verify-commit-or-file() {
    →chroma/-git-verify-commit "$@" && return
    →chroma/-git-verify-file "$@"
}

# A generic handler that checks if given commit reference
# is correct or if it's a file or directives that exists
→chroma/-git-verify-commit-or-file-or-dir() {
    →chroma/-git-verify-commit "$@" && return
    →chroma/-git-verify-file-or-dir "$@"
}

# A generic handler that checks if given revision range
# is correct or if a file of that name exists
→chroma/-git-verify-rev-range-or-file() {
    local _wrd="$4"

    →chroma/-git-verify-commit "$@" && return 0

    if [[ "$_wrd" = *..* ]]; then
        (( FAST_HIGHLIGHT[chroma-git-reset-etc-saw-file] )) && {
            →chroma/-git-verify-file "$@" && return 0
            __style=${FAST_THEME_NAME}unknown-token
            return 1
        }

        __style=""
        return 0
    fi

    →chroma/-git-verify-file "$@" && \
        { FAST_HIGHLIGHT[chroma-git-reset-etc-saw-file]=1; return 0; }

    __style=""
    return 1
}

→chroma/-git-verify-tag-name() {
    local _wrd="$4"
    .fast-run-git-command "git tag" "chroma-git-tags-$PWD" "" $(( 2*60 ))
    [[ -n ${__lines_list[(r)$_wrd]} ]] && \
        __style=${FAST_THEME_NAME}correct-subtle || \
        __style=${FAST_THEME_NAME}incorrect-subtle
}

# A handler for the commit's -m/--message options.Currently
# does the same what →chroma/main-chroma-std-aopt-action does
→chroma/-git-commit-msg-opt-action() {
    →chroma/main-chroma-std-aopt-action "$@"
}

# A handler for the commit's -m/--message options' argument
→chroma/-git-commit-msg-opt-ARG-action() {
    integer _start="$2" _end="$3"
    local _scmd="$1" _wrd="$4"

    (( __start >= 0 )) || return

    # Match the message body in case of an --message= option
    if [[ "$_wrd" = (#b)(--message=)(*) && -n "${match[2]}" ]]; then
        _wrd="${(Q)${match[2]//\`/x}}"
        # highlight --message=>>something<<
        reply+=("$(( __start+10 )) $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}double-quoted-argument]}")
    elif [[ "$_wrd" != --message ]]; then
        # highlight the message's body
        reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}double-quoted-argument]}")
    fi

    integer length=${FAST_HIGHLIGHT[git-cmsg-len]:-50}

    if (( ${#_wrd} > length )); then
        for (( __idx1 = 1, __idx2 = 1; __idx1 <= length; ++ __idx1, ++ __idx2 )); do
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

# A RESET handler
# TODO: differentiate tree-ish from commit
→chroma/-git-RESET-verify-commit-or-file() {
    →chroma/-git-verify-commit "$@" && {
        →chroma/-git-verify-file "$@" && {
            # TODO: with -p/--patch, the <paths> are optional,
            # and this argument will be taken as a commit in a
            # specific circumstances
            FAST_HIGHLIGHT[chroma-git-reset-etc-saw-file]=1
            return 0
        }

        (( FAST_HIGHLIGHT[chroma-git-reset-etc-saw-file] ||
            FAST_HIGHLIGHT[chroma-git-reset-etc-saw-commit] )) && \
            { __style=${FAST_THEME_NAME}unknown-token; return 1; }

        FAST_HIGHLIGHT[chroma-git-reset-etc-saw-commit]=1

        __style=${FAST_THEME_NAME}correct-subtle

        return 0
    }

    →chroma/-git-verify-file "$@" && \
        { FAST_HIGHLIGHT[chroma-git-reset-etc-saw-file]=1; return 0; }

    return 1
}

return 0

# vim:ft=zsh:et:sw=4
