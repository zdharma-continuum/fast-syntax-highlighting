# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2018 Sebastian Gniazdowski
#
# Example chroma function. It colorizes first two arguments as `builtin' style,
# third and following arguments as `globbing' style. First two arguments may
# be "strings", they will be passed through to normal higlighter (by returning 1).
#
# $1 - 0 or 1, denoting if it's first call to the chroma, or following one
#
# $2 - the current token, also accessible by $__arg from the above scope -
#      basically a private copy of $__arg; the token can be eg.: "grep"
#
# $3 - a private copy of $_start_pos, i.e. the position of the token in the
#      command line buffer, used to add region_highlight entry (see man),
#      because Zsh colorizes by *ranges* in command line buffer
#
# $4 - a private copy of $_end_pos from the above scope
#
#
# Overall functioning is: when command "example" is occured, this function
# is called with $1 == 1, it ("example") is the first token ($2), then for any
# following token, this function is called with $1 == 0, until end of command
# is occured (i.e. till enter is pressed or ";" is put into source, or the
# command line simply ends).
#
# Other tips are:
# - $CURSOR holds cursor position
# - $BUFFER holds whole command line buffer
# - $LBUFFER holds command line buffer that is left from the cursor, i.e. it's a
#   BUFFER substring 1 .. $CURSOR
# - $RBUFFER is the same as LBUFFER but holds part of BUFFER right to the cursor
#
# The function receives $BUFFER but via sequence of tokens, which are shell words,
# e.g. "a b c" is a shell word, while a b c are 3 shell words.
#
# FAST_HIGHLIGHT is a friendly hash array which allows to store strings without
# creating global parameters (variables). If you need hash, just use it first
# declaring, under some distinct name like: typeset -gA CHROMA_EXPLE_DICT.
# Remember to reset the hash and others at __first_call == 1, so that you have
# a fresh state for new command.

# Keep chroma-takever state meaning: until ;, handle highlighting via chroma.
# So the below 8192 assignment takes care that next token will be routed to chroma.
(( next_word = 2 | 8192 ))

local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"
local __style
integer __idx1 __idx2

(( __first_call )) && {
    # Called for the first time - new command.
    # FAST_HIGHLIGHT is used because it survives between calls, and
    # allows to use a single global hash only, instead of multiple
    # global string variables.
    FAST_HIGHLIGHT[chroma-example-counter]=0

    # Set style for region_highlight entry. It is used below in
    # '[[ -n "$__style" ]] ...' line, which adds highlight entry,
    # like "10 12 fg=green", through `reply' array.
    #
    # Could check if command `example' exists and set `unknown-token'
    # style instead of `command'
    __style=${FAST_THEME_NAME}command

} || {
    # Following call, i.e. not the first one

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
        return 1
    fi

    if [[ "$__wrd" = -* ]]; then
        # Detected option, add style for it.
        [[ "$__wrd" = --* ]] && __style=${FAST_THEME_NAME}double-hyphen-option || \
                                __style=${FAST_THEME_NAME}single-hyphen-option
    else
        # Count non-option tokens
        (( FAST_HIGHLIGHT[chroma-example-counter] += 1, __idx1 = FAST_HIGHLIGHT[chroma-example-counter] ))

        # Colorize 1..2 as builtin, 3.. as glob
        if (( FAST_HIGHLIGHT[chroma-example-counter] <= 2 )); then
            if [[ "$__wrd" = \"* ]]; then
                # Pass through, fsh main code will do the highlight!
                return 1
            else
                __style=${FAST_THEME_NAME}builtin
            fi
        else
            __style=${FAST_THEME_NAME}globbing
        fi
    fi
}

# Add region_highlight entry (via `reply' array).
# If 1 will be added to __start_pos, this will highlight "oken".
# If 1 will be subtracted from __end_pos, this will highlight "toke".
# $PREBUFFER is for specific situations when users does command \<ENTER>
# i.e. when multi-line command using backslash is entered.
#
# This is a common place of adding such entry, but any above code can do
# it itself (and it does in other chromas) and skip setting __style to
# this way disable this code.
[[ -n "$__style" ]] && (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style]}")

# We aren't passing-through, do obligatory things ourselves.
# _start_pos=$_end_pos advainces pointers in command line buffer.
#
# To pass through means to `return 1'. The highlighting of
# this single token is then done by fast-syntax-highlighting's
# main code and chroma doesn't have to do anything.
(( this_word = next_word ))
_start_pos=$_end_pos

return 0

# vim:ft=zsh:et:sw=4
