# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
#
# Chroma function for command `git'. It colorizes the part of command
# line that holds `git' invocation.

(( FAST_HIGHLIGHT[-zplugin.ch-chroma-def] )) && return 1

FAST_HIGHLIGHT[-zplugin.ch-chroma-def]=1

typeset -gA fsh__zplugin__chroma__def
fsh__zplugin__chroma__def=(
    ##
    ## No subcommand
    ##
    ## {{{

    subcmd:NULL "NULL_0_opt"
    NULL_0_opt "(-help|--help|-h)
                   <<>> NO-OP // ::chroma/main-chroma-std-aopt-action"

    "subcommands" "(help|man|self-update|cd|times|zstatus|load|light|unload|snippet|ls|ice|<ice|specification>|update|status|report|delete|loaded|list|cd|create|edit|glance|stress|changes|recently|clist|completions|cdisable|cname|cenable|cname|creinstall|cuninstall|csearch|compinit|dtrace|dstart|dstop|dunload|dreport|dclear|compile|uncompile|compiled|cdlist|cdreplay|cdclear|srv|recall|env-whitelist|bindkeys|module)"

    ## }}}

    # Generic actions
    NO_MATCH_#_opt "* <<>> __style=\${FAST_THEME_NAME}incorrect-subtle // NO-OP"
    NO_MATCH_#_arg "__style=\${FAST_THEME_NAME}incorrect-subtle // NO-OP"

    ##
    ## `load'
    ##
    ## {{{

    "subcmd:(load|light|compile|stress|edit|glance|recall|update|status|cd|changes|delete)"
        "LOAD_1_arg // LOAD_2_arg // NO_MATCH_#_opt // NO_MATCH_#_arg"

    LOAD_1_arg "NO-OP // ::chroma/-zplugin-verify-plugin"

    LOAD_2_arg "NO-OP // ::chroma/-zplugin-verify-plugin"

    ## }}}

    ##
    ## `light'
    ##
    ## {{{

    subcmd:light "LIGHT_0_opt // LOAD_1_arg // LOAD_2_arg // NO_MATCH_#_opt // NO_MATCH_#_arg"

    LIGHT_0_opt "-b
                    <<>> NO-OP // ::chroma/main-chroma-std-aopt-action"

    ## }}}

    ##
    ## `light'
    ##
    ## {{{

    subcmd:(unload|report) "UNLOAD_1_arg // UNLOAD_2_arg"

    UNLOAD_1_arg "NO-OP // ::chroma/-zplugin-verify-loaded-plugin"

    UNLOAD_2_arg "NO-OP // ::chroma/-zplugin-verify-loaded-plugin"

    ## }}}


    ##
    ## `cenable'
    ##
    ## {{{

    subcmd:cenable "COMPLETION_1_arg"

    COMPLETION_1_arg "NO-OP // ::chroma/-zplugin-verify-disabled-completion"

    ## }}}

    ##
    ## `cdisable'
    ##
    ## {{{

    subcmd:cdisable "DISCOMPLETION_1_arg"

    DISCOMPLETION_1_arg "NO-OP // ::chroma/-zplugin-verify-completion"

    ## }}}


    ##
    ## `light'
    ##
    ## {{{

    subcmd:uncompile "UNCOMPILE_1_arg"

    UNCOMPILE_1_arg "NO-OP // ::chroma/-zplugin-verify-compiled-plugin"

    ## }}}

    ##
    ## `*'
    ##
    ## {{{

    "subcmd:*" "CATCH_ALL_#_opt"
    "CATCH_ALL_#_opt" "* <<>> NO-OP // ::chroma/main-chroma-std-aopt-SEMI-action"

    ## }}}
)

chroma/-git-verify-tag-name() {
    local _wrd="$4"
    -fast-run-git-command "git tag" "chroma-git-tags-$PWD" "" $(( 2*60 ))
    [[ -n ${__lines_list[(r)$_wrd]} ]] && \
        __style=${FAST_THEME_NAME}correct-subtle || \
        __style=${FAST_THEME_NAME}incorrect-subtle
}

# A handler for the commit's -m/--message options.Currently
# does the same what chroma/main-chroma-std-aopt-action does
chroma/-git-commit-msg-opt-action() {
    chroma/main-chroma-std-aopt-action "$@"
}

chroma/-zplugin-verify-plugin() {
    local _scmd="$1" _wrd="$4"

    [[ -d "$_wrd" ]] && \\
        { __style=${FAST_THEME_NAME}correct-subtle; return 0; }

    typeset -a plugins
    plugins=( "${ZPLGM[PLUGINS_DIR]}"/*(N:t) )
    plugins=( "${plugins[@]//---//}" )
    plugins=( "${plugins[@]:#_local/zplugin}" )
    plugins=( "${plugins[@]:#custom}" )

    [[ -n "${plugins[(r)$_wrd]}" ]] && \
        __style=${FAST_THEME_NAME}correct-subtle || \
        return 1
        #__style=${FAST_THEME_NAME}incorrect-subtle
    return 0
}

chroma/-zplugin-verify-loaded-plugin() {
    local _scmd="$1" _wrd="$4"
    typeset -a plugins absolute1 absolute2 absolute3 normal
    plugins=( "${ZPLG_REGISTERED_PLUGINS[@]:#_local/zplugin}" )
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

chroma/-zplugin-verify-completion() {
    local _scmd="$1" _wrd="$4"
    # Find enabled completions
    typeset -a completions
    completions=( "${ZPLGM[COMPLETIONS_DIR]}"/_*(N:t) )
    completions=( "${completions[@]#_}" )

    [[ -n "${completions[(r)${_wrd#_}]}" ]] && \
        __style=${FAST_THEME_NAME}correct-subtle || \
        return 1

    return 0
}

chroma/-zplugin-verify-disabled-completion() {
    local _scmd="$1" _wrd="$4"
    # Find enabled completions
    typeset -a completions
    completions=( "${ZPLGM[COMPLETIONS_DIR]}"/[^_]*(N:t) )

    [[ -n "${completions[(r)${_wrd#_}]}" ]] && \
        __style=${FAST_THEME_NAME}correct-subtle || \
        return 1

    return 0
}

chroma/-zplugin-verify-compiled-plugin() {
    local _scmd="$1" _wrd="$4"

    typeset -a plugins
    plugins=( "${ZPLGM[PLUGINS_DIR]}"/*(N) )

    typeset -a show_plugins p matches
    for p in "${plugins[@]}"; do
        matches=( $p/*.zwc(N) )
        if [ "$#matches" -ne "0" ]; then
            p="${p:t}"
            [[ "$p" = (_local---zplugin|custom) ]] && continue
            p="${p//---//}"
            show_plugins+=( "$p" )
        fi
    done

    [[ -n "${show_plugins[(r)$_wrd]}" ]] && \
        { __style=${FAST_THEME_NAME}correct-subtle; return 0; } || \
        return 1
}

return 0

# vim:ft=zsh:et:sw=4
