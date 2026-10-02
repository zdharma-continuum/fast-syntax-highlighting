#!/usr/bin/env zsh

emulate -L zsh
setopt no_unset pipe_fail
zmodload zsh/zpty

local repo_dir=${FSH_TEST_REPO:-${0:A:h:h}}
local scenario=${1:-before}
local zdotdir
local output chunk i result=timeout
local pty_name=fsh-zle-line-finish

case $scenario in
  before|delayed|reload|no-zle|direct|fallback) ;;
  *) print -ru2 -- "Unknown scenario: $scenario"; return 1 ;;
esac

zdotdir=$(mktemp -d "${TMPDIR:-/tmp}/fsh-zle-line-finish.XXXXXXXX") || return 1

{
  {
    print -r -- 'FUNCNEST=50'
    print -r -- "PS1='FSH_TEST> '; PS2=''"
    print -r -- 'bindkey >/dev/null'
    print -r -- "FAST_WORK_DIR=${(q)zdotdir}"
    print -r -- 'typeset -gi before_calls=0 after_calls=0 highlight_calls=0'
    print -r -- 'before_hook() { (( ++before_calls )); }'
    print -r -- 'after_hook() { (( ++after_calls )); }'
    if [[ $scenario == fallback ]]; then
      print -r -- 'add-zle-hook-widget() { return 1; }'
    else
      print -r -- 'autoload -Uz add-zle-hook-widget'
    fi
    if [[ $scenario == before || $scenario == reload || $scenario == no-zle ]]; then
      print -r -- 'add-zle-hook-widget line-finish before_hook'
    elif [[ $scenario == direct ]]; then
      print -r -- 'zle -N zle-line-finish before_hook'
    fi
    [[ $scenario == no-zle ]] && print -r -- 'unsetopt zle'
    print -r -- "source ${(q)repo_dir}/fast-syntax-highlighting.plugin.zsh"
    [[ $scenario == no-zle ]] && print -r -- 'setopt zle'
    if [[ $scenario != fallback ]]; then
      print -r -- 'deferred_hooks() { add-zle-hook-widget line-init after_hook; add-zle-hook-widget line-finish after_hook; }'
      print -r -- 'autoload -Uz add-zsh-hook; add-zsh-hook precmd deferred_hooks'
    fi
    [[ $scenario == reload ]] && print -r -- "source ${(q)repo_dir}/fast-syntax-highlighting.plugin.zsh"
    print -r -- 'functions[_fsh_test_highlight]=$functions[_zsh_highlight]'
    print -r -- '_zsh_highlight() { [[ $WIDGET != zle-line-finish ]] || (( ++highlight_calls )); _fsh_test_highlight; }'
  } >| "$zdotdir/.zshrc"

  zpty -b $pty_name env -i \
    HOME="$zdotdir" ZDOTDIR="$zdotdir" TERM=xterm-256color PATH="$PATH" zsh -i

  for i in {1..200}; do
    chunk=''
    zpty -r $pty_name chunk 2>/dev/null && output+=$chunk
    [[ $output == *'FSH_TEST> '* ]] && break
    sleep 0.025
  done
  if [[ $output == *'FSH_TEST> '* ]]; then
    zpty -w $pty_name "printf '\n%s%s:%d:%d:%d\n' '__FSH_' 'DONE__' \"\$before_calls\" \"\$after_calls\" \"\$highlight_calls\""$'\n'
    for i in {1..200}; do
      chunk=''
      zpty -r $pty_name chunk 2>/dev/null && output+=$chunk
      if [[ $output == *'maximum nested function level reached'* ]]; then
        result=recursion-error
        break
      elif [[ $output == *'__FSH_DONE__:'*$'\n'* ]]; then
        local expected_before=0 expected_after=2
        [[ $scenario == before || $scenario == reload || $scenario == no-zle || $scenario == direct ]] && expected_before=1
        [[ $scenario == fallback ]] && expected_after=0
        local expected="__FSH_DONE__:$expected_before:$expected_after:1"
        if [[ $output == *"$expected"$'\r\n'* || $output == *"$expected"$'\n'* ]]; then
          result=ok
        else
          result=incorrect-hook-counts
        fi
        break
      fi
      sleep 0.025
    done
  fi
} always {
  zpty -d $pty_name 2>/dev/null || true
  rm -rf -- "$zdotdir"
}

if [[ $result != ok ]]; then
  print -r -- "$output"
  print -ru2 -- "zle-line-finish regression result ($scenario): $result"
  return 1
fi

print -r -- "$result"
