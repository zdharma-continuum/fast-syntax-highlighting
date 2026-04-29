#!/usr/bin/env zsh

emulate -L zsh
setopt no_unset pipe_fail
zmodload zsh/zpty

local repo_dir=${0:A:h:h}
local zdotdir=${TMPDIR:-/tmp}/fsh-zle-line-finish-$$
local marker='__FSH_ZLE_LINE_FINISH_DONE__'
local output chunk i result=timeout

mkdir -p "$zdotdir"

{
  print -r -- 'FUNCNEST=50'
  print -r -- "PS1='FSH_TEST> '"
  print -r -- 'bindkey >/dev/null'
  print -r -- 'autoload -Uz add-zle-hook-widget'
  print -r -- 'before_hook() { :; }'
  print -r -- 'after_hook() { :; }'
  print -r -- 'add-zle-hook-widget line-finish before_hook'
  print -r -- "source ${(q)repo_dir}/fast-syntax-highlighting.plugin.zsh"
  print -r -- 'add-zle-hook-widget line-finish after_hook'
} >| "$zdotdir/.zshrc"

zpty -d fsh-zle-line-finish 2>/dev/null || true
zpty fsh-zle-line-finish env -i \
  HOME="$HOME" \
  ZDOTDIR="$zdotdir" \
  TERM=xterm-256color \
  PATH="$PATH" \
  zsh -i

zpty -r fsh-zle-line-finish chunk '*FSH_TEST> *' 2>/dev/null || true
output+=$chunk

zpty -w fsh-zle-line-finish "echo $marker"$'\n'
for i in {1..40}; do
  zpty -r fsh-zle-line-finish chunk '*FSH_TEST> *' 2>/dev/null || true
  output+=$chunk

  if [[ "$output" == *'maximum nested function level reached'* ]]; then
    result=recursion-error
    break
  elif [[ "$output" == *"$marker"* ]]; then
    result=ok
    break
  fi

  sleep 0.05
done

zpty -w fsh-zle-line-finish 'exit'$'\n' 2>/dev/null || true
zpty -d fsh-zle-line-finish 2>/dev/null || true
rm -rf "$zdotdir"

if [[ "$result" != ok ]]; then
  print -r -- "$output"
  print -ru2 -- "zle-line-finish regression result: $result"
  return 1
fi

print -r -- "$result"
