# vim:ft=zsh:et:sw=4
(( next_word = 2 | 8192 ))
[[ "$__arg_type" = 3 ]] && return 2

local __first_call="$1" __wrd="${2%%=*}" __start_pos="$3" __end_pos="$4"

if (( __first_call )) || [[ "$2" = -* ]]; then
    return 1
else
    if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
        return 1
    elif (( $+aliases[(e)$__wrd] )) || (( ${+galiases[(e)$__wrd]} )); then
        (( __start=__start_pos-${#PREBUFFER}, __end=__start_pos+${#__wrd}-${#PREBUFFER}, __start >= 0 )) \
            && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}correct-subtle]}")
    elif (( $+functions[(e)$__wrd] )) || (( $+builtins[(e)$__wrd] )) || (( $+commands[(e)$__wrd] )) || (( $reswords[(Ie)$__wrd] )); then
        (( __start=__start_pos-${#PREBUFFER}, __end=__start_pos+${#__wrd}-${#PREBUFFER}, __start >= 0 )) \
            && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
    else
        return 1
    fi
    if [[ "$__wrd" != "$2" ]]; then
        return 1
    fi
fi

(( this_word = next_word ))
_start_pos=$_end_pos

return 0
