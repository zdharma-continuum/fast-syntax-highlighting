# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018-2019 Sebastian Gniazdowski

(( next_word = 2 | 8192 ))
local THEFD check __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"
local __style

(( ! ${+FAST_HIGHLIGHT[whatis_chroma_callback_was_ran]} )) && \
        FAST_HIGHLIGHT[whatis_chroma_callback_was_ran]=0

(( ! ${+FAST_HIGHLIGHT[whatis_chroma_zle_-F_have_-w_opt]} )) && {
        is-at-least 5.0.6 && local __res=1 || local __res=0
        FAST_HIGHLIGHT[whatis_chroma_zle_-F_have_-w_opt]="$__res"
}

-fast-whatis-chroma-callback() {
    emulate -L zsh
    setopt extendedglob warncreateglobal typesetsilent

    local THEFD="$1" input check=2 nl=$'\n' __wrd __style

    .fast-zts-read-all "$THEFD" input

    zle -F "$THEFD"
    exec {THEFD}<&-

    __wrd="${${input#[^$nl]#$nl}%%$nl*}"
    if [[ "$input" = test* ]]; then
        if [[ "${input%$nl}" = *[^0-9]'0' ]]; then
            if [[ "${input#test$nl}" = *nothing\ appropriate* ]]; then
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
        [[ "${input%$nl}" = *0 ]] && check=1 || check=0
    fi

    if (( check != 2 )); then
        FAST_HIGHLIGHT[whatis-cache-$__wrd]=$check
        if (( check )) then
            __style=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}correct-subtle]}
        elif [[ ${~__wrd} = */* && -e ${~__wrd} ]] then
            __style=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path]}
        else
            __style=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}
        fi
        local -a start_end
        start_end=( ${(s:/:)${${(M)${${input#type?${nl}[^$nl]#$nl}}#*$nl}%$nl}} )
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

    exec {THEFD}< <(
        print "test"
        LANG=C whatis "osx whatis fallback check"
        print "$?"
    )
    command true # a workaround of Zsh bug
    zle -F ${${FAST_HIGHLIGHT[whatis_chroma_zle_-F_have_-w_opt]:#0}:+-w} "$THEFD" -fast-whatis-chroma-callback
fi

[[ "$__arg_type" = 3 ]] && return 2

if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
    return 1
fi

if (( __first_call )) || [[ "$__wrd" = -* ]]; then
    return 1
elif (( ! FAST_HIGHLIGHT[whatis_chroma_type] )); then
    # Return 1 (i.e. treat the argument as a path) only if the callback have
    # had a chance to establish the whatis_chroma_type field
    (( FAST_HIGHLIGHT[whatis_chroma_callback_was_ran] )) && return 1
else
    if [[ -z "${FAST_HIGHLIGHT[whatis-cache-$__wrd]}" ]]; then
        if (( FAST_HIGHLIGHT[whatis_chroma_type] == 2 )); then
            exec {THEFD}< <(
                print "type2"
                print "$__wrd"
                (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER} ))
                print "$__start/$__end"
                LANG=C whatis "$__wrd" 2>/dev/null
            )
            command true # see above
            zle -F ${${FAST_HIGHLIGHT[whatis_chroma_zle_-F_have_-w_opt]:#0}:+-w} "$THEFD" -fast-whatis-chroma-callback
        else
            exec {THEFD}< <(
                print "type1"
                print "$__wrd"
                (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER} ))
                print "$__start/$__end"
                LANG=C whatis "$__wrd" &> /dev/null
                print "$?"
            )
            command true
            zle -F ${${FAST_HIGHLIGHT[whatis_chroma_zle_-F_have_-w_opt]:#0}:+-w} "$THEFD" -fast-whatis-chroma-callback
        fi
        __style=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}
        (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && \
            reply+=("$__start $__end $__style")
    else
        check=${FAST_HIGHLIGHT[whatis-cache-$__wrd]}
        if (( check )) then
            __style=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}correct-subtle]}
        elif [[ ${~__wrd} = */* && -e ${~__wrd} ]] then
            __style=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}path]}
        elif (( FAST_HIGHLIGHT[whatis_chroma_type] )); then
            __style=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}
        fi
        [[ -n "$__style" ]] && \
            (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && \
                reply+=("$__start $__end $__style")
    fi
fi
(( this_word = next_word ))
_start_pos=$_end_pos

return 0

# vim:ft=zsh:et:sw=4:sts=4
