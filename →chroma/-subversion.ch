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

→chroma/-subversion.ch/parse-revision() {
    setopt local_options extendedglob warn_create_global typeset_silent
    local __wrd="$1" __start_pos="$2" __end_pos="$3" __style __start __end
    case $__wrd in
        (r|)[0-9]##)               __style=${FAST_THEME_NAME}mathnum          ;;
        (HEAD|BASE|COMITTED|PREV)) __style=${FAST_THEME_NAME}correct-subtle   ;;
        '{'[^}]##'}')              __style=${FAST_THEME_NAME}subtle-bg        ;;
        *)                         __style=${FAST_THEME_NAME}incorrect-subtle ;;
    esac
    (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style]}")
}

→chroma/-subversion.ch/parse-target() {
    setopt local_options extendedglob warn_create_global typeset_silent
    local __wrd="$1" __start_pos="$2" __end_pos="$3" __style __start __end
    if [[ $__wrd == *@[^/]# ]]
    then
        local place=${__wrd%@[^/]#}
        local rev=$__wrd[$(($#place+2)),$#__wrd]
        if [[ -e $place ]]; then
            local __style
            [[ -d $place ]] && __style="${FAST_THEME_NAME}path-to-dir"  ||  __style="${FAST_THEME_NAME}path"
            (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}-$#rev-1, __start >= 0 )) \
                && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style]}")
        fi
        (( __start=__start_pos-${#PREBUFFER}+$#place, __end=__end_pos-${#PREBUFFER}-$#rev, __start >= 0 )) \
            && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}for-loop-separator]}")
        →chroma/-subversion.ch/parse-revision $rev $((__start_pos+$#place+1)) $__end_pos
    else
        return 1
    fi
}

setopt local_options extendedglob warn_create_global

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
    FAST_HIGHLIGHT[subversion-command]=$__wrd
    FAST_HIGHLIGHT[subversion-option-argument]=
    FAST_HIGHLIGHT[subversion-subcommand]=
    FAST_HIGHLIGHT[subversion-subcommand-arguments]=0

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
        case $FAST_HIGHLIGHT[subversion-command]/$FAST_HIGHLIGHT[subversion-subcommand] in
            svn/)
                case $__wrd in
                    --username|-u)         FAST_HIGHLIGHT[subversion-option-argument]=any;;
                    --password|-p)         FAST_HIGHLIGHT[subversion-option-argument]=any;;
                    --config-(dir|option)) FAST_HIGHLIGHT[subversion-option-argument]=any;;
                esac
                ;;
            svn/?*)
                case $__wrd in
                    --accept)          FAST_HIGHLIGHT[subversion-option-argument]=accept;;
                    --change|-c)       FAST_HIGHLIGHT[subversion-option-argument]=revision;;
                    --changelist|--cl) FAST_HIGHLIGHT[subversion-option-argument]=any;;
                    --(set-|)depth)    FAST_HIGHLIGHT[subversion-option-argument]=depth;;
                    --diff(3|)-cmd)    FAST_HIGHLIGHT[subversion-option-argument]=cmd;;
                    --editor-cmd)      FAST_HIGHLIGHT[subversion-option-argument]=cmd;;
                    --encoding)        FAST_HIGHLIGHT[subversion-option-argument]=any;;
                    --file)            FAST_HIGHLIGHT[subversion-option-argument]=any;;
                    --limit|-l)        FAST_HIGHLIGHT[subversion-option-argument]=number;;
                    --message|-m)      FAST_HIGHLIGHT[subversion-option-argument]=any;;
                    --native-eol)      FAST_HIGHLIGHT[subversion-option-argument]=eol;;
                    --new|--old)       FAST_HIGHLIGHT[subversion-option-argument]=target;;
                    --revision|-r)     FAST_HIGHLIGHT[subversion-option-argument]=revision-pair;;
                    --show-revs)       FAST_HIGHLIGHT[subversion-option-argument]=show-revs;;
                    --strip)           FAST_HIGHLIGHT[subversion-option-argument]=number;;
                    --with-revprop)    FAST_HIGHLIGHT[subversion-option-argument]=revprop;;
                esac
                ;;
            svnadmin/*)
                case $__wrd in
                    --config-dir)           FAST_HIGHLIGHT[subversion-option-argument]=any;;
                    --fs-type)              FAST_HIGHLIGHT[subversion-option-argument]=any;;
                    --memory-cache-size|-M) FAST_HIGHLIGHT[subversion-option-argument]=number;;
                    --parent-dir)           FAST_HIGHLIGHT[subversion-option-argument]=any;;
                    --revision|-r)          FAST_HIGHLIGHT[subversion-option-argument]=revision-pair;;
                esac
                ;;
            svndumpfilter/*)
                case $__wrd in
                    --targets) FAST_HIGHLIGHT[subversion-option-argument]=any;;
                esac
                ;;
        esac
    elif [[ -n $FAST_HIGHLIGHT[subversion-option-argument] ]]; then
        case $FAST_HIGHLIGHT[subversion-option-argument] in
            any)
                FAST_HIGHLIGHT[subversion-option-argument]=
                return 1
                ;;
            accept)
                [[ $__wrd = (p(|ostpone)|e(|dit)|l(|aunch)|base|working|recommended|[mt][cf]|(mine|theirs)-(conflict|full)) ]] \
                    && __style=${FAST_THEME_NAME}correct-subtle \
                    || __style=${FAST_THEME_NAME}incorrect-subtle
                ;;
            depth)
                [[ $__wrd = (empty|files|immediates|infinity) ]] \
                    && __style=${FAST_THEME_NAME}correct-subtle \
                    || __style=${FAST_THEME_NAME}incorrect-subtle
                ;;
            number)
                [[ $__wrd = [0-9]## ]] \
                    && __style=${FAST_THEME_NAME}mathnum \
                    || __style=${FAST_THEME_NAME}incorrect-subtle
                ;;
            eol)
                [[ $__wrd = (CR(|LF)|LF) ]] \
                    && __style=${FAST_THEME_NAME}correct-subtle \
                    || __style=${FAST_THEME_NAME}incorrect-subtle
                ;;
            show-revs)
                [[ $__wrd = (merged|eligible) ]] \
                    && __style=${FAST_THEME_NAME}correct-subtle \
                    || __style=${FAST_THEME_NAME}incorrect-subtle
                ;;
            revision)
                →chroma/-subversion.ch/parse-revision $__wrd $__start_pos $__end_pos
                ;;
            revision-pair)
                local -a match mbegin mend
                if [[ $__wrd = (#b)(\{[^}]##\}|[^:]##)(:)(*) ]]; then
                    →chroma/-subversion.ch/parse-revision $match[1] $__start_pos $(( __end_pos - ( mend[3]-mend[2] ) - 1 ))
                    →chroma/-subversion.ch/parse-revision $match[3] $(( __start_pos + ( mbegin[3]-mbegin[1] ) )) $__end_pos
                    (( __start=__start_pos-${#PREBUFFER}+(mbegin[2]-mbegin[1]), __end=__end_pos-${#PREBUFFER}-(mend[3]-mend[2]), __start >= 0 )) \
                        && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}for-loop-separator]}")
                else
                    →chroma/-subversion.ch/parse-revision $__wrd $__start_pos $__end_pos
                fi
                ;;
            target)
                →chroma/-subversion.ch/parse-target $__wrd $__start_pos $__end_pos || return $?
                ;;
            cmd)
                this_word=1
                return 1
                ;;
        esac
        FAST_HIGHLIGHT[subversion-option-argument]=
    elif [[ -z $FAST_HIGHLIGHT[subversion-subcommand] ]]
    then
        FAST_HIGHLIGHT[subversion-subcommand]=$__wrd
        local subcmds
        case $FAST_HIGHLIGHT[subversion-command] in
            svn) subcmds='(add|auth|blame|praise|annotate|ann|cat|changelist|cl|checkout|co|cleanup|commit|ci|copy|cp|delete|del|remove|rm|diff|di|export|help|\?|h|import|info|list|ls|lock|log|merge|mergeinfo|mkdir|move|mv|rename|ren|patch|propdel|pdel|pd|propedit|pedit|pe|propget|pget|pg|proplist|plist|pl|propset|pset|ps|relocate|resolve|resolved|revert|status|stat|st|switch|sw|unlock|update|up|upgrade|x-shelf-diff|x-shelf-drop|x-shelf-list|x-shelves|x-shelf-list-by-paths|x-shelf-log|x-shelf-save|x-shelve|x-unshelve)' ;;
            svnadmin) subcmds="(crashtest|create|delrevprop|deltify|dump|dump-revprops|freeze|help|\?|h|hotcopy|info|list-dblogs|list-unused-dblogs|load|load-revprops|lock|lslocks|lstxns|pack|recover|rmlocks|rmtxns|setlog|setrevprop|setuuid|unlock|upgrade|verify)";;
            svndumpfilter) subcmds='(include|exclude|help|\?)';;
        esac
        [[ $FAST_HIGHLIGHT[subversion-subcommand] = $~subcmds ]] \
            && __style=${FAST_THEME_NAME}subcommand \
            || __style=${FAST_THEME_NAME}incorrect-subtle
        FAST_HIGHLIGHT[subversion-subcommand-arguments]=0
    else
        (( FAST_HIGHLIGHT[subversion-subcommand-arguments]+=1 ))
        if [[ ( $FAST_HIGHLIGHT[subversion-subcommand] == (checkout|co|export|log|merge|switch|sw) && $FAST_HIGHLIGHT[subversion-subcommand-arguments] -eq 1 ) \
                  || $FAST_HIGHLIGHT[subversion-subcommand] == (blame|praise|annotate|ann|cat|copy|cp|diff|info|list|ls|mergeinfo) ]]; then
            →chroma/-subversion.ch/parse-target $__wrd $__start_pos $__end_pos || return $?
        else
            return 1
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
