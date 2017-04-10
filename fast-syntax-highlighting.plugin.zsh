# -------------------------------------------------------------------------------------------------
# Copyright (c) 2010-2016 zsh-syntax-highlighting contributors
# Copyright (c) 2017 Sebastian Gniazdowski (modifications)
# All rights reserved.
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
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------


# Set $ZERO to the expected value, regardless of functionargzero.
typeset -g ZERO=${(%):-%N}

# Invokes each highlighter that needs updating.
# This function is supposed to be called whenever the ZLE state changes.
_zsh_highlight()
{
  # Store the previous command return code to restore it whatever happens.
  local ret=$?

  # Remove all highlighting in isearch, so that only the underlining done by zsh itself remains.
  # For details see FAQ entry 'Why does syntax highlighting not work while searching history?'.
  if [[ $WIDGET == zle-isearch-update ]] && ! (( $+ISEARCHMATCH_ACTIVE )); then
    region_highlight=()
    return $ret
  fi

  setopt localoptions warncreateglobal noksharrays
  local REPLY # don't leak $REPLY into global scope
  local -a reply

  # Do not highlight if there are more than 300 chars in the buffer. It's most
  # likely a pasted command or a huge list of files in that case..
  [[ -n ${ZSH_HIGHLIGHT_MAXLENGTH:-} ]] && [[ $#BUFFER -gt $ZSH_HIGHLIGHT_MAXLENGTH ]] && return $ret

  # Do not highlight if there are pending inputs (copy/paste).
  [[ $PENDING -gt 0 ]] && return $ret

  # Reset region highlight to build it from scratch
  # may need to remove path_prefix highlighting when the line ends
  if [[ $WIDGET == zle-line-finish ]] || _zsh_highlight_buffer_modified; then
      -fast-highlight-init
      -fast-highlight-process && region_highlight=( $reply ) || region_highlight=()
  fi

  {
    local cache_place
    local -a region_highlight_copy

    # Re-apply zle_highlight settings

    # region
    if (( REGION_ACTIVE == 1 )); then
      _zsh_highlight_apply_zle_highlight region standout "$MARK" "$CURSOR"
    elif (( REGION_ACTIVE == 2 )); then
      () {
        local needle=$'\n'
        integer min max
        if (( MARK > CURSOR )) ; then
          min=$CURSOR max=$MARK
        else
          min=$MARK max=$CURSOR
        fi
        (( min = ${${BUFFER[1,$min]}[(I)$needle]} ))
        (( max += ${${BUFFER:($max-1)}[(i)$needle]} - 1 ))
        _zsh_highlight_apply_zle_highlight region standout "$min" "$max"
      }
    fi

    # yank / paste (zsh-5.1.1 and newer)
    (( $+YANK_ACTIVE )) && (( YANK_ACTIVE )) && _zsh_highlight_apply_zle_highlight paste standout "$YANK_START" "$YANK_END"

    # isearch
    (( $+ISEARCHMATCH_ACTIVE )) && (( ISEARCHMATCH_ACTIVE )) && _zsh_highlight_apply_zle_highlight isearch underline "$ISEARCHMATCH_START" "$ISEARCHMATCH_END"

    # suffix
    (( $+SUFFIX_ACTIVE )) && (( SUFFIX_ACTIVE )) && _zsh_highlight_apply_zle_highlight suffix bold "$SUFFIX_START" "$SUFFIX_END"

    return $ret

  } always {
    typeset -g _ZSH_HIGHLIGHT_PRIOR_BUFFER="$BUFFER"
    typeset -gi _ZSH_HIGHLIGHT_PRIOR_CURSOR=$CURSOR
  }
}

# Apply highlighting based on entries in the zle_highlight array.
# This function takes four arguments:
# 1. The exact entry (no patterns) in the zle_highlight array:
#    region, paste, isearch, or suffix
# 2. The default highlighting that should be applied if the entry is unset
# 3. and 4. Two integer values describing the beginning and end of the
#    range. The order does not matter.
_zsh_highlight_apply_zle_highlight() {
  local entry="$1" default="$2"
  integer first="$3" second="$4"

  # read the relevant entry from zle_highlight
  local region="${zle_highlight[(r)${entry}:*]}"

  if [[ -z "$region" ]]; then
    # entry not specified at all, use default value
    region=$default
  else
    # strip prefix
    region="${region#${entry}:}"

    # no highlighting when set to the empty string or to 'none'
    if [[ -z "$region" ]] || [[ "$region" == none ]]; then
      return
    fi
  fi

  integer start end
  if (( first < second )); then
    start=$first end=$second
  else
    start=$second end=$first
  fi
  region_highlight+=("$start $end $region")
}


# -------------------------------------------------------------------------------------------------
# API/utility functions for highlighters
# -------------------------------------------------------------------------------------------------

# Whether the command line buffer has been modified or not.
#
# Returns 0 if the buffer has changed since _zsh_highlight was last called.
_zsh_highlight_buffer_modified()
{
  [[ "${_ZSH_HIGHLIGHT_PRIOR_BUFFER:-}" != "$BUFFER" ]]
}

# Whether the cursor has moved or not.
#
# Returns 0 if the cursor has moved since _zsh_highlight was last called.
_zsh_highlight_cursor_moved()
{
  [[ -n $CURSOR ]] && [[ -n ${_ZSH_HIGHLIGHT_PRIOR_CURSOR-} ]] && (($_ZSH_HIGHLIGHT_PRIOR_CURSOR != $CURSOR))
}

# -------------------------------------------------------------------------------------------------
# Setup functions
# -------------------------------------------------------------------------------------------------

# Helper for _zsh_highlight_bind_widgets
# $1 is name of widget to call
_zsh_highlight_call_widget()
{
  builtin zle "$@" && _zsh_highlight
}

# Rebind all ZLE widgets to make them invoke _zsh_highlights.
_zsh_highlight_bind_widgets()
{
  setopt localoptions noksharrays
  typeset -F SECONDS
  local prefix=orig-s$SECONDS-r$RANDOM # unique each time, in case we're sourced more than once

  # Load ZSH module zsh/zleparameter, needed to override user defined widgets.
  zmodload zsh/zleparameter 2>/dev/null || {
    print -r -- >&2 'zsh-syntax-highlighting: failed loading zsh/zleparameter.'
    return 1
  }

  # Override ZLE widgets to make them invoke _zsh_highlight.
  local -U widgets_to_bind
  widgets_to_bind=(${${(k)widgets}:#(.*|run-help|which-command|beep|set-local-history|yank)})

  # Always wrap special zle-line-finish widget. This is needed to decide if the
  # current line ends and special highlighting logic needs to be applied.
  # E.g. remove cursor imprint, don't highlight partial paths, ...
  widgets_to_bind+=(zle-line-finish)

  # Always wrap special zle-isearch-update widget to be notified of updates in isearch.
  # This is needed because we need to disable highlighting in that case.
  widgets_to_bind+=(zle-isearch-update)

  local cur_widget
  for cur_widget in $widgets_to_bind; do
    case $widgets[$cur_widget] in

      # Already rebound event: do nothing.
      user:_zsh_highlight_widget_*);;

      # The "eval"'s are required to make $cur_widget a closure: the value of the parameter at function
      # definition time is used.
      #
      # We can't use ${0/_zsh_highlight_widget_} because these widgets are always invoked with
      # NO_function_argzero, regardless of the option's setting here.

      # User defined widget: override and rebind old one with prefix "orig-".
      user:*) zle -N $prefix-$cur_widget ${widgets[$cur_widget]#*:}
              eval "_zsh_highlight_widget_${(q)prefix}-${(q)cur_widget}() { _zsh_highlight_call_widget ${(q)prefix}-${(q)cur_widget} -- \"\$@\" }"
              zle -N $cur_widget _zsh_highlight_widget_$prefix-$cur_widget;;

      # Completion widget: override and rebind old one with prefix "orig-".
      completion:*) zle -C $prefix-$cur_widget ${${(s.:.)widgets[$cur_widget]}[2,3]} 
                    eval "_zsh_highlight_widget_${(q)prefix}-${(q)cur_widget}() { _zsh_highlight_call_widget ${(q)prefix}-${(q)cur_widget} -- \"\$@\" }"
                    zle -N $cur_widget _zsh_highlight_widget_$prefix-$cur_widget;;

      # Builtin widget: override and make it call the builtin ".widget".
      builtin) eval "_zsh_highlight_widget_${(q)prefix}-${(q)cur_widget}() { _zsh_highlight_call_widget .${(q)cur_widget} -- \"\$@\" }"
               zle -N $cur_widget _zsh_highlight_widget_$prefix-$cur_widget;;

      # Incomplete or nonexistent widget: Bind to z-sy-h directly.
      *) 
         if [[ $cur_widget == zle-* ]] && [[ -z $widgets[$cur_widget] ]]; then
           _zsh_highlight_widget_${cur_widget}() { :; _zsh_highlight }
           zle -N $cur_widget _zsh_highlight_widget_$cur_widget
         else
      # Default: unhandled case.
           print -r -- >&2 "zsh-syntax-highlighting: unhandled ZLE widget ${(qq)cur_widget}"
         fi
    esac
  done
}

# -------------------------------------------------------------------------------------------------
# Setup
# -------------------------------------------------------------------------------------------------

# Try binding widgets.
_zsh_highlight_bind_widgets || {
  print -r -- >&2 'zsh-syntax-highlighting: failed binding ZLE widgets, exiting.'
  return 1
}

# Reset scratch variables when commandline is done.
_zsh_highlight_preexec_hook()
{
  typeset -g _ZSH_HIGHLIGHT_PRIOR_BUFFER=
  typeset -gi _ZSH_HIGHLIGHT_PRIOR_CURSOR=0
}

autoload -U add-zsh-hook
add-zsh-hook preexec _zsh_highlight_preexec_hook 2>/dev/null || {
    print -r -- >&2 'zsh-syntax-highlighting: failed loading add-zsh-hook.'
}

# Load zsh/parameter module if available
zmodload zsh/parameter 2>/dev/null

autoload -U is-at-least 
source "${ZERO:h}/fast-highlight"

[[ "${+termcap[Co]}" = 1 && "${termcap[Co]}" = "256" ]] && FAST_HIGHLIGHT_STYLES[variable]="fg=112"

-fast-highlight-fill-option-variables
