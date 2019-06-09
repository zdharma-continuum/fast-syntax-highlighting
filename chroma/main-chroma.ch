# Copyright (c) 2018 Sebastian Gniazdowski
#
# Main chroma function. It allows to create the command-dedicated chromas
# (like -git.ch) through a definition provided by `chroma_def' array (read
# from the upper scope).
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

typeset -gA chroma_def
#typeset -ga chroma_def_arr
chroma_def=(
    "subcmd:NULL" "F_0_opt // D_1_arg // D_2_arg // D_#_arg"
    "F_0_opt" "(-C|--exec-path=|--git-dir=|--work-tree=)
                   <<>> return 1 // ::-some-chroma-handler
                   <<>> print 'Im here' >> /tmp/reply // ::-std-ch-+x-dir-path-verify
            || -c
                    <<>> NO-OP // ::-chroma-git-a-handler
                    <<>> echo ABCD =========== >> /tmp/reply // ::-chroma-git-verify-config-assign
            || --namespace=
                    <<>> return 1 // NO-OP
                    <<>> echo Hello ============ >> /tmp/reply // NO-OP
            || (--version|--help|--html-path|--man-path|--info-path|-p|--paginate|--no-pager|--no-replace-objects|--bare)
                    <<>> NO-OP // NO-OP"


    "subcommands" "::chroma/-git-get-subcommands.ch" # run a function (the :: causes this) and use `reply'
    #"subcommands" "(fetch|pull)" # run a function (the :: causes this) and use `reply'

    "X_0_arg" "NO-OP // ::chroma/-git-check-if-alias.ch"

    # `fetch'
    "subcmd:fetch" "FETCH_MULTIPLE_0_opt^ // FETCH_0_opt // REMOTE_1_arg // REF_#_arg"

    # Special options (^ - has directives, currently - an :add-directive)
    "FETCH_MULTIPLE_0_opt^" "
                --multiple
                    <<>> __style=\${FAST_THEME_NAME}correct-subtle // ::chroma-occured-multiple-handler-function
                || --multiple:add
                    <<>> REPO_#_arg
                || --multiple:del
                    <<>> REMOTE_1_arg // REF_#_arg" # when --multiple is passed, then there is no
                                             # refspec argument, only remotes-ids follow
                                             # unlimited # of them, hence the # in D_#_arg

    # FETCH_0_opt. FETCH-options (FETCH is an identifier) at position 0 ->
    #   -> before any argument
    "FETCH_0_opt" "--help
                    <<>> __style=\${FAST_THEME_NAME}correct-subtle // ::chroma-occured-help-handler-function
           || (--depth=|--deepen=|--shallow-exclude=|--shallow-since=|--receive-pack=|
               --refmap=|--recurse-submodules=|-j|--jobs=|--submodule-prefix=|--upload-pack|
               --recurse-submodules-default=)
                   <<>> __style=\${FAST_THEME_NAME}correct-subtle // ::chroma-git-fetch-aopt-action
                   <<>> __style=\${FAST_THEME_NAME}correct-subtle // ::chroma-git-fetch-aopt-ARG-action"
                   # Above: note the two //-separated blocks for options that have
                   # some arguments – the second pair of action/handler is being
                   # run when an option argument is occurred (first one: the option
                   # itself)

    "REMOTE_1_arg" "NO-OP // ::-chroma-git-remote-verify"
    "REF_#_arg" "NO-OP // ::-chroma-git-ref-verify"
    "REPO_#_arg" "NO-OP // ::-chroma-git-repo-verify"  # The hash `#' denotes: an argument at any position
                                                    # It will nicely match any following (above the first 2)
                                                    # arguments passed when using --multiple

    # `push'|`pull''
    "subcmd:(push|pull|lp)" "C_0_opt // X_0_arg // C_1_arg // C_2_arg"

    "C_0_opt" "*
            <<>> return 1 // ::chroma-git-push|pull-option
                                                            
                                                            
            <<>> echo 'C_0_opt *-catch-all **with argument**' >> /tmp/reply
            // ::chroma-git-push|pull-option"  # a catch-all option entry; it thus doesn't
                                                             # verify if the option is valid (but the
                                                             # handler could be still doing this)
    "C_1_arg" "NO-OP // ::-chroma-remote-verify"
    "C_2_arg" "NO-OP // ::-chroma-ref-verify"

    # `COMMIT'
    "subcmd:commit" "Y_#_opt"
    "Y_#_opt" "(-m|--message=)
                        <<>> return 1 // ::chroma-git-aopt-action
                        <<>> return 1 // ::chroma-git-aopt-ARG-action" # The second <<>>-block enables
                                                     # the action/handler pair for an option argument
                                                     # and also in general denotes options with arguments

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

#print -rl "chroma_def_arr element count: ${#chroma_def_arr}" >> /tmp/reply
#chroma_def=( "${chroma_def_arr[@]}" )

local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"
print -r -- @@@@@@@@@@@@@@@@@@@@@@@@@@@@ "               " @@@@@@@@@@@@ >> /tmp/reply
print -r -- @@@@@@@ local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4" @@@@@@@ >> /tmp/reply
local __style __entry __value __action __handler __tmp __svalue __hspaces=$'\t ' __nl=$'\n'
integer __idx1 __idx2 __ivalue __have_value=0
local -a __lines_list chroma_git_remote_subcommands __avalue
local -A map
map=( "#" "H" "^" "D" )
chroma_git_remote_subcommands=(add rename remove set-head set-branches get-url set-url set-url set-url show prune update)

chroma/-git-check-if-alias.ch() {
    local __wrd="$1" __subcmd="$2"
    local -a __result

    typeset -ga chroma__git__aliases
    __result=( ${(M)chroma__git__aliases[@]:#${__wrd}[[:space:]]##*} )
    print "Got is-alias-__result: $__result" >> /tmp/reply
}

chroma/-git-get-subcommands.ch() {
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
    typeset -ga chroma__git__aliases
    chroma__git__aliases=( ${__lines_list[__svalue+1,__tmp]} )
    [[ ${__lines_list[__svalue]} != "Command_aliases" ]] && (( ++ __svalue, __ivalue=0, 1 )) || (( __ivalue=1 ))
    __lines_list[__svalue,__tmp]=( ${(@)__lines_list[__svalue+__ivalue,__tmp]%%[[:space:]]##*} )
    reply=( "${__lines_list[@]}" )
}

chroma/main-create-OPTION-hash.ch() {
    local __subcmd="$1" __option_set_id="$2" __the_hash_name="$3" __ __e __el __the_hash_name __var_name
    local -a __split __sp __s

    print -rl "======================" "  **## STARTING ##** chroma/main-##CREATE##-option-HASH.ch // subcmd:$__subcmd // option_set_id:$__option_set_id // h-nam:$__the_hash_name" >> /tmp/reply
    print "[D] Got option-set: ${(j:,:)__option_set_id}" >> /tmp/reply
    typeset -gA "$__the_hash_name"
    print "[E] __the_hash_name ${__the_hash_name}:[$__option_set_id]" >> /tmp/reply

    # Split on ||
    __split=( "${(@s:||:)chroma_def[${__option_set_id}]}" )
    [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && __split=()
    __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )

    print -rl "[F] Got ||-__split >>> ${(@)${${__split[@]##[[:space:]]##}[@]//[${__hspaces}]##/ }[@]//[${__nl}]##/$__nl} <<<" >> /tmp/reply
    for __el in $__split; do
        __sp=( "${(@s:<<>>:)__el}" )
        [[ ${#__sp} -eq 1 && -z "${__sp[1]}" ]] && __sp=()
        __sp=( "${__sp[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )

        print -l -- "[F2 option-hash] Got split of an ||-part:" "${${__sp[@]}[@]/(#s)/\\t}" "^^^^^^^^^^^^" >> /tmp/reply
        __e="${__sp[1]}"
        __s=( "${(@s:|:)${${__e#\(}%\)}}" )
        [[ ${#__s} -eq 1 && -z "${__s[1]}" ]] && __s=()
        __s=( "${__s[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
        shift __sp

        for __ in $__s; do
            __=${__%\^}
            [[ "$__" = --*:(add|del) ]] && __var_name="${__the_hash_name}[${__}-directive]" || __var_name="${__the_hash_name}[${__}-opt-action]"
            print "${(r:55:: :):-${__var_name}} := >>${__sp[1]}${${${#__sp}:#(0|1)}:+ +}<<" >> /tmp/reply
            : ${(P)__var_name::=${__sp[1]}${${${#__sp}:#(0|1)}:+ +}}

            if (( ${#__sp} >= 2 )); then
                __var_name="${__the_hash_name}[${__}-opt-arg-action]"
                print "${(r:55:: :):-${__var_name}} := >>${__sp[2]}<<}" >> /tmp/reply
                : ${(P)__var_name::=$__sp[2]}
            fi
        done
    done
}

chroma/main-process-token.ch() {
    local __subcmd="$1" __wrd="$2" __val __var_name __main_hash_name __the_hash_name __i __size
    local -a __splitted __split __added

    print "\n*Starting* chroma/main-process-token // subcmd:${(qq)__subcmd}" >> /tmp/reply
    __main_hash_name="chroma__main__${${FAST_HIGHLIGHT[chroma-current]//[^a-zA-Z0-9_]/_}//(#b)([\#\^])/${map[${match[1]}]}}"
    __var_name="${__main_hash_name}[subcmd:$__subcmd]"
    __splitted=( "${(@s://:P)__var_name}" )
    [[ ${#__splitted} -eq 1 && -z "${__splitted[1]}" ]] && __splitted=()
    __splitted=( "${__splitted[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )

    print -rl -- "[B] MAIN-PROCESS-TOKEN: got [OPTION/ARG-**S-E-T-S**] //-splitted from subcmd:$__subcmd: ${${(j:, :)__splitted}:-EMPTY-SET!}" "//" ${${(j:, :)${__splitted[@]:#(${(~j:|:)${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-option-sets]}})}}:-EMPTY-SET!} ${${(j:, :)${=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-option-sets]}}:-EMPTY-SET!} >> /tmp/reply

    (( ! ${#__splitted} )) && return 1

    print -rl -- "------------------------" >> /tmp/reply
    print -rl -- "---NO-HASH-CREATE-NOW---" >> /tmp/reply
    print -rl -- "------------------------" >> /tmp/reply
    print -rl -- "-z OPT-WITH-ARG-ACTIVE" >> /tmp/reply

    # Options occuring before a subcommand
    if [[ -z "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]}" ]]; then
        if [[ "$__wrd" = -* ]]; then
            print "1st-PATH (-z opt-with-arg-active, non-opt-arg branch, i.e. OPTION BRANCH) [#${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}]" >> /tmp/reply
            for __val in ${__splitted[@]:#(${(~j:|:)${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-option-sets]}})} ${=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-option-sets]}; do
                [[ "${__val}" != "${__val%%_([0-9]##|\#)##*}"_${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}_opt(\*|\^|) && "${__val}" != "${__val%%_([0-9]##|\#)*}"_"#"_opt(\*|\^|) ]] && { print "DIDN'T MATCH $__val / arg counter:${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}" >> /tmp/reply;  continue; } || print "Got candidate: $__val" >> /tmp/reply
                # Create the hash cache-parameter if needed
                __the_hash_name="chroma__${FAST_HIGHLIGHT[chroma-current]//[^a-zA-Z0-9_]/_}__${__subcmd//[^a-zA-Z0-9_]/_}__${${__val//\#/H}//[^a-zA-Z0-9_]/_}"
                [[ "$__val" = *_opt(\*|\^|) && "${(P)+__the_hash_name}" -eq 0 ]] && chroma/main-create-OPTION-hash.ch "$__subcmd" "$__val" "$__the_hash_name" || echo "[C] No..." >> /tmp/reply
                # Try dedicated-entry for the option
                __var_name="${__the_hash_name}[${${${${(M)__wrd#?*=}:+${__wrd%=*}=}:-$__wrd}}-opt-action]"
                __split=( "${(@s://:P)__var_name}" )
                [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && __split=()
                # If no result, then try with catch-all entry
                (( ! ${#__split} )) && {
                    print "% no ${(q-)${${${(M)__wrd#?*=}:+${__wrd%=*}=}:-$__wrd}}-opt-action, retrying with *-opt-action" "|__var_name|:$__var_name">> /tmp/reply
                    __var_name="${__the_hash_name}[*-opt-action]"
                    __split=( "${(@s://:P)__var_name}" )
                    [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && __split=()
                }
                __svalue="$__var_name"
                # Remove whitespace
                __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
                print -l -- "\`$__val': (ch.run #${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr]}), deref. of \`$__var_name'" >> /tmp/reply
                if (( ${#__split} )); then
                    print -l -- "Got [[main]] splitted processing of {\$#__split:$#__split/${__wrd}-opt-action or *-opt-action}" "${${(q-)__split[@]}[@]/(#s)/\\t}" >> /tmp/reply
                    if [[ "${__split[2]}" = *[[:blank:]]+ ]]; then
                        echo "YES handling the value (the OPT.ARGUMENT)! [${__split[2]}]" >> /tmp/reply
                        if [[ "$__wrd" = *=* ]]; then
                            echo "Here 5 (the-immediate Arg-Acquiring, of option)" >> /tmp/reply
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]="${__svalue%-opt-action\]}-opt-arg-action]"
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-arg]="${__wrd#*=}"
                            __have_value=2
                        else
                            echo "Here 6 (enable Arg-Awaiting, of option)" >> /tmp/reply
                            print "FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]=\"${__svalue%-opt-action\]}-opt-arg-action]\"" >> /tmp/reply
                            __have_value=0
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]="${__svalue%-opt-action\]}-opt-arg-action]"
                        fi
                    fi

                    __action="${__split[1]}"
                    __handler="${__split[2]%[[:blank:]]+}"

                    # Check for directives (like :add)
                    if [[ "$__val" = *opt\^ ]]; then
                        __var_name="${__the_hash_name}[${${${${(M)__wrd#?*=}:+${__wrd%=*}=}:-$__wrd}}:add-directive]"
                        (( ${(P)+__var_name} )) && __split=( "${(@s://:P)__var_name}" )
                        [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && __split[1]=()
                        __ivalue=${#__split}
                        __var_name="${__var_name%:add-*}:del-directive]"
                        (( ${(P)+__var_name} )) && __split+=( "${(@s://:P)__var_name}" )
                        [[ ${#__split} -eq $(( __ivalue + 1 )) && -z "${__split[__ivalue+1]}" ]] && __split[__ivalue+1]=()
                        __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
                        __tmp=${#__split}

                        # First: del-directive
                        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-option-sets]+="${(j: :)__split[__ivalue+1,__tmp]} "

                        print -rl "__ivalue:$__ivalue, THE __SPLIT[#$__tmp]: " "${__split[@]}" "//" "The FAST_HIGHLIGHT[chroma-*deleted-option-sets]: " ${=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-option-sets]} >> /tmp/reply

                        # Second: add-directive
                        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-option-sets]+="${(j: :)__split[1,__ivalue]} "
                    fi
                    [[ "$__handler" = ::[^[:space:]]* ]] && __handler="${__handler#::}" || __handler=""
                    [[ -n "$__handler" && "$__handler" != "NO-OP" ]] && { print -rl -- "Running handler(1): $__handler" >> /tmp/reply;  "$__handler"; }
                    [[ "$__have_value" -ne 2 && -n "$__action" && "$__action" != "NO-OP" ]] && { print -rl "Running action (1): $__action" >> /tmp/reply; eval "$__action"; }
                    [[ "$__val" != *\* ]] && break
                else
                    __style=${FAST_THEME_NAME}incorrect-subtle
                fi
            done
        else
            print "1st-PATH-B (-z opt-with-arg-active, non-opt-arg branch, ARGUMENT BRANCH [#${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}])" >> /tmp/reply
            for __val in ${__splitted[@]:#(${(~j:|:)${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-option-sets]}})} ${=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-option-sets]}; do
                [[ "${__val}" != "${__val%%_([0-9]##|\#)*}"_"${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}"_arg(\*|\^|) && "${__val}" != "${__val%%_([0-9]##|\#)*}"_"#"_arg(\*|\^|) ]] && { print "Continuing for $__val" >> /tmp/reply; continue }
                # Create the hash cache-parameter if needed
                __the_hash_name="chroma__${FAST_HIGHLIGHT[chroma-current]//[^a-zA-Z0-9_]/_}__${__subcmd//[^a-zA-Z0-9_]/_}__${${__val//\#/H}//[^a-zA-Z0-9_]/_}"
                __action="" __handler=""
                print "A hit, chosen __val:$__val!" >> /tmp/reply
                __split=( "${(@s://:)chroma_def[$__val]}" )
                __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
                __action="${__split[1]}"
                print -rl -- "Got action record for $__val, i.e. the split:" "${__split[@]}" "^^^^^^^^^^^^^^^^^^^^^" >> /tmp/reply
                [[ "${__split[2]}" = ::[^[:space:]]* ]] && __handler="${__split[2]#::}" || { [[ "$__handler" != "NO-OP" && -n "$__handler" ]] && print "Error in chroma definition: a handler entry ${(q)__split[2]} without leading \`::'"; }
                [[ -n "$__handler" && "$__handler" != "NO-OP" ]] && { print -rl -- "Running handler(3): $__handler" >> /tmp/reply; "$__handler" "$__wrd" "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]:-NULL}"; }
                [[ -n "$__action" && "$__action" != "NO-OP" ]] && { print -rl -- "Running action(3): $__action" >> /tmp/reply; eval "$__action"; }
                [[ "$__val" != *\* ]] && break
            done
        fi
    else
        print -- "2nd-PATH (-n opt-with-arg-active) NON-EMPTY arg-active:\nHere 7X the actual opt-val <<< \$__wrd:$__wrd >>> store (after the \`Here 6 Arg-Awaiting' in the chroma-run: #$(( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr]-1 )) [current: #$(( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr] ))])" >> /tmp/reply
        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-arg]="$__wrd"
        __have_value=1
    fi

    # Execute the action if not during simulated opt-argument (--opt=...)
    echo "Here 9 ** before: \`if (( __have_value ))'" >> /tmp/reply
    if (( __have_value )); then
        echo "Here 11 -- in the \`if (( __have_value ))' [have_value: $__have_value]" >> /tmp/reply
        # Split
        __var_name="${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]}"
        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]=""
        __split=( "${(@s://:P)__var_name}" )
        [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && { print -rl "NULL at __var_name:$__var_name" >> /tmp/reply; __split=(); }
        __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )

        # Remember 1st level action
        (( __have_value == 2 )) && __value="$__action" || __value=""

        if (( ${#__split} )); then
            print -l -- "Got //-split (3, for opt-ARG-action, from [$__var_name]):" "${${(q-)__split[@]}[@]/(#s)/\\t}" >> /tmp/reply
            __action="${__split[1]}"
            __handler="${__split[2]}"
            [[ "$__handler" = ::[^[:space:]]* ]] && __handler="${__handler#::}"

            [[ -n "$__handler" && "$__handler" != "NO-OP" ]] && { print -rl -- "Running handler(2): $__handler" >> /tmp/reply;  "$__handler"; }
            [[ -n "$__action" && "$__action" != "NO-OP" ]] && { print -rl -- "Running action(2): $__action" >> /tmp/reply; eval "$__action"; }
            print -rl -- "The __action value: [$__value]" >> /tmp/reply
            [[ "$__have_value" -eq 2 && -n "$__value" && "$__value" != "NO-OP" ]] && { print -rl "Running action (of 1, at 2): $__value" >> /tmp/reply; eval "$__value"; }
        fi
    fi
    print -- "############### Exiting chroma/main-process-token.ch $__subcmd / $__wrd ###############" >> /tmp/reply
}

chroma/-pre_process_chroma_def.ch() {
    local __key __value __ke _val __the_hash_name="$1" __var_name
    local -a __split

    print -rl -- "Starting PRE-PROCESS for __the_hash_name:$__the_hash_name" >> /tmp/reply

    local __subcmds="${chroma_def[subcommands]}"
    if [[ "$__subcmds" = "::"* ]]; then
        ${__subcmds#::}
        __var_name="${__the_hash_name}[subcommands]"
        : ${(P)__var_name::=(${(j:|:)reply})}
    else
        __var_name="${__the_hash_name}[subcommands]"
        : ${(P)__var_name::=$__subcmds}
    fi
    print "Got the SUBCOMMANDS: ${(P)__var_name}" >> /tmp/reply

    for __key in "${(@)chroma_def[(I)subcmd:*]}"; do
        __split=( "${(@s:|:)${${__key##subcmd:\((#c0,1)}%\)}}" )
        [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && __split=()
        __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
        for __ke in "${__split[@]}"; do
            __var_name="${__the_hash_name}[subcmd:$__ke]"
            : ${(P)__var_name::=${chroma_def[$__key]}}
            print -rl -- "Storred ${__var_name}=chroma_def[$__key], i.e. = ${chroma_def[$__key]}" >> /tmp/reply
        done
    done
}

if (( __first_call )); then
    FAST_HIGHLIGHT[chroma-current]="$__wrd"
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]=0
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-got-subcommand]=0
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]=""
    FAST_HIGHLIGHT[chrome-${FAST_HIGHLIGHT[chroma-current]}-occurred-double-hyphen]=0
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]=""
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-arg]=""
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr]=1
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-option-sets]=""
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-option-sets]=""
    __the_hash_name="chroma__main__${${FAST_HIGHLIGHT[chroma-current]//[^a-zA-Z0-9_]/_}//(#b)([\#\^])/${map[${match[1]}]}}"
    (( 0 == ${(P)+__the_hash_name} )) && { typeset -gA "$__the_hash_name"; chroma/-pre_process_chroma_def.ch "$__the_hash_name" } || print "...No... [\$+var: ${(P)+__the_hash_name}]" >> /tmp/reply
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-aliases-start-at]="-1"
    return 1
else
    (( ++ FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr] ))
    # Following call, i.e. not the first one

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    echo "== @@ Starting @@ #${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr]} Main-Chroma-call == // << __WORD:$__wrd >> ## GOT-SUBCOMMAND:${(qq)FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-got-subcommand]} //@@// -n option-with-arg-active:${(q-)FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]}" >> /tmp/reply
    if [[ "$__wrd" = -*  || -n "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]}"
    ]]; then
        echo "Here A ## The \`if -*' MAIN branch" >> /tmp/reply
        chroma/main-process-token.ch "${${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}:-NULL}" "$__wrd"
    else
        # If at e.g. '>' or destination/source spec (of the redirection)
        if (( in_redirection > 0 )); then
            return 1
        elif (( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-got-subcommand] == 0 )); then
            __the_hash_name="chroma__main__${${FAST_HIGHLIGHT[chroma-current]//[^a-zA-Z0-9_]/_}//(#b)([\#\^])/${map[${match[1]}]}}"
            __var_name="${__the_hash_name}[subcommands]"
            if [[ "$__wrd" = ${(P)~__var_name} ]]; then
                print "Here 16, got-subcommand := $__wrd, subcmd verification / OK" >> /tmp/reply
                FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-got-subcommand]=1
                FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]="$__wrd"
            else
                print "subcmd verif / NOT OK; Incrementing the COUNTER-ARG ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]} -> $(( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg] + 1 ))" >> /tmp/reply
                (( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg] += 1 ))
                echo "Here 14-A, ARGUMENT ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}" >> /tmp/reply
            fi
            chroma/main-process-token.ch "${${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}:-NULL}" "$__wrd"
        else
            __wrd="${__wrd//\`/x}"
            __arg="${__arg//\`/x}"
            __wrd="${(Q)__wrd}"

            print "Incrementing the COUNTER-ARG ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]} -> $(( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg] + 1 ))" >> /tmp/reply
            (( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg] += 1 ))
            echo "Here 14-B, ARGUMENT ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}" >> /tmp/reply

            print "Here 15: ELSE *-got-subcommand == 1 is TRUE" >>/tmp/reply
            chroma/main-process-token.ch "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" "$__wrd"

            if [[ -n "" ]]; then
                if [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "push" \
                    || "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "pull" \
                    || "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "fetch" ]] \
                    && (( ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-fetch-multiple]} == 0 ))
                then
                    # if not option
                    if [[ "$__wrd" != -* || "${FAST_HIGHLIGHT[chrome-${FAST_HIGHLIGHT[chroma-current]}-occurred-double-hyphen]}" -eq 1 ]]; then
                        (( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter] ))
                        if (( __idx1 == 2 )); then
                            -fast-run-${FAST_HIGHLIGHT[chroma-current]}-command "git remote" "chroma-${FAST_HIGHLIGHT[chroma-current]}-remotes" ""
                        else
                            __wrd="${__wrd%%:*}"
                            -fast-run-${FAST_HIGHLIGHT[chroma-current]}-command "git for-each-ref --format='%(refname:short)' refs/heads" "chroma-${FAST_HIGHLIGHT[chroma-current]}-branches" "refs/heads"
                        fi
                        # if remote/ref exists
                        if [[ -n ${__lines_list[(r)$__wrd]} ]]; then
                            (( __start=__start_pos-${#PREBUFFER}, __end=__start_pos+${#__wrd}-${#PREBUFFER}, __start >= 0 )) && \
                                reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}correct-subtle]}")
                        # if ref (__idx1 == 3) does not exist and subcommand is push
                        elif (( __idx1 != 2 )) && [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "push" ]]; then
                            (( __start=__start_pos-${#PREBUFFER}, __end=__start_pos+${#__wrd}-${#PREBUFFER}, __start >= 0 )) && \
                                reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
                        # if not existing remote name, because not an URL (i.e. no colon)
                        elif [[ $__idx1 -eq 2 && $__wrd != *:* ]]; then
                            (( __start=__start_pos-${#PREBUFFER}, __end=__start_pos+${#__wrd}-${#PREBUFFER}, __start >= 0 )) && \
                                reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
                        fi
                    # if option
                    else
                        if [[ "$__wrd" = "--multiple" && "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "fetch" ]]; then
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-fetch-multiple]=1
                            __style=${FAST_THEME_NAME}double-hyphen-option
                        else
                            return 1
                        fi
                    fi
                elif (( ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-fetch-multiple]} )) \
                    && [[ "$__wrd" != -* || "${FAST_HIGHLIGHT[chrome-${FAST_HIGHLIGHT[chroma-current]}-occurred-double-hyphen]}" -eq 1 ]]; then
                    -fast-run-${FAST_HIGHLIGHT[chroma-current]}-command "git remote" "chroma-${FAST_HIGHLIGHT[chroma-current]}-remotes" ""
                    if [[ -n ${__lines_list[(r)$__wrd]} ]]; then
                        __style=${FAST_THEME_NAME}correct-subtle
                    fi
                elif [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "commit" ]]; then
                    match[1]=""
                    match[2]=""
                    # if previous argument is -m or current argument is --message=something
                    if (( FAST_HIGHLIGHT[chrome-${FAST_HIGHLIGHT[chroma-current]}-got-msg1] == 1 )) \
                        || [[ "$__wrd" = (#b)(--message=)(*) && "${FAST_HIGHLIGHT[chrome-${FAST_HIGHLIGHT[chroma-current]}-occurred-double-hyphen]}" = 0 ]]; then
                        FAST_HIGHLIGHT[chrome-${FAST_HIGHLIGHT[chroma-current]}-got-msg1]=0
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
                        if (( ${#__wrd} > 50 )); then
                            for (( __idx1 = 1, __idx2 = 1; __idx1 <= 50; ++ __idx1, ++ __idx2 )); do
                                while [[ "${__arg[__idx2]}" != "${__wrd[__idx1]}" ]]; do
                                    (( ++ __idx2 ))
                                    (( __idx2 > __asize )) && { __idx2=-1; break; }
                                done
                                (( __idx2 == -1 )) && break
                            done
                            if (( __idx2 != -1 )); then
                                if [[ -n "${match[1]}" ]]; then
                                    (( __start=__start_pos-${#PREBUFFER}+__idx2, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && \
                                        reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
                                else
                                    (( __start=__start_pos-${#PREBUFFER}+__idx2-1, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && \
                                        reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
                                fi
                            fi
                        fi
                    # if before --
                    elif [[ "${FAST_HIGHLIGHT[chrome-${FAST_HIGHLIGHT[chroma-current]}-occurred-double-hyphen]}" = 0 ]]; then
                        if [[ "$__wrd" = "-m" ]]; then
                            FAST_HIGHLIGHT[chrome-${FAST_HIGHLIGHT[chroma-current]}-got-msg1]=1
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
                elif [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "checkout" ]] \
                    || [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "revert" ]] \
                    || [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "merge" ]] \
                    || [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "diff" ]] \
                    || [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "reset" ]] \
                    || [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "rebase" ]]; then

                    # if doing `git checkout -b ...'
                    if [[ "$__wrd" = "-b" && "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "checkout" ]]; then
                        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-checkout-new]=1
                        __style=${FAST_THEME_NAME}single-hyphen-option
                    # if command is not checkout -b something
                    elif [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-checkout-new]}" = 0 ]]; then
                        # if not option
                        if [[ "$__wrd" != -* || "${FAST_HIGHLIGHT[chrome-${FAST_HIGHLIGHT[chroma-current]}-occurred-double-hyphen]}" = 1 ]]; then
                            (( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter] ))
                            if (( __idx1 == 2 )) || \
                                [[ "$__idx1" = 3 && "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "diff" ]]; then
                                # if is ref
                                if command git rev-parse --verify --quiet "$__wrd" >/dev/null 2>&1; then
                                    __style=${FAST_THEME_NAME}correct-subtle
                                # if is file and subcommand is checkout or diff
                                elif [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "checkout" \
                                    || "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "reset" \
                                    || "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "diff" ]] && [[ -e ${~__wrd} ]]; then
                                    __style=${FAST_THEME_NAME}path
                                elif [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "checkout" && \
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
                    elif [[ "${FAST_HIGHLIGHT[chrome-${FAST_HIGHLIGHT[chroma-current]}-occurred-double-hyphen]}" = 0 && "$__wrd" = -* ]]; then
                        return 1
                    fi
                elif [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "remote" && "$__wrd" != -* ]]; then
                    (( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter] ))
                    if [[ "$__idx1" = 2 ]]; then
                        if (( ${chroma_git_remote_subcommands[(I)$__wrd]} )); then
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-remote-subcommand]="$__wrd"
                            __style=${FAST_THEME_NAME}subcommand
                        else
                            __style=${FAST_THEME_NAME}incorrect-subtle
                        fi
                    elif [[ "$__idx1" = 3 && "$FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-remote-subcommand]" = "add" ]]; then
                        -fast-run-${FAST_HIGHLIGHT[chroma-current]}-command "git remote" "chroma-${FAST_HIGHLIGHT[chroma-current]}-remotes" ""
                        if [[ -n ${__lines_list[(r)$__wrd]} ]]; then
                            __style=${FAST_THEME_NAME}incorrect-subtle
                        fi
                    elif [[ "$__idx1" = 3 && -n "$FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-remote-subcommand]" ]]; then
                        -fast-run-${FAST_HIGHLIGHT[chroma-current]}-command "git remote" "chroma-${FAST_HIGHLIGHT[chroma-current]}-remotes" ""
                        if [[ -n ${__lines_list[(r)$__wrd]} ]]; then
                            __style=${FAST_THEME_NAME}correct-subtle
                        else
                            __style=${FAST_THEME_NAME}incorrect-subtle
                        fi
                    fi
                elif [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "branch" ]]; then
                    if [[ "$__wrd" = --delete \
                        ||  "$__wrd" = --edit-description \
                        ||  "$__wrd" = --set-upstream-to=* \
                        ||  "$__wrd" = --unset-upstream \
                        ||  "$__wrd" = -d \
                        ||  "$__wrd" = -D ]]; then
                        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-branch-change]=1
                        return 1
                    elif [[ "$__wrd" != -* ]]; then
                        -fast-run-${FAST_HIGHLIGHT[chroma-current]}-command "git for-each-ref --format='%(refname:short)' refs/heads" "chroma-${FAST_HIGHLIGHT[chroma-current]}-branches" "refs/heads"
                        if [[ -n ${__lines_list[(r)$__wrd]} ]]; then
                            __style=${FAST_THEME_NAME}correct-subtle
                        elif (( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-branch-change] )); then
                            __style=${FAST_THEME_NAME}incorrect-subtle
                        fi
                    else
                        return 1
                    fi
                elif [[ "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" = "tag" ]]; then
                    if [[ -z "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]}" ]]; then
                        if [[ "$__wrd" = (-u|-m) ]]; then
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]="$__wrd"
                        elif [[ "$__wrd" = "-F" ]]; then
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]="$__wrd"
                        elif [[ "$__wrd" = "-d" ]]; then
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]="$__wrd"
                        elif [[ "$__wrd" = (--contains|--no-contains|--points-at|--merged|--no-merged) ]]; then
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]="$__wrd"
                        fi
                        if [[ "$__wrd" != -* ]]; then
                            (( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter] ))
                            if [[ ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter]} -eq 2 ]]; then
                                -fast-run-${FAST_HIGHLIGHT[chroma-current]}-command "git for-each-ref --format='%(refname:short)' refs/heads" "chroma-${FAST_HIGHLIGHT[chroma-current]}-branches" "refs/heads"
                                -fast-run-${FAST_HIGHLIGHT[chroma-current]}-command "+git tag" "chroma-${FAST_HIGHLIGHT[chroma-current]}-tags" ""
                                [[ -n ${__lines_list[(r)$__wrd]} ]] && __style=${FAST_THEME_NAME}incorrect-subtle
                            elif [[ ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter]} -eq 3 ]]; then
                            fi
                        else
                            return 1
                        fi
                    else
                        case "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]}" in
                            (-u|-m)
                                __style=${FAST_THEME_NAME}optarg-string
                                ;;
                            (-F)
                                FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]=""
                                return 1;
                                ;;
                            (-d)
                                -fast-run-${FAST_HIGHLIGHT[chroma-current]}-command "git tag" "chroma-${FAST_HIGHLIGHT[chroma-current]}-tags" ""
                                [[ -n ${__lines_list[(r)$__wrd]} ]] && \
                                    __style=${FAST_THEME_NAME}correct-subtle || \
                                    __style=${FAST_THEME_NAME}incorrect-subtle
                                ;;
                            (--contains|--no-contains|--points-at|--merged|--no-merged)
                                if git rev-parse --verify --quiet "$__wrd" >/dev/null 2>&1; then
                                    __style=${FAST_THEME_NAME}correct-subtle
                                else
                                    __style=${FAST_THEME_NAME}incorrect-subtle
                                fi
                                ;;
                        esac
                        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]=""
                    fi
                else
                    return 1
                fi
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
