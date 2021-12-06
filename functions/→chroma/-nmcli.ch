# vim:ft=zsh:et:sw=4
(( next_word = 2 | 8192 ))
[[ "$__arg_type" = 3 ]] && return 2

typeset -A subcommands
local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4" subcommand
subcommands=(
    help "_"
    general "help status hostname permissions logging _"
    networking "help on off connectivity _"
    radio "help all wifi wwan _"
    connection "help show up down add modify clone edit delete monitor reload load import export _"
    device "help status show set connect reapply modify disconnect delete monitor wifi lldp _"
    agent "help secret polkit all _"
    monitor "help _"
    _ "_"
)

if (( __first_call )); then
    FAST_HIGHLIGHT[chroma-nmcli-subcommand-a]=""
    FAST_HIGHLIGHT[chroma-nmcli-subcommand-b]=""
    return 1
elif (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
        return 1
elif [[ "$2" = -* ]]; then
    return 1
elif [[ -z ${FAST_HIGHLIGHT[chroma-nmcli-subcommand-a]} ]]; then
    for subcommand in ${(@k)subcommands}; do
        [[ $subcommand = $__wrd* ]] && break || subcommand="_"
    done
    if [[ $subcommand = _ ]]; then
        (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) \
            && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
    else
        (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) \
        && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}subcommand]}")
    fi
    FAST_HIGHLIGHT[chroma-nmcli-subcommand-a]="$subcommand"
elif [[ -z ${FAST_HIGHLIGHT[chroma-nmcli-subcommand-b]} ]]; then
    for subcommand in ${(s. .)subcommands[${FAST_HIGHLIGHT[chroma-nmcli-subcommand-a]}]}; do
        [[ "$subcommand" = $__wrd* ]] && break || subcommand="_"
    done
    if [[ $subcommand = _ ]]; then
        (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) \
            && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}")
    else
        (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) \
        && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}subcommand]}")
    fi
    FAST_HIGHLIGHT[chroma-nmcli-subcommand-b]="$subcommand"
else
    return 1
fi

(( this_word = next_word ))
_start_pos=$_end_pos

return 0
