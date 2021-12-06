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

→chroma/main-chroma-print() {
    (( FAST_HIGHLIGHT[DEBUG] )) && print "$@" >> /tmp/fsh-dbg
}

local __chroma_name="${1#\%}" __first_call="$2" __wrd="$3" __start_pos="$4" __end_pos="$5"

# Not a well formed chroma name
[[ -z "$__chroma_name" ]] && return 1

# Load the fsh_{name-of-the-chroma}_chroma_def array
(( !FAST_HIGHLIGHT[-${__chroma_name}.ch-chroma-def] )) && →chroma/-${__chroma_name}.ch

→chroma/main-chroma-print -r -- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
→chroma/main-chroma-print -r -- @@@@@@@  local __chroma_name="${1#\%}" __first_call="$2" __wrd="$3" __start_pos="$4" __end_pos="$5" @@@@@@@
local __style __entry __value __action __handler __tmp __svalue __hspaces=$'\t ' __nl=$'\n' __ch_def_name
integer __idx1 __idx2 __start __end __ivalue __have_value=0
local -a __lines_list __avalue
local -A map
map=( "#" "_H" "^" "_D" "*" "_S" )

(( __start=_start_pos-__PBUFLEN, __end=_end_pos-__PBUFLEN ))

# Handler that highlights the options
→chroma/main-chroma-std-aopt-action() {
    integer _start="$2" _end="$3"
    local _scmd="$1" _wrd="$4"

    [[ "$_wrd" = (#b)(--[a-zA-Z0-9_-]##)=(*) ]] && {
        reply+=("$_start $(( _end - mend[2] + mbegin[2] - 1 )) ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}double-hyphen-option]}")
    } || {
	[[ "$_wrd" = --* ]] && __style=${FAST_THEME_NAME}double-hyphen-option || \
	    __style=${FAST_THEME_NAME}single-hyphen-option
    }
}

# Handler that highlights the options' arguments
→chroma/main-chroma-std-aopt-ARG-action() {
    integer _start="$2" _end="$3"
    local _scmd="$1" _wrd="$4"

    [[ "$_wrd" = (#b)(--[a-zA-Z0-9_-]##)=(*) ]] && {
        reply+=("$(( _start + 1 + mend[1] )) $_end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}optarg-${${${(M)match[2]:#<->}:+number}:-string}]}")
    } || __style=${FAST_THEME_NAME}optarg-${${${(M)_wrd:#(-|)<->}:+number}:-string}
}

# This handler also highlights explicit arguments, i.e. --opt=the-explicit-arg
→chroma/main-chroma-std-aopt-SEMI-action() {
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

# A handler which verifies the token as an GIT url
→chroma/main-chroma-std-verify-url() {
    setopt localoptions extendedglob
    local _wrd="$4"
    integer url_correct=0
    # Correct matches
    # Correct matches
    if [[ "$_wrd" = (#b)(git|http|https|ftp|ftps|file)://([a-zA-Z0-9._~-]##)(:[0-9]##)(#c0,1)(/([a-zA-Z0-9./_~:-]##))(#c0,1) ]]; then
        url_correct=1
    elif [[ "$_wrd" = (#b)rsync://([a-zA-Z0-9._~-]##)(/([a-zA-Z0-9./_~:-]##))(#c0,1) ]]; then
        url_correct=1
    elif [[ "$_wrd" = (#b)ssh://([a-zA-Z0-9._~-]##@)(#c0,1)([a-zA-Z0-9._~-]##)(:[0-9]##)(#c0,1)(/([a-zA-Z0-9./_~:-]##))(#c0,1) ]]; then
        url_correct=1
    elif [[ "$_wrd" = (#b)([a-zA-Z0-9._~-]##@)(#c0,1)([a-zA-Z0-9._~-]##):([a-zA-Z0-9./_~:-](#c0,1)[a-zA-Z0-9._~:-][a-zA-Z0-9./_~:-]#)(#c0,1) ]]; then
        url_correct=1
    elif [[ "$_wrd" = (#b)[[:alnum:]/_~:.-]## ]]; then
        url_correct=1
    fi

    (( url_correct )) && \
        { __style=${FAST_THEME_NAME}correct-subtle; return 0; } || \
        { __style=${FAST_THEME_NAME}incorrect-subtle; return 1; }
}

# A handler which verifies the token as a shell wildcard
→chroma/main-chroma-std-verify-pattern() {
    setopt localoptions extendedglob
    local _wrd="$4"
    __style=${FAST_THEME_NAME}globbing-ext
}

# Creates a hash table for given option set (an *_opt field in the chroma def.)
→chroma/main-create-OPTION-hash.ch() {
    local __subcmd="$1" __option_set_id="$2" __the_hash_name="$3" __ __e __el __the_hash_name __var_name
    local -a __split __sp __s

    →chroma/main-chroma-print -rl "======================" "  **## STARTING ##** →chroma/main-##CREATE##-option-HASH.ch // subcmd:$__subcmd // option_set_id:$__option_set_id // h-nam:$__the_hash_name"
    →chroma/main-chroma-print "[D] Got option-set: ${(j:,:)__option_set_id}"
    typeset -gA "$__the_hash_name"
    →chroma/main-chroma-print "[E] __the_hash_name ${__the_hash_name}:[$__option_set_id]"

    # Split on ||
    __ch_def_name="fsh__${__chroma_name}__chroma__def[${__option_set_id}]"
    __split=( "${(P@s:||:)__ch_def_name}" )
    [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && __split=()
    # Remove only leading and trailing whitespace
    __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )

    →chroma/main-chroma-print -rl "[F] Got ||-__split: _________" ${${(@)${${__split[@]##[[:space:]]##}[@]//[${__hspaces}]##/ }[@]//[${__nl}]##/$__nl}[@]//(#s)/:::} "_________"
    for __el in $__split; do
        __sp=( "${(@s:<<>>:)__el}" )
        [[ ${#__sp} -eq 1 && -z "${__sp[1]}" ]] && __sp=()
        __sp=( "${__sp[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )

        →chroma/main-chroma-print -l -- "Processing an ||-part - got <<>>-split: _________" "${${__sp[@]}[@]/(#s)/-\\t}" "_________"
        __e="${__sp[1]}"
        local __e1=${${__e#\(}%\)(:add|:del|)}
        local __e2=${(M)__e##\(*\)(:add|:del)}
        # Split on | with the ( and ) and :add/:del stripped and then append
        # the :add or :del depending on what's on the input line
        __s=()
        for __ in ${(@s:|:)__e1}; do
            __s+=( $__${__e2:+${(M)__e%(:add|:del)}} )
        done
        [[ ${#__s} -eq 1 && -z "${__s[1]}" ]] && __s=()
        __s=( "${__s[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
        shift __sp

        for __ in $__s; do
            __=${__%\^}
            [[ "$__" = -*:(add|del) ]] && __var_name="${__the_hash_name}[${__}-directive]" || __var_name="${__the_hash_name}[${__}-opt-action]"
            →chroma/main-chroma-print "${(r:70:: :):-${__var_name}} := >>${__sp[1]}${${${#__sp}:#(0|1)}:+ +}<<"
            : ${(P)__var_name::=${__sp[1]}${${${#__sp}:#(0|1)}:+ +}}

            if (( ${#__sp} >= 2 )); then
                __var_name="${__the_hash_name}[${__}-opt-arg-action]"
                →chroma/main-chroma-print "${(r:70:: :):-${__var_name}} := >>${__sp[2]}<<}"
                : ${(P)__var_name::=$__sp[2]}
            fi
        done
    done
}

# Processes given token
→chroma/main-process-token.ch() {
    local __subcmd="$1" __wrd="$2" __val __var_name __main_hash_name __the_hash_name __i __size
    local -a __splitted __split __added

    →chroma/main-chroma-print "\n******************* Starting →chroma/main-process-token <<$__wrd>>// subcmd:${(qq)__subcmd}"
    __main_hash_name="fsh__chroma__main__${${FAST_HIGHLIGHT[chroma-current]//[^a-zA-Z0-9_]/_}//(#b)([\#\^\*])/${map[${match[1]}]}}"
    __var_name="${__main_hash_name}[subcmd:$__subcmd]"
    __splitted=( "${(@s://:P)__var_name}" )
    [[ ${#__splitted} -eq 1 && -z "${__splitted[1]}" ]] && __splitted=()
    __splitted=( "${__splitted[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )

    →chroma/main-chroma-print -rl -- "[B] MAIN-PROCESS-TOKEN: got [OPTION/ARG-**S-E-T-S**] //-splitted from subcmd:$__subcmd: ${${(j:, :)__splitted}:-EMPTY-SET!}" "----- __splitted\\Deleted: -----" ${${(j:, :)${__splitted[@]:#(${(~j:|:)${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-nodes]}})}}:-EMPTY-SET (deleted)!} "----- Added\\Deleted: -----" ${${(j:, :)${${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-nodes]}:#(${(~j:|:)${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-nodes]}})}}:-EMPTY-SET (added)!} -----\ Deleted:\ ----- ${(j:, :)${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-nodes]}} >> /tmp/reply

    (( ! ${#__splitted} )) && {
        __var_name="${__main_hash_name}[subcmd:*]"
        __splitted=( "${(@s://:P)__var_name}" )
        [[ ${#__splitted} -eq 1 && -z "${__splitted[1]}" ]] && __splitted=()
        __splitted=( "${__splitted[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
       (( ! ${#__splitted} )) && return 1
    }

    →chroma/main-chroma-print -rl -- "---NO-HASH-CREATE-FROM-NOW-ON---"

    if [[ -z "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]}" ]]; then
        →chroma/main-chroma-print -rl -- "-z OPT-WITH-ARG-ACTIVE == true"
        if [[ "$__wrd" = -* ]]; then
            →chroma/main-chroma-print "1st-PATH (-z opt-with-arg-active, non-opt-arg branch, i.e. OPTION BRANCH) [#${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}]"
            for __val in ${__splitted[@]:#(${(~j:|:)${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-nodes]}})} ${${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-nodes]}:#(${(~j:|:)${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-nodes]}})}; do
                [[ "${__val}" != "${__val%%_([0-9]##|\#)##*}"_${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}_opt(\*|\^|) && "${__val}" != "${__val%%_([0-9]##|\#)*}"_"#"_opt(\*|\^|) ]] && { →chroma/main-chroma-print "DIDN'T MATCH $__val / arg counter:${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}" ;  continue; } || →chroma/main-chroma-print "Got candidate: $__val"
                # Create the hash cache-parameter if needed
                __the_hash_name="fsh__chroma__${FAST_HIGHLIGHT[chroma-current]//[^a-zA-Z0-9_]/_}__${__subcmd//[^a-zA-Z0-9_]/_}__${${__val//(#b)([\#\^\*])/${map[${match[1]}]}}//[^a-zA-Z0-9_]/_}"
                [[ "$__val" = *_opt(\*|\^|) && "${(P)+__the_hash_name}" -eq 0 ]] && →chroma/main-create-OPTION-hash.ch "$__subcmd" "$__val" "$__the_hash_name" || →chroma/main-chroma-print "Not creating, the hash already exists..."
                # Try dedicated-entry for the option
                __var_name="${__the_hash_name}[${${${${(M)__wrd#?*=}:+${__wrd%=*}=}:-$__wrd}}-opt-action]"
                __split=( "${(@s://:P)__var_name}" )
                [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && __split=()
                # If no result, then try with catch-all entry
                (( ! ${#__split} )) && {
                    →chroma/main-chroma-print "% no ${(q-)${${${(M)__wrd#?*=}:+${__wrd%=*}=}:-$__wrd}}-opt-action, retrying with *-opt-action" "|__var_name|:$__var_name"
                    __var_name="${__the_hash_name}[*-opt-action]"
                    __split=( "${(@s://:P)__var_name}" )
                    [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && __split=()
                }
                __svalue="$__var_name"
                # Remove whitespace
                __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
                →chroma/main-chroma-print -l -- "\`$__val' // ${#__split} // $__wrd: (ch.run #${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr]}), deref. of \`$__var_name'"
                if (( ${#__split} )); then
                    →chroma/main-chroma-print -l -- "Got split of {\$#__split:$#__split} ${__wrd}-opt-action or *-opt-action" "${${(q-)__split[@]}[@]/(#s)/->\\t}"
                    if [[ "${__split[2]}" = *[[:blank:]]+ ]]; then
                        →chroma/main-chroma-print "YES handling the value (the OPT.ARGUMENT)! [${__split[2]}]"
                        if [[ "$__wrd" = *=* ]]; then
                            →chroma/main-chroma-print "The-immediate Arg-Acquiring, of option"
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]="${__svalue%-opt-action\]}-opt-arg-action]"
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-arg]="${__wrd#*=}"
                            __have_value=2
                        else
                            →chroma/main-chroma-print "Enable Arg-Awaiting, of option"
                            →chroma/main-chroma-print "FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]=\"${__svalue%-opt-action\]}-opt-arg-action]\""
                            __have_value=0
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]="${__svalue%-opt-action\]}-opt-arg-action]"
                        fi
                    fi

                    __action="${__split[1]}"
                    __handler="${__split[2]%[[:blank:]]+}"

                    # Check for directives (like :add)
                    if [[ "$__val" = *_opt\^ ]]; then
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
                        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-nodes]+="${(j: :)__split[__ivalue+1,__tmp]} "

                        →chroma/main-chroma-print -rl ":add / :del directives: __ivalue:$__ivalue, THE __SPLIT[#$__tmp]: " "${__split[@]}" "//" "The FAST_HIGHLIGHT[chroma-*deleted-nodes]: " ${=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-nodes]} >> /tmp/reply

                        # Second: add-directive
                        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-nodes]+="${(j: :)__split[1,__ivalue]} "
                    fi
                    [[ "$__handler" = ::[^[:space:]]* ]] && __handler="${__handler#::}" || __handler=""
                    [[ -n "$__handler" && "$__handler" != "NO-OP" ]] && { →chroma/main-chroma-print -rl -- "Running handler(1): $__handler" ; "$__handler" "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]:-NULL}" "$__start" "$__end" "$__wrd"; }
                    [[ "$__have_value" -ne 2 && -n "$__action" && "$__action" != "NO-OP" ]] && { →chroma/main-chroma-print -rl "Running action (1): $__action" ; eval "() { $__action; }"; }
                    [[ "$__val" != *\* ]] && break
                else
                    →chroma/main-chroma-print -rl -- "NO-MATCH ROUTE TAKEN"
                fi
            done
        else
            →chroma/main-chroma-print "1st-PATH-B (-z opt-with-arg-active, non-opt-arg branch, ARGUMENT BRANCH [#${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}]) //// added-nodes: ${=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-nodes]}"
            for __val in ${__splitted[@]:#(${(~j:|:)${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-nodes]}})} ${${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-nodes]}:#(${(~j:|:)${(@)=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-nodes]}})}; do
                [[ "${__val}" != "${__val%%_([0-9]##|\#)*}"_"${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}"_arg(\*|\^|) && "${__val}" != "${__val%%_([0-9]##|\#)*}"_"#"_arg(\*|\^|) ]] && { →chroma/main-chroma-print "Continuing for $__val / arg counter ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}" ; continue }
                # Create the hash cache-parameter if needed
                __the_hash_name="fsh__chroma__${FAST_HIGHLIGHT[chroma-current]//[^a-zA-Z0-9_]/_}__${__subcmd//[^a-zA-Z0-9_]/_}__${${__val//\#/H}//[^a-zA-Z0-9_]/_}"
                __action="" __handler=""
                →chroma/main-chroma-print "A hit, chosen __val:$__val!"
                __ch_def_name="fsh__${__chroma_name}__chroma__def[$__val]"
                __split=( "${(P@s:<<>>:)__ch_def_name}" )
                __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )

                __sp=( "${(@s://:)__split[1]}" )
                __sp=( "${__sp[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
                __action="${__sp[1]#*::::: ##}"

                # Verify if it's the expected argument
                [[ "${__sp[1]}" = *:::::* && "$__wrd" != ${~${__sp[1]%% ##:::::*}} ]] && \
                    { →chroma/main-chroma-print -r "mismatch ${__sp[1]%% ##:::::*} != $__wrd, continuing" ; continue; }

                →chroma/main-chroma-print -l -- "Got action record for $__val, i.e. the split:" "${__sp[@]//(#s)/-\t}" "_________"

                [[ "${__sp[2]}" = ::[^[:space:]]* ]] && __handler="${__sp[2]#::}" || { [[ -n "$__handler" && "$__handler" != "NO-OP" ]] && →chroma/main-chroma-print "=== Error === In chroma definition: a handler entry ${(q)__sp[2]} without leading \`::'" ; }
                [[ -n "$__handler" && "$__handler" != "NO-OP" ]] && { →chroma/main-chroma-print -rl -- "Running handler(3): $__handler" ; "$__handler" "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]:-NULL}" "$__start" "$__end" "$__wrd"; }
                [[ -n "$__action" && "$__action" != "NO-OP" ]] && { →chroma/main-chroma-print -rl -- "Running action(3): $__action" ; eval "() { $__action; } \"${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]:-NULL}\" \"$__start\" \"$__end\" \"$__wrd\""; }

                # Check for argument directives (like :add)
                if (( ${#__split} >= 2 )); then
                    for __ in "${(@)__split[2,-1]}"; do
                        __splitted=( "${(@s://:)__}" )
                        if [[ "${__splitted[1]}" = add:* ]]; then
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-nodes]+="${__splitted[1]#add:} ${(j: :)__splitted[2,-1]} "
                        elif [[ "${__splitted[1]}" = del:* ]]; then
                            FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-nodes]+="${__splitted[1]#del:} ${(j: :)__splitted[2,-1]} "
                        fi
                    done
                    →chroma/main-chroma-print -l "ARGUMENT :add / :del directives: THE __SPLIT[#${#__split}]: " "${__split[@]//(#s)/-\\t}" "//" "The FAST_HIGHLIGHT[chroma-*deleted-nodes]: " ${(@)${=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-nodes]}//(#s)/-\\t} "The FAST_HIGHLIGHT[chroma-*added-nodes]: " ${(@)${=FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-nodes]}//(#s)/-\\t}
                fi

                [[ "$__val" != *\* ]] && break
            done
        fi
    else
        →chroma/main-chroma-print -- "2nd-PATH (-n opt-with-arg-active) NON-EMPTY arg-active:\nThe actual opt-val <<< \$__wrd:$__wrd >>> store (after the \`Arg-Awaiting' in the chroma-run: #$(( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr]-1 )) [current: #$(( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr] ))])"
        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-arg]="$__wrd"
        __have_value=1
    fi

    # Execute the action if not during simulated opt-argument (--opt=...)
    →chroma/main-chroma-print "** BEFORE: \`if (( __have_value ))'"
    if (( __have_value )); then
        →chroma/main-chroma-print "In the \`if (( __have_value ))' [have_value: $__have_value]"
        # Split
        __var_name="${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]}"
        FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]=""
        __split=( "${(@s://:P)__var_name}" )
        [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && { →chroma/main-chroma-print -rl "NULL at __var_name:$__var_name" ; __split=(); }
        __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )

        # Remember 1st level action
        (( __have_value == 2 )) && __value="$__action" || __value=""

        if (( ${#__split} )); then
            →chroma/main-chroma-print -l -- "Got //-split (3, for opt-ARG-action, from [$__var_name]):" "${${(q-)__split[@]}[@]/(#s)/+\\t}"
            __action="${__split[1]}"
            __handler="${__split[2]}"
            [[ "$__handler" = ::[^[:space:]]* ]] && __handler="${__handler#::}"

            [[ -n "$__handler" && "$__handler" != "NO-OP" ]] && { →chroma/main-chroma-print -rl -- "Running handler(2): $__handler" ; "$__handler" "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]:-NULL}" "$__start" "$__end" "$__wrd"; }
            [[ -n "$__action" && "$__action" != "NO-OP" ]] && { →chroma/main-chroma-print -rl -- "Running action(2): $__action" ; eval "$__action"; }
            →chroma/main-chroma-print -rl -- "The __action value: [$__value]"
            [[ "$__have_value" -eq 2 && -n "$__value" && "$__value" != "NO-OP" ]] && { →chroma/main-chroma-print -rl "Running action (of 1, at 2): $__value" ; eval "$__value"; }
        fi
    fi
    →chroma/main-chroma-print -- "_________ Exiting →chroma/main-process-token.ch $__subcmd / $__wrd _________"
}

# Iterates over the chroma def. fields and creates initial
# fields in the fsh__${__chroma_name}__chroma__def hash
→chroma/-pre_process_chroma_def.ch() {
    local __key __value __ke _val __the_hash_name="$1" __var_name
    local -a __split

    →chroma/main-chroma-print -rl -- "Starting PRE_PROCESS for __the_hash_name:$__the_hash_name"

    __ch_def_name="fsh__${__chroma_name}__chroma__def[subcommands]"
    local __subcmds="${(P)__ch_def_name}"
    if [[ "$__subcmds" = "::"* ]]; then
        ${__subcmds#::}
        __var_name="${__the_hash_name}[subcommands]"
        : ${(P)__var_name::=(${(j:|:)reply})}
    else
        __var_name="${__the_hash_name}[subcommands]"
        : ${(P)__var_name::=$__subcmds}
    fi
    →chroma/main-chroma-print "Got SUBCOMMANDS: ${(P)__var_name}"

    __ch_def_name="fsh__${__chroma_name}__chroma__def[subcmd-hook]"
    local __subcmd_hook="${(P)__ch_def_name}"
    if [[ -n "$__subcmd_hook" ]]; then
        __var_name="${__the_hash_name}[subcmd-hook]"
        : ${(P)__var_name::=$__subcmd_hook}
    fi

    __ch_def_name="fsh__${__chroma_name}__chroma__def[(I)subcmd:*]"
    for __key in "${(P@)__ch_def_name}"; do
        __split=( "${(@s:|:)${${__key##subcmd:\((#c0,1)}%\)}}" )
        [[ ${#__split} -eq 1 && -z "${__split[1]}" ]] && __split=()
        __split=( "${__split[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
        for __ke in "${__split[@]}"; do
            __var_name="${__the_hash_name}[subcmd:$__ke]"
            __ch_def_name="fsh__${__chroma_name}__chroma__def[$__key]"
            : ${(P)__var_name::=${(P)__ch_def_name}}
            →chroma/main-chroma-print -rl -- "Storred ${__var_name}=chroma_def[$__key], i.e. = ${(P)__ch_def_name}"
        done
    done
}

if (( __first_call )); then
    →chroma/-${__chroma_name}-first-call
    FAST_HIGHLIGHT[chroma-current]="$__wrd"
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]=0
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-got-subcommand]=0
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]=""
    FAST_HIGHLIGHT[chrome-${FAST_HIGHLIGHT[chroma-current]}-occurred-double-hyphen]=0
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]=""
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-arg]=""
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr]=1
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-added-nodes]=""
    FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-deleted-nodes]=""
    __the_hash_name="fsh__chroma__main__${${FAST_HIGHLIGHT[chroma-current]//[^a-zA-Z0-9_]/_}//(#b)([\#\^])/${map[${match[1]}]}}"
    (( 0 == ${(P)+__the_hash_name} )) && {
        typeset -gA "$__the_hash_name"
        →chroma/-pre_process_chroma_def.ch "$__the_hash_name"
    } || →chroma/main-chroma-print "...No... [\${+$__the_hash_name} ${(P)+__the_hash_name}]"
    return 1
else
    (( ++ FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr] ))
    # Following call, i.e. not the first one

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    →chroma/main-chroma-print "== @@ Starting @@ #${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-call-nr]} Main-Chroma-call == // << __WORD:$__wrd >> ## Subcommand: ${${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}:-NULL} //@@// -n option-with-arg-active:${(q-)FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]}"
    if [[ "$__wrd" = -*  || -n "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-option-with-arg-active]}"
    ]]; then
        →chroma/main-chroma-print "## The \`if -*' i.e. \`IF OPTION' MAIN branch"
        →chroma/main-process-token.ch "${${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}:-NULL}" "$__wrd"
    else
        # If at e.g. '>' or destination/source spec (of the redirection)
        if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
            return 1
        elif (( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-got-subcommand] == 0 )) {
            __the_hash_name="fsh__chroma__main__${${FAST_HIGHLIGHT[chroma-current]//[^a-zA-Z0-9_]/_}//(#b)([\#\^])/${map[${match[1]}]}}"
            __var_name="${__the_hash_name}[subcommands]"
            if [[ "$__wrd" = ${(P)~__var_name} ]]; then
                →chroma/main-chroma-print "GOT-SUBCOMMAND := $__wrd, subcmd verification / OK"
                FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-got-subcommand]=1
                FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]="$__wrd"
		__var_name="${__the_hash_name}[subcmd-hook]"
		(( ${(P)+__var_name} )) && { →chroma/main-chroma-print -r -- "Running subcmd-hook: ${(P)__var_name}" ; "${(P)__var_name}" "$__wrd"; }
                __style="${FAST_THEME_NAME}subcommand"
            else
                →chroma/main-chroma-print "subcmd verif / NOT OK; Incrementing the COUNTER-ARG ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]} -> $(( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg] + 1 ))" >> /tmp/fsh-dbg
                (( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg] += 1 ))
                →chroma/main-chroma-print "UNRECOGNIZED ARGUMENT ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}"
                →chroma/main-process-token.ch "${${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}:-NULL}" "$__wrd"
            fi
        } else {
            __wrd="${__wrd//\`/x}"
            __arg="${__arg//\`/x}"
            __wrd="${(Q)__wrd}"

            local __tmp_def_name="fsh__${__chroma_name}__chroma__def[subcommands-blacklist]"
            if [[ ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]} = \
                (${(~j:|:)${(@s:,:)${(PA)__tmp_def_name}}})
            ]] {
                return 1
            }

            →chroma/main-chroma-print "Incrementing the COUNTER-ARG ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]} -> $(( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg] + 1 ))"
            (( FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg] += 1 ))
            →chroma/main-chroma-print "ARGUMENT ${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-counter-arg]}"

            →chroma/main-chroma-print "ELSE *-got-subcommand == 1 is TRUE"
            →chroma/main-process-token.ch "${FAST_HIGHLIGHT[chroma-${FAST_HIGHLIGHT[chroma-current]}-subcommand]}" "$__wrd"
        }
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
