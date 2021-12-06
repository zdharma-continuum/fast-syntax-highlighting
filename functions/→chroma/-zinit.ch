# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018-2019 Sebastian Gniazdowski
#
# Chroma function for command `git'. It colorizes the part of command
# line that holds `git' invocation.

(( FAST_HIGHLIGHT[-zinit.ch-chroma-def] )) && return 1

FAST_HIGHLIGHT[-zinit.ch-chroma-def]=1

typeset -gA fsh__zinit__chroma__def
fsh__zinit__chroma__def=(
    ##
    ## No subcommand
    ##
    ## {{{

    subcmd:NULL "NULL_0_opt"
    NULL_0_opt "(-help|--help|-h)
                   <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    "subcommands" "(help|man|self-update|cd|times|zstatus|load|light|unload|snippet|ls|ice|<ice|specification>|update|status|report|delete|loaded|list|cd|create|edit|glance|stress|changes|recently|clist|completions|cdisable|cname|cenable|cname|creinstall|cuninstall|csearch|compinit|dtrace|dstart|dstop|dunload|dreport|dclear|compile|uncompile|compiled|cdlist|cdreplay|cdclear|srv|recall|env-whitelist|bindkeys|module)"

    ## }}}

    # Generic actions
    NO_MATCH_\#_opt "* <<>> __style=\${FAST_THEME_NAME}incorrect-subtle // NO-OP"
    NO_MATCH_\#_arg "__style=\${FAST_THEME_NAME}incorrect-subtle // NO-OP"


    ##
    ## `ice'
    ##
    ## {{{

    subcmd:ice "ICE_#_arg // NO_MATCH_#_opt"

    "ICE_#_arg" "NO-OP // ::→chroma/-zinit-check-ice-mod"

    ## }}}

    ##
    ## `snippet'
    ##
    ## {{{

    subcmd:snippet "SNIPPET_0_opt // SNIPPET_1_arg // NO_MATCH_#_opt //
                    NO_MATCH_#_arg"

    SNIPPET_0_opt "(-f|--command)
                        <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    SNIPPET_1_arg "NO-OP // ::→chroma/-zinit-verify-snippet"

    ## }}}

    ##
    ## `load'
    ##
    ## {{{

    "subcmd:load"
        "LOAD_1_arg // LOAD_2_arg // NO_MATCH_#_opt // NO_MATCH_#_arg"

    LOAD_1_arg "NO-OP // ::→chroma/-zinit-verify-plugin"

    LOAD_2_arg "NO-OP // ::→chroma/-zinit-verify-plugin"

    ## }}}

    ##
    ## `compile|uncompile|stress|edit|glance|recall|status|cd|changes`
    ##
    ## {{{
    
    "subcmd:(compile|uncompile|stress|edit|glance|recall|status|cd|changes)"
        "PLGSNP_1_arg // PLGSNP_2_arg // NO_MATCH_#_opt // NO_MATCH_#_arg"

    PLGSNP_1_arg "NO-OP // ::→chroma/-zinit-verify-plugin-or-snippet"

    PLGSNP_2_arg "NO-OP // ::→chroma/-zinit-verify-plugin-or-snippet"

    ## }}}

    ##
    ## `update'
    ##
    ## {{{

    subcmd:update "UPDATE_0_opt // PLGSNP_1_arg // PLGSNP_2_arg //
                   NO_MATCH_#_opt // NO_MATCH_#_arg"

    UPDATE_0_opt "
            (--all|-r|--reset|-q|--quiet|-p|--parallel)
                    <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    ## }}}

    ##
    ## `light'
    ##
    ## {{{

    subcmd:light "LIGHT_0_opt // LOAD_1_arg // LOAD_2_arg // NO_MATCH_#_opt //
                  NO_MATCH_#_arg"

    LIGHT_0_opt "-b
                    <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    ## }}}

    ##
    ## `unload'
    ##
    ## {{{

    subcmd:unload "UNLOAD_0_opt // UNLOAD_1_arg // UNLOAD_2_arg // NO_MATCH_#_opt //
                  NO_MATCH_#_arg"

    UNLOAD_0_opt "-q
                    <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    UNLOAD_1_arg "NO-OP // ::→chroma/-zinit-verify-loaded-plugin"

    UNLOAD_2_arg "NO-OP // ::→chroma/-zinit-verify-loaded-plugin"

    ## }}}

    ##
    ## `report'
    ##
    ## {{{

    subcmd:report "REPORT_0_opt // UNLOAD_1_arg // UNLOAD_2_arg // NO_MATCH_#_opt //
                  NO_MATCH_#_arg"

    REPORT_0_opt "--all
                    <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    ## }}}

    ##
    ## `delete'
    ##
    ## {{{

    "subcmd:delete"
        "DELETE_0_opt // PLGSNP_1_arg // PLGSNP_2_arg // NO_MATCH_#_opt // NO_MATCH_#_arg"

    DELETE_0_opt "
            (--all|--clean|-y|--yes|-q|--quiet)
                    <<>> NO-OP // ::→chroma/main-chroma-std-aopt-action"

    ## }}}

    ##
    ## `cenable'
    ##
    ## {{{

    subcmd:cenable "COMPLETION_1_arg // NO_MATCH_#_opt // NO_MATCH_#_arg"

    COMPLETION_1_arg "NO-OP // ::→chroma/-zinit-verify-disabled-completion"

    ## }}}

    ##
    ## `cdisable'
    ##
    ## {{{

    subcmd:cdisable "DISCOMPLETION_1_arg // NO_MATCH_#_opt // NO_MATCH_#_arg"

    DISCOMPLETION_1_arg "NO-OP // ::→chroma/-zinit-verify-completion"

    ## }}}


    ##
    ## `light'
    ##
    ## {{{

    subcmd:uncompile "UNCOMPILE_1_arg // NO_MATCH_#_opt // NO_MATCH_#_arg"

    UNCOMPILE_1_arg "NO-OP // ::→chroma/-zinit-verify-compiled-plugin"

    ## }}}

    ##
    ## `*'
    ##
    ## {{{

    "subcmd:*" "CATCH_ALL_#_opt"
    "CATCH_ALL_#_opt" "* <<>> NO-OP // ::→chroma/main-chroma-std-aopt-SEMI-action"

    ## }}}
)

#→chroma/-zinit-first-call() {
    # This is being done in the proper place - in -fast-highlight-process
    #FAST_HIGHLIGHT[chroma-zinit-ice-elements-svn]=0
#}

→chroma/-zinit-verify-plugin() {
    local _scmd="$1" _wrd="$4"

    [[ -d "$_wrd" ]] && \
        { __style=${FAST_THEME_NAME}correct-subtle; return 0; }

    typeset -a plugins
    plugins=( "${ZINIT[PLUGINS_DIR]}"/*(N:t) )
    plugins=( "${plugins[@]//---//}" )
    plugins=( "${plugins[@]:#_local/zinit}" )
    plugins=( "${plugins[@]:#custom}" )

    [[ -n "${plugins[(r)$_wrd]}" ]] && \
        __style=${FAST_THEME_NAME}correct-subtle || \
        return 1
        #__style=${FAST_THEME_NAME}incorrect-subtle
    return 0
}

→chroma/-zinit-verify-plugin-or-snippet() {
    →chroma/-zinit-verify-plugin "$1" "" "" "$4" || \
        →chroma/-zinit-verify-snippet "$1" "" "" "$4"
    return $?
}

→chroma/-zinit-verify-loaded-plugin() {
    local _scmd="$1" _wrd="$4"
    typeset -a plugins absolute1 absolute2 absolute3 normal
    plugins=( "${ZINIT_REGISTERED_PLUGINS[@]:#_local/zinit}" )
    normal=( "${plugins[@]:#%*}" )
    absolute1=( "${(M)plugins[@]:#%*}" )
    absolute1=( "${absolute1[@]/\%\/\//%/}" )
    local hm="${HOME%/}"
    absolute2=( "${absolute1[@]/$hm/HOME}" )
    absolute3=( "${absolute1[@]/\%/}" )
    plugins=( $absolute1 $absolute2 $absolute3 $normal )

    [[ -n "${plugins[(r)$_wrd]}" ]] && \
        __style=${FAST_THEME_NAME}correct-subtle || \
        return 1
        #__style=${FAST_THEME_NAME}incorrect-subtle

    return 0
}

→chroma/-zinit-verify-completion() {
    local _scmd="$1" _wrd="$4"
    # Find enabled completions
    typeset -a completions
    completions=( "${ZINIT[COMPLETIONS_DIR]}"/_*(N:t) )
    completions=( "${completions[@]#_}" )

    [[ -n "${completions[(r)${_wrd#_}]}" ]] && \
        __style=${FAST_THEME_NAME}correct-subtle || \
        return 1

    return 0
}

→chroma/-zinit-verify-disabled-completion() {
    local _scmd="$1" _wrd="$4"
    # Find enabled completions
    typeset -a completions
    completions=( "${ZINIT[COMPLETIONS_DIR]}"/[^_]*(N:t) )

    [[ -n "${completions[(r)${_wrd#_}]}" ]] && \
        __style=${FAST_THEME_NAME}correct-subtle || \
        return 1

    return 0
}

→chroma/-zinit-verify-compiled-plugin() {
    local _scmd="$1" _wrd="$4"

    typeset -a plugins
    plugins=( "${ZINIT[PLUGINS_DIR]}"/*(N) )

    typeset -a show_plugins p matches
    for p in "${plugins[@]}"; do
        matches=( $p/*.zwc(N) )
        if [ "$#matches" -ne "0" ]; then
            p="${p:t}"
            [[ "$p" = (_local---zinit|custom) ]] && continue
            p="${p//---//}"
            show_plugins+=( "$p" )
        fi
    done

    [[ -n "${show_plugins[(r)$_wrd]}" ]] && \
        { __style=${FAST_THEME_NAME}correct-subtle; return 0; } || \
        return 1
}

→chroma/-zinit-verify-snippet() {
    local _scmd="$1" url="$4" dirname local_dir
    url="${${url#"${url%%[! $'\t']*}"}%/}"
    id_as="${FAST_HIGHLIGHT[chroma-zinit-ice-elements-id-as]:-${ZINIT_ICE[id-as]:-$url}}"

    filename="${${id_as%%\?*}:t}"
    dirname="${${id_as%%\?*}:t}"
    local_dir="${${${id_as%%\?*}:h}/:\/\//--}"
    [[ "$local_dir" = "." ]] && local_dir="" || local_dir="${${${${${local_dir#/}//\//--}//=/--EQ--}//\?/--QM--}//\&/--AMP--}"
    local_dir="${ZINIT[SNIPPETS_DIR]}${local_dir:+/$local_dir}"

    (( ${+ZINIT_ICE[svn]} || ${FAST_HIGHLIGHT[chroma-zinit-ice-elements-svn]} )) && {
        # TODO: handle the SVN path's specifics
        [[ -d "$local_dir/$dirname" ]] && \
            { __style=${FAST_THEME_NAME}correct-subtle; return 0; } || \
            return 1
    } || {
        # TODO: handle the non-SVN path's specifics
        [[ -d "$local_dir/$dirname" ]] && \
            { __style=${FAST_THEME_NAME}correct-subtle; return 0; } || \
            return 1
    }
}

→chroma/-zinit-check-ice-mod() {
    local _scmd="$1" _wrd="$4"
    [[ "$_wrd" = (svn(\'|\")*|svn) ]] && \
        FAST_HIGHLIGHT[chroma-zinit-ice-elements-svn]=1
    [[ "$_wrd" = (#b)(id-as(:|)(\'|\")(*)(\'|\")|id-as:(*)|id-as(*)) ]] && \
        FAST_HIGHLIGHT[chroma-zinit-ice-elements-id-as]="${match[4]}${match[6]}${match[7]}"

    # Copy from zinit-autoload.zsh / -zplg-recall
    local -a ice_order nval_ices ext_val_ices
    ext_val_ices=( ${(@)${(@Ms.|.)ZINIT_EXTS[ice-mods]:#*\'\'*}//\'\'/} )

    ice_order=(
        svn proto from teleid bindmap cloneopts id-as depth if wait load
        unload blockf pick bpick src as ver silent lucid notify mv cp
        atinit atclone atload atpull nocd run-atpull has cloneonly make
        service trackbinds multisrc compile nocompile nocompletions
        reset-prompt wrap-track reset sh \!sh bash \!bash ksh \!ksh csh
        \!csh aliases countdown ps-on-unload ps-on-update trigger-load
        light-mode is-snippet atdelete pack git verbose on-update-of
        subscribe param extract
        # Include all additional ices – after
        # stripping them from the possible: ''
        ${(@s.|.)${ZINIT_EXTS[ice-mods]//\'\'/}}
    )
    nval_ices=(
            blockf silent lucid trackbinds cloneonly nocd run-atpull
            nocompletions sh \!sh bash \!bash ksh \!ksh csh \!csh
            aliases countdown light-mode is-snippet git verbose

            # Include only those additional ices,
            # don't have the '' in their name, i.e.
            # aren't designed to hold value
            ${(@)${(@s.|.)ZINIT_EXTS[ice-mods]}:#*\'\'*}

            # Must be last
            svn
    )

    if [[ "$_wrd" = (#b)(${(~j:|:)${ice_order[@]:#(${(~j:|:)nval_ices[@]:#(${(~j:|:)ext_val_ices[@]})})}})(*) ]]; then
        reply+=("$(( __start )) $(( __start+${mend[1]} )) ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}double-hyphen-option]}")
        reply+=("$(( __start+${mbegin[2]} )) $(( __end )) ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}optarg-string]}")
        -fast-highlight-string
        return 0
    elif [[ "$_wrd" = (#b)(${(~j:|:)nval_ices[@]}) ]]; then
        __style=${FAST_THEME_NAME}single-hyphen-option
        return 0
    else
        __style=${FAST_THEME_NAME}incorrect-subtle
        return 1
    fi
}

return 0

# vim:ft=zsh:et:sw=4
