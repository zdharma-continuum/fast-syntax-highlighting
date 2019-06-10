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


    "subcommands" "::chroma/-git-get-subcommands.ch" # run a function (the :: causes this) and use `reply'
    #"subcommands" "(fetch|pull)" # run a function (the :: causes this) and use `reply'

    "subcmd-hook" "chroma/-git-check-if-alias.ch"

    ##
    ## `FETCH'
    ##

    "subcmd:fetch" "FETCH_MULTIPLE_0_opt^ // FETCH_ALL_0_opt^ // FETCH_0_opt // REMOTE_1_arg // REF_#_arg // FETCH_NO_MATCH_0_opt"

    # Special options (^ - has directives, currently - an :add and :del directive)
    "FETCH_MULTIPLE_0_opt^" "
                --multiple
                    <<>> __style=\${FAST_THEME_NAME}correct-subtle // ::chroma-occured-multiple-handler-function
                || --multiple:add
                    <<>> REPO_#_arg
                || --multiple:del
                    <<>> REMOTE_1_arg // REF_#_arg" # when --multiple is passed, then there is no
                                             # refspec argument, only remotes-ids follow
                                             # unlimited # of them, hence the # in D_#_arg

    # Special options (^ - has directives - an :del-directive)
    "FETCH_ALL_0_opt^" "
                --all
                    <<>> __style=\${FAST_THEME_NAME}double-hyphen-option // NO-OP 
                || --all:del
                    <<>> REMOTE_1_arg // REF_#_arg"

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
                   <<>> __style=\${FAST_THEME_NAME}correct-subtle // ::chroma-git-fetch-opt-action"
                   # Above: note the two //-separated blocks for options that have
                   # some arguments – the second pair of action/handler is being
                   # run when an option argument is occurred (first one: the option
                   # itself)

    "REMOTE_1_arg" "NO-OP // ::-chroma-git-remote-verify"
    "REF_#_arg" "NO-OP // ::-chroma-git-ref-verify"
    "REPO_#_arg" "NO-OP // ::-chroma-git-repo-verify"  # The hash `#' denotes: an argument at any position
                                                    # It will nicely match any following (above the first 2)
                                                    # arguments passed when using --multiple
    "FETCH_NO_MATCH_0_opt" "* <<>> __style=\${FAST_THEME_NAME}incorrect-subtle // NO-OP"

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

chroma/main-chroma-print() {
    (( FAST_HIGHLIGHT[DEBUG] )) && print "$@"
}

#chroma_def=( "${chroma_def_arr[@]}" )

local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"
chroma/main-chroma-print -r -- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ >> /tmp/fsh-dbg
chroma/main-chroma-print -r -- @@@@@@@ local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4" @@@@@@@ >> /tmp/fsh-dbg
local __style __entry __value __action __handler __tmp __svalue __hspaces=$'\t ' __nl=$'\n'
integer __idx1 __idx2 __start __end __ivalue __have_value=0
local -a __lines_list __avalue
local -A map
map=( "#" "_H" "^" "_D" "*" "_S" )

(( __start=_start_pos-__PBUFLEN, __end=_end_pos-__PBUFLEN ))

chroma/-git-check-if-alias.ch() {
    local __wrd="$1"
    local -a __result

    typeset -ga chroma__git__aliases
    __result=( ${(M)chroma__git__aliases[@]:#${__wrd}[[:space:]]##*} )
    chroma/main-chroma-print "Got is-alias-__result: $__result" >> /tmp/fsh-dbg
    [[ -n "$__result" ]] && \
	FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]="${${${__result#* }## ##}%% *}"
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

chroma/main-chroma-std-aopt-action() {
    integer _start="$2" _end="$3"
    local _scmd="$1" _wrd="$4"

    [[ "$_wrd" = (#b)(--[a-zA-Z0-9_-]##)=(*) ]] && {
        reply+=("$_start $(( _end - mend[2] + mbegin[2] - 1 )) ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}double-hyphen-option]}")
        reply+=("$(( _start + 1 + mend[1] )) $_end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}optarg-${${${(M)match[2]:#<->}:+number}:-string}]}")
    } || {
	[[ "$_wrd" = --* ]] && __style=${FAST_THEME_NAME}double-hyphen-option || \
	    __style=${FAST_THEME_NAME}single-hyphen-option
    }
}

chroma/main-chroma-std-aopt-ARG-action() {
    integer _start="$2" _end="$3"
    local _scmd="$1" _wrd="$4"

    [[ "$_wrd" = (#b)(--[a-zA-Z0-9_-]##)=(*) ]] && {
        reply+=("$(( _start + 1 + mend[1] )) $_end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}optarg-${${${(M)match[2]:#<->}:+number}:-string}]}")
    } || __style=${FAST_THEME_NAME}optarg-${${${(M)_wrd:#(-|)<->}:+number}:-string}
}

chroma/main-create-OPTION-hash.ch() {
    local __subcmd="$1" __option_set_id="$2" __the_hash_name="$3" __ __e __el __the_hash_name __var_name
    local -a __split __sp __s

    chroma/main-chroma-print -rl "======================" "  **## STARTING ##** chroma/main-##CREATE##-option-HASH.ch // subcmd:$__subcmd // option_set_id:$__option_set_id // h-nam:$__the_hash_name" >> /tmp/fsh-dbg
    chroma/main-chroma-print "[D] Got option-set: ${(j:,:)__option_set_id}" >> /tmp/fsh-dbg
    typeset -gA "$__the_hash_name"
    chroma/main-chroma-print "[E] __the_hash_name ${__the_hash_name}:[$__option_set_id]" >> /tmp/fsh-dbg

    # Split on ||
    __split=( "${(@s:||:)chroma_def[${__option_set_id}]}" )
    [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && __split=()
    __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )

    chroma/main-chroma-print -rl "[F] Got ||-__split: _________" ${${(@)${${__split[@]##[[:space:]]##}[@]//[${__hspaces}]##/ }[@]//[${__nl}]##/$__nl}[@]//(#s)/:::} "_________" >> /tmp/fsh-dbg
    for __el in $__split; do
        __sp=( "${(@s:<<>>:)__el}" )
        [[ ${#__sp} -eq 1 && -z "${__sp[1]}" ]] && __sp=()
        __sp=( "${__sp[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )

        chroma/main-chroma-print -l -- "Processing an ||-part - got <<>>-split: _________" "${${__sp[@]}[@]/(#s)/\\t}" "_________" >> /tmp/fsh-dbg
        __e="${__sp[1]}"
        __s=( "${(@s:|:)${${__e#\(}%\)}}" )
        [[ ${#__s} -eq 1 && -z "${__s[1]}" ]] && __s=()
        __s=( "${__s[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
        shift __sp

        for __ in $__s; do
            __=${__%\^}
            [[ "$__" = --*:(add|del) ]] && __var_name="${__the_hash_name}[${__}-directive]" || __var_name="${__the_hash_name}[${__}-opt-action]"
            chroma/main-chroma-print "${(r:55:: :):-${__var_name}} := >>${__sp[1]}${${${#__sp}:#(0|1)}:+ +}<<" >> /tmp/fsh-dbg
            : ${(P)__var_name::=${__sp[1]}${${${#__sp}:#(0|1)}:+ +}}

            if (( ${#__sp} >= 2 )); then
                __var_name="${__the_hash_name}[${__}-opt-arg-action]"
                chroma/main-chroma-print "${(r:70:: :):-${__var_name}} := >>${__sp[2]}<<}" >> /tmp/fsh-dbg
                : ${(P)__var_name::=$__sp[2]}
            fi
        done
    done
}

chroma/main-process-token.ch() {
    local __subcmd="$1" __wrd="$2" __val __var_name __main_hash_name __the_hash_name __i __size
    local -a __splitted __split __added

    chroma/main-chroma-print "\n******************* Starting chroma/main-process-token // subcmd:${(qq)__subcmd}" >> /tmp/fsh-dbg
    __main_hash_name="chroma__main__${${FAST_HIGHLIGHT[chroma-current]//[^a-zA-Z0-9_]/_}//(#b)([\#\^\*])/${map[${match[1]}]}}"
    __var_name="${__main_hash_name}[subcmd:$__subcmd]"
    __splitted=( "${(@s://:P)__var_name}" )
    [[ ${#__splitted} -eq 1 && -z "${__splitted[1]}" ]] && __splitted=()
    __splitted=( "${__splitted[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )

    chroma/main-chroma-print -rl -- "[B] MAIN-PROCESS-TOKEN: got [OPTION/ARG-**S-E-T-S**] //-splitted from subcmd:$__subcmd: ${${(j:, :)__splitted}:-EMPTY-SET!}" "//" ${${(j:, :)${__splitted[@]:#(${(~j:|:)${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-option-sets]}})}}:-EMPTY-SET!} ${${(j:, :)${=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-option-sets]}}:-EMPTY-SET!} >> /tmp/fsh-dbg

    (( ! ${#__splitted} )) && return 1

    chroma/main-chroma-print -rl -- "------------------------" >> /tmp/fsh-dbg
    chroma/main-chroma-print -rl -- "---NO-HASH-CREATE-NOW---" >> /tmp/fsh-dbg
    chroma/main-chroma-print -rl -- "------------------------" >> /tmp/fsh-dbg
    chroma/main-chroma-print -rl -- "-z OPT-WITH-ARG-ACTIVE" >> /tmp/fsh-dbg

    # Options occuring before a subcommand
    if [[ -z "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]}" ]]; then
        if [[ "$__wrd" = -* ]]; then
            chroma/main-chroma-print "1st-PATH (-z opt-with-arg-active, non-opt-arg branch, i.e. OPTION BRANCH) [#${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}]" >> /tmp/fsh-dbg
            for __val in ${__splitted[@]:#(${(~j:|:)${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-option-sets]}})} ${=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-option-sets]}; do
                [[ "${__val}" != "${__val%%_([0-9]##|\#)##*}"_${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}_opt(\*|\^|) && "${__val}" != "${__val%%_([0-9]##|\#)*}"_"#"_opt(\*|\^|) ]] && { chroma/main-chroma-print "DIDN'T MATCH $__val / arg counter:${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}" >> /tmp/fsh-dbg;  continue; } || chroma/main-chroma-print "Got candidate: $__val" >> /tmp/fsh-dbg
                # Create the hash cache-parameter if needed
                __the_hash_name="chroma__${FAST_HIGHLIGHT[chroma-current]//[^a-zA-Z0-9_]/_}__${__subcmd//[^a-zA-Z0-9_]/_}__${${__val//(#b)([\#\^\*])/${map[${match[1]}]}}//[^a-zA-Z0-9_]/_}"
                [[ "$__val" = *_opt(\*|\^|) && "${(P)+__the_hash_name}" -eq 0 ]] && chroma/main-create-OPTION-hash.ch "$__subcmd" "$__val" "$__the_hash_name" || chroma/main-chroma-print "Not creating, the hash already exists..." >> /tmp/fsh-dbg
                # Try dedicated-entry for the option
                __var_name="${__the_hash_name}[${${${${(M)__wrd#?*=}:+${__wrd%=*}=}:-$__wrd}}-opt-action]"
                __split=( "${(@s://:P)__var_name}" )
                [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && __split=()
                # If no result, then try with catch-all entry
                (( ! ${#__split} )) && {
                    chroma/main-chroma-print "% no ${(q-)${${${(M)__wrd#?*=}:+${__wrd%=*}=}:-$__wrd}}-opt-action, retrying with *-opt-action" "|__var_name|:$__var_name">> /tmp/fsh-dbg
                    __var_name="${__the_hash_name}[*-opt-action]"
                    __split=( "${(@s://:P)__var_name}" )
                    [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && __split=()
                }
                __svalue="$__var_name"
                # Remove whitespace
                __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
                chroma/main-chroma-print -l -- "\`$__val' // ${#__split} // $__wrd: (ch.run #${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr]}), deref. of \`$__var_name'" >> /tmp/fsh-dbg
                if (( ${#__split} )); then
                    chroma/main-chroma-print -l -- "Got split of {\$#__split:$#__split} ${__wrd}-opt-action or *-opt-action" "${${(q-)__split[@]}[@]/(#s)/\\t}" >> /tmp/fsh-dbg
                    if [[ "${__split[2]}" = *[[:blank:]]+ ]]; then
                        chroma/main-chroma-print "YES handling the value (the OPT.ARGUMENT)! [${__split[2]}]" >> /tmp/fsh-dbg
                        if [[ "$__wrd" = *=* ]]; then
                            chroma/main-chroma-print "The-immediate Arg-Acquiring, of option" >> /tmp/fsh-dbg
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]="${__svalue%-opt-action\]}-opt-arg-action]"
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-arg]="${__wrd#*=}"
                            __have_value=2
                        else
                            chroma/main-chroma-print "Enable Arg-Awaiting, of option" >> /tmp/fsh-dbg
                            chroma/main-chroma-print "FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]=\"${__svalue%-opt-action\]}-opt-arg-action]\"" >> /tmp/fsh-dbg
                            __have_value=0
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]="${__svalue%-opt-action\]}-opt-arg-action]"
                        fi
                    fi

                    __action="${__split[1]}"
                    __handler="${__split[2]%[[:blank:]]+}"

                    # Check for directives (like :add)
                    if [[ "$__val" = *opt\^ ]]; then
                        __var_name="${__the_hash_name}[${${${${(M)__wrd#?*=}:+${__wrd%=*}=}:-$__wrd}}:add-directive]"
                        (( ${(P)+__var_name} )) && __split=( "${(@s://:P)__var_name}" ) || __split=()
                        [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && __split[1]=()
                        __ivalue=${#__split}
                        __var_name="${__var_name%:add-*}:del-directive]"
                        (( ${(P)+__var_name} )) && __split+=( "${(@s://:P)__var_name}" )
                        [[ ${#__split} -eq $(( __ivalue + 1 )) && -z "${__split[__ivalue+1]}" ]] && __split[__ivalue+1]=()
                        __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
                        __tmp=${#__split}

                        # First: del-directive
                        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-option-sets]+="${(j: :)__split[__ivalue+1,__tmp]} "

                        chroma/main-chroma-print -rl ":add / :del directives: __ivalue:$__ivalue, THE __SPLIT[#$__tmp]: " "${__split[@]}" "//" "The FAST_HIGHLIGHT[chroma-*deleted-option-sets]: " ${=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-option-sets]} >> /tmp/fsh-dbg

                        # Second: add-directive
                        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-option-sets]+="${(j: :)__split[1,__ivalue]} "
                    fi
                    [[ "$__handler" = ::[^[:space:]]* ]] && __handler="${__handler#::}" || __handler=""
                    [[ -n "$__handler" && "$__handler" != "NO-OP" ]] && { chroma/main-chroma-print -rl -- "Running handler(1): $__handler" >> /tmp/fsh-dbg; "$__handler" "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]:-NULL}" "$__start" "$__end" "$__wrd"; }
                    [[ "$__have_value" -ne 2 && -n "$__action" && "$__action" != "NO-OP" ]] && { chroma/main-chroma-print -rl "Running action (1): $__action" >> /tmp/fsh-dbg; eval "() { $__action; }"; }
                    [[ "$__val" != *\* ]] && break
                else
                    chroma/main-chroma-print -rl -- "NO-MATCH ROUTE TAKEN" >> /tmp/fsh-dbg
                fi
            done
        else
            chroma/main-chroma-print "1st-PATH-B (-z opt-with-arg-active, non-opt-arg branch, ARGUMENT BRANCH [#${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}]) //// added-option-sets: ${=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-option-sets]}" >> /tmp/fsh-dbg
            for __val in ${__splitted[@]:#(${(~j:|:)${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-option-sets]}})} ${=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-option-sets]}; do
                [[ "${__val}" != "${__val%%_([0-9]##|\#)*}"_"${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}"_arg(\*|\^|) && "${__val}" != "${__val%%_([0-9]##|\#)*}"_"#"_arg(\*|\^|) ]] && { chroma/main-chroma-print "Continuing for $__val" >> /tmp/fsh-dbg; continue }
                # Create the hash cache-parameter if needed
                __the_hash_name="chroma__${FAST_HIGHLIGHT[chroma-current]//[^a-zA-Z0-9_]/_}__${__subcmd//[^a-zA-Z0-9_]/_}__${${__val//\#/H}//[^a-zA-Z0-9_]/_}"
                __action="" __handler=""
                chroma/main-chroma-print "A hit, chosen __val:$__val!" >> /tmp/fsh-dbg
                __split=( "${(@s://:)chroma_def[$__val]}" )
                __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
                __action="${__split[1]}"
                chroma/main-chroma-print -rl -- "Got action record for $__val, i.e. the split:" "${__split[@]}" "^^^^^^^^^^^^^^^^^^^^^" >> /tmp/fsh-dbg
                [[ "${__split[2]}" = ::[^[:space:]]* ]] && __handler="${__split[2]#::}" || { [[ "$__handler" != "NO-OP" && -n "$__handler" ]] && chroma/main-chroma-print "Error in chroma definition: a handler entry ${(q)__split[2]} without leading \`::'"; }
                [[ -n "$__handler" && "$__handler" != "NO-OP" ]] && { chroma/main-chroma-print -rl -- "Running handler(3): $__handler" >> /tmp/fsh-dbg; "$__handler" "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]:-NULL}" "$__start" "$__end" "$__wrd"; }
                [[ -n "$__action" && "$__action" != "NO-OP" ]] && { chroma/main-chroma-print -rl -- "Running action(3): $__action" >> /tmp/fsh-dbg; eval "$__action"; }
                [[ "$__val" != *\* ]] && break
            done
        fi
    else
        chroma/main-chroma-print -- "2nd-PATH (-n opt-with-arg-active) NON-EMPTY arg-active:\nThe actual opt-val <<< \$__wrd:$__wrd >>> store (after the \`Arg-Awaiting' in the chroma-run: #$(( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr]-1 )) [current: #$(( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr] ))])" >> /tmp/fsh-dbg
        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-arg]="$__wrd"
        __have_value=1
    fi

    # Execute the action if not during simulated opt-argument (--opt=...)
    chroma/main-chroma-print "** BEFORE: \`if (( __have_value ))'" >> /tmp/fsh-dbg
    if (( __have_value )); then
        chroma/main-chroma-print "In the \`if (( __have_value ))' [have_value: $__have_value]" >> /tmp/fsh-dbg
        # Split
        __var_name="${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]}"
        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]=""
        __split=( "${(@s://:P)__var_name}" )
        [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && { chroma/main-chroma-print -rl "NULL at __var_name:$__var_name" >> /tmp/fsh-dbg; __split=(); }
        __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )

        # Remember 1st level action
        (( __have_value == 2 )) && __value="$__action" || __value=""

        if (( ${#__split} )); then
            chroma/main-chroma-print -l -- "Got //-split (3, for opt-ARG-action, from [$__var_name]):" "${${(q-)__split[@]}[@]/(#s)/\\t}" >> /tmp/fsh-dbg
            __action="${__split[1]}"
            __handler="${__split[2]}"
            [[ "$__handler" = ::[^[:space:]]* ]] && __handler="${__handler#::}"

            [[ -n "$__handler" && "$__handler" != "NO-OP" ]] && { chroma/main-chroma-print -rl -- "Running handler(2): $__handler" >> /tmp/fsh-dbg; "$__handler" "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]:-NULL}" "$__start" "$__end" "$__wrd"; }
            [[ -n "$__action" && "$__action" != "NO-OP" ]] && { chroma/main-chroma-print -rl -- "Running action(2): $__action" >> /tmp/fsh-dbg; eval "$__action"; }
            chroma/main-chroma-print -rl -- "The __action value: [$__value]" >> /tmp/fsh-dbg
            [[ "$__have_value" -eq 2 && -n "$__value" && "$__value" != "NO-OP" ]] && { chroma/main-chroma-print -rl "Running action (of 1, at 2): $__value" >> /tmp/fsh-dbg; eval "$__value"; }
        fi
    fi
    chroma/main-chroma-print -- "_________ Exiting chroma/main-process-token.ch $__subcmd / $__wrd _________">> /tmp/fsh-dbg
}

chroma/-pre_process_chroma_def.ch() {
    local __key __value __ke _val __the_hash_name="$1" __var_name
    local -a __split

    chroma/main-chroma-print -rl -- "Starting PRE-PROCESS for __the_hash_name:$__the_hash_name" >> /tmp/fsh-dbg

    local __subcmds="${chroma_def[subcommands]}"
    if [[ "$__subcmds" = "::"* ]]; then
        ${__subcmds#::}
        __var_name="${__the_hash_name}[subcommands]"
        : ${(P)__var_name::=(${(j:|:)reply})}
    else
        __var_name="${__the_hash_name}[subcommands]"
        : ${(P)__var_name::=$__subcmds}
    fi
    chroma/main-chroma-print "Got SUBCOMMANDS: ${(P)__var_name}" >> /tmp/fsh-dbg

    local __subcmd_hook="${chroma_def[subcmd-hook]}"
    if [[ -n "$__subcmd_hook" ]]; then
        __var_name="${__the_hash_name}[subcmd-hook]"
        : ${(P)__var_name::=$__subcmd_hook}
    fi

    for __key in "${(@)chroma_def[(I)subcmd:*]}"; do
        __split=( "${(@s:|:)${${__key##subcmd:\((#c0,1)}%\)}}" )
        [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && __split=()
        __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
        for __ke in "${__split[@]}"; do
            __var_name="${__the_hash_name}[subcmd:$__ke]"
            : ${(P)__var_name::=${chroma_def[$__key]}}
            chroma/main-chroma-print -rl -- "Storred ${__var_name}=chroma_def[$__key], i.e. = ${chroma_def[$__key]}" >> /tmp/fsh-dbg
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
    (( 0 == ${(P)+__the_hash_name} )) && { typeset -gA "$__the_hash_name"; chroma/-pre_process_chroma_def.ch "$__the_hash_name" } || chroma/main-chroma-print "...No... [\$+var: ${(P)+__the_hash_name}]" >> /tmp/fsh-dbg
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-aliases-start-at]="-1"
    return 1
else
    (( ++ FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr] ))
    # Following call, i.e. not the first one

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    chroma/main-chroma-print "== @@ Starting @@ #${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr]} Main-Chroma-call == // << __WORD:$__wrd >> ## Subcommand: ${${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}:-NULL} //@@// -n option-with-arg-active:${(q-)FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]}" >> /tmp/fsh-dbg
    if [[ "$__wrd" = -*  || -n "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]}"
    ]]; then
        chroma/main-chroma-print "## The \`if -*' i.e. \`IF OPTION' MAIN branch" >> /tmp/fsh-dbg
        chroma/main-process-token.ch "${${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}:-NULL}" "$__wrd"
    else
        # If at e.g. '>' or destination/source spec (of the redirection)
        if (( in_redirection > 0 )); then
            return 1
        elif (( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-got-subcommand] == 0 )); then
            __the_hash_name="chroma__main__${${FAST_HIGHLIGHT[chroma-current]//[^a-zA-Z0-9_]/_}//(#b)([\#\^])/${map[${match[1]}]}}"
            __var_name="${__the_hash_name}[subcommands]"
            if [[ "$__wrd" = ${(P)~__var_name} ]]; then
                chroma/main-chroma-print "GOT-SUBCOMMAND := $__wrd, subcmd verification / OK" >> /tmp/fsh-dbg
                FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-got-subcommand]=1
                FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]="$__wrd"
		__var_name="${__the_hash_name}[subcmd-hook]"
		(( ${(P)+__var_name} )) && { chroma/main-chroma-print -r -- "Running subcmd-hook: ${(P)__var_name}" >> /tmp/fsh-dbg; "${(P)__var_name}" "$__wrd"; }
                __style="${FAST_THEME_NAME}subcommand"
            else
                chroma/main-chroma-print "subcmd verif / NOT OK; Incrementing the COUNTER-ARG ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]} -> $(( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg] + 1 ))" >> /tmp/fsh-dbg
                (( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg] += 1 ))
                chroma/main-chroma-print "UNRECOGNIZED ARGUMENT ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}" >> /tmp/fsh-dbg
            fi
            chroma/main-process-token.ch "${${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}:-NULL}" "$__wrd"
        else
            __wrd="${__wrd//\`/x}"
            __arg="${__arg//\`/x}"
            __wrd="${(Q)__wrd}"

            chroma/main-chroma-print "Incrementing the COUNTER-ARG ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]} -> $(( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg] + 1 ))" >> /tmp/fsh-dbg
            (( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg] += 1 ))
            chroma/main-chroma-print "ARGUMENT ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}" >> /tmp/fsh-dbg

            chroma/main-chroma-print "ELSE *-got-subcommand == 1 is TRUE" >>/tmp/fsh-dbg
            chroma/main-process-token.ch "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" "$__wrd"
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
