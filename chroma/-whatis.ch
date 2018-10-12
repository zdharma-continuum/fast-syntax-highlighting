# vim:ft=zsh:et:sw=4
(( next_word = 2 | 8192 ))
local out check __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"
typeset -gA FAST_WHATIS_CACHE

if (( __first_call )) && [[ -z "${FAST_HIGHLIGHT[whatis_chroma_type]}" ]] ;then
    if ! command -v whatis > /dev/null; then
        FAST_HIGHLIGHT[whatis_chroma_type]=0
        return 1
    fi

    out=$(whatis "osx whatis fallback ckeck")
    if [[ $? == 0 ]]; then
        if [[ "$out" = *nothing\ appropriate* ]]; then
            FAST_HIGHLIGHT[whatis_chroma_type]=2
        else
            FAST_HIGHLIGHT[whatis_chroma_type]=0
            return 1
        fi
    else
        FAST_HIGHLIGHT[whatis_chroma_type]=1
    fi
fi

[[ "$__arg_type" = 3 ]] && return 2

if (( __first_call )) || (( ! FAST_HIGHLIGHT[whatis_chroma_type] )) || [[ "$__wrd" = -* ]]; then
    return 1
else
    if [[ -z "${FAST_WHATIS_CACHE[$__wrd]}" ]]; then
        if (( FAST_HIGHLIGHT[whatis_chroma_type] == 2 )); then
            out=$(whatis "$__wrd")
            [[ "$out" != *nothing\ appropriate* ]] && check=1 || check=0
        else
            whatis "$__wrd" > /dev/null && check=1 || check=0
        fi
        FAST_WHATIS_CACHE[$__wrd]=$check
    else
        check=${FAST_WHATIS_CACHE[$__wrd]}
    fi
    if (( check )) then
        __style=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}correct-subtle]}
    elif [[ ${~__wrd} = */* && -e ${~__wrd} ]] then
        __style=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path]}
    else
        __style=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}
    fi
    (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) \
        && reply+=("$__start $__end $__style")
fi
(( this_word = next_word ))
_start_pos=$_end_pos

return 0
