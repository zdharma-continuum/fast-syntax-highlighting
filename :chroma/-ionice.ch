# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# -------------------------------------------------------------------------------------------------
# Copyright (c) 2018 Sebastian Gniazdowski
# Copyright (C) 2019 by Philippe Troin (F-i-f on GitHub)
# All rights reserved.
#
# The only licensing for this file follows.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice, this list of conditions
#    and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice, this list of
#    conditions and the following disclaimer in the documentation and/or other materials provided
#    with the distribution.
#  * Neither the name of the zsh-syntax-highlighting contributors nor the names of its contributors
#    may be used to endorse or promote products derived from this software without specific prior
#    written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# -------------------------------------------------------------------------------------------------

setopt local_options extendedglob warn_create_global typeset_silent

# Keep chroma-takever state meaning: until ;, handle highlighting via chroma.
# So the below 8192 assignment takes care that next token will be routed to chroma.
(( next_word = 2 | 8192 ))

local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"
local __style option_start=0 option_end=0 number_start=0 number_end=0
local -a match mbegin mend

(( __first_call )) && {
    # Called for the first time - new command.
    # FAST_HIGHLIGHT is used because it survives between calls, and
    # allows to use a single global hash only, instead of multiple
    # global string variables.
    FAST_HIGHLIGHT[ionice-option-argument]=0

    # Set style for region_highlight entry. It is used below in
    # '[[ -n "$__style" ]] ...' line, which adds highlight entry,
    # like "10 12 fg=green", through `reply' array.
    #
    # Could check if command `example' exists and set `unknown-token'
    # style instead of `command'
    __style=${FAST_THEME_NAME}precommand

} || {
    # Following call, i.e. not the first one

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
        return 1
    fi

    if (( FAST_HIGHLIGHT[ionice-option-argument] )); then
        (( FAST_HIGHLIGHT[ionice-option-argument] = 0 ))
        [[ $__wrd == [0-9]# ]] && __style=${FAST_THEME_NAME}mathnum || __style=${FAST_THEME_NAME}incorrect-subtle
    else
        case $__wrd in
            --(class(data|)|(u|p(g|))id))
                 __style=${FAST_THEME_NAME}double-hyphen-option
                 FAST_HIGHLIGHT[ionice-option-argument]=1
                 ;;
            -[cnpPu])
                 __style=${FAST_THEME_NAME}single-hyphen-option
                 FAST_HIGHLIGHT[ionice-option-argument]=1
                 ;;
            --*)
                __style=${FAST_THEME_NAME}double-hyphen-option
                ;;
            -*)
                __style=${FAST_THEME_NAME}single-hyphen-option
                ;;
            *)
                this_word=1
                next_word=2
                return 1
                ;;
        esac
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
