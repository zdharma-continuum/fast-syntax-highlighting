# vim:ft=zsh:et:sw=4
(( next_word = 2 | 8192 ))
local THEFD check __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"
typeset -gA FAST_WHATIS_CACHE

(( ! ${+FAST_HIGHLIGHT[whatis_chroma_callback_was_ran]} )) && \
        FAST_HIGHLIGHT[whatis_chroma_callback_was_ran]=0

(( ! ${+FAST_HIGHLIGHT[whatis_chroma_zle_-F_have_-w_opt]} )) && {
        is-at-least 5.0.6 && local __res=1 || local __res=0
        FAST_HIGHLIGHT[whatis_chroma_zle_-F_have_-w_opt]="$__res"
}

-fast-whatis-chroma-callback() {
    local THEFD="$1" input check=2

    -fast-zts-read-all "$THEFD" input

    zle -F "$THEFD"
    exec {THEFD}<&-

    if [[ "$input" = test* ]]; then
        if [[ "${input%$'\n'}" = *[^0-9]'0' ]]; then
            if [[ "${input#test$'\n'}" = *nothing\ appropriate* ]]; then
                FAST_HIGHLIGHT[whatis_chroma_type]=2
            else
                FAST_HIGHLIGHT[whatis_chroma_type]=0
            fi
        else
            FAST_HIGHLIGHT[whatis_chroma_type]=1
        fi
    elif [[ "$input" = type2* ]]; then
        [[ "$input" != *nothing\ appropriate* ]] && check=1 || check=0
    elif [[ "$input" = type1* ]]; then
        [[ "${input%$'\n'}" = *0 ]] && check=1 || check=0
    fi

    if (( check != 2 )); then
        FAST_WHATIS_CACHE[$__wrd]=$check
        if (( check )) then
            __style=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}correct-subtle]}
        elif [[ ${~__wrd} = */* && -e ${~__wrd} ]] then
            __style=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path]}
        else
            __style=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}
        fi
        local -a start_end
        start_end=( ${(s:/:)${${(M)${${input#type?$'\n'}}#*$'\n'}%$'\n'}} )
        (( start_end[1] >= 0 )) && region_highlight+=("$start_end[1] $start_end[2] $__style")
        zle -R
    fi

    FAST_HIGHLIGHT[whatis_chroma_callback_was_ran]=1
    return 0
}

zle -N -- -fast-whatis-chroma-callback

if (( __first_call )) && [[ -z "${FAST_HIGHLIGHT[whatis_chroma_type]}" ]] ;then
    if ! command -v whatis > /dev/null; then
        FAST_HIGHLIGHT[whatis_chroma_type]=0
        return 1
    fi

    exec {THEFD}< <( echo "test"; whatis "osx whatis fallback check"; echo "$?"; )
    command true # a workaround of Zsh bug
    zle -F ${${FAST_HIGHLIGHT[whatis_chroma_zle_-F_have_-w_opt]:#0}:+-w} "$THEFD" -fast-whatis-chroma-callback
fi

[[ "$__arg_type" = 3 ]] && return 2

if (( __first_call )) || [[ "$__wrd" = -* ]]; then
    return 1
elif (( ! FAST_HIGHLIGHT[whatis_chroma_type] )); then
    # Return 1 (i.e. treat the argument as a path) only if the callback have
    # had a chance to establish the whatis_chroma_type field
    (( FAST_HIGHLIGHT[whatis_chroma_callback_was_ran] )) && return 1
else
    if [[ -z "${FAST_WHATIS_CACHE[$__wrd]}" ]]; then
        if (( FAST_HIGHLIGHT[whatis_chroma_type] == 2 )); then
            exec {THEFD}< <(
                echo "type2"
                (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER} ))
                echo "$__start/$__end"
                whatis "$__wrd" 2>/dev/null
            )
            command true # see above
            zle -F ${${FAST_HIGHLIGHT[whatis_chroma_zle_-F_have_-w_opt]:#0}:+-w} "$THEFD" -fast-whatis-chroma-callback
        else
            exec {THEFD}< <(
                echo "type1"
                (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER} ))
                echo "$__start/$__end"
                whatis "$__wrd" > /dev/null 2>&1
                echo "$?"
            )
            command true
            zle -F ${${FAST_HIGHLIGHT[whatis_chroma_zle_-F_have_-w_opt]:#0}:+-w} "$THEFD" -fast-whatis-chroma-callback
        fi
    else
        check=${FAST_WHATIS_CACHE[$__wrd]}
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
fi
(( this_word = next_word ))
_start_pos=$_end_pos

return 0
