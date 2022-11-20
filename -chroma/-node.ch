# vim:ft=zsh:et:sw=4
(( next_word = 2 | 8192 ))
[[ "$__arg_type" = 3 ]] && return 2

local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"
local __style

if (( __first_call )); then
    FAST_HIGHLIGHT[chroma-node-file]=1
elif (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
    return 1
elif [[ "$__wrd" = -- ]]; then
    FAST_HIGHLIGHT[chroma-node-file]=2
elif (( FAST_HIGHLIGHT[chroma-node-file] != 2 )) && [[ "$__wrd" = -* ]]; then
    if [[ "$__wrd" = -*e* || "$__wrd" = --eval ]]; then
        FAST_HIGHLIGHT[chroma-node-file]=0
    fi
elif (( FAST_HIGHLIGHT[chroma-node-file] )); then
    if [[ "$__wrd" = debug || "$__wrd" = inspect ]]; then
        __style=${FAST_THEME_NAME}subcommand
    else
        FAST_HIGHLIGHT[chroma-node-file]=0
        if [[ -f ${~__wrd} || -f ${~__wrd}.js || -f ${~__wrd}/index.js ]]; then
            __style=${FAST_THEME_NAME}path
        else
            __style=${FAST_THEME_NAME}incorrect-subtle
        fi
    fi
    (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) \
        && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style]}")
    (( this_word = next_word ))
    _start_pos=$_end_pos

    return 0
fi

return 1
