#!/bin/sh

#
# This file runs the highlighter on a specified file
# i.e. parses the file with the highlighter. Outputs
# running time (stderr) and resulting region_highlight
# (file parse.out, or $2 if given).
#
# Can be also run in line-wise mode on own input (-o
# option in $1), no region_highlight file then.
#

[[ -z "$ZSH_VERSION" ]] && exec /usr/bin/env /usr/local/bin/zsh-5.4.2-dev-0 -f -c "source \"$0\" \"$1\" \"$2\" \"$3\""

ZERO="${(%):-%N}"

if [[ -e "${ZERO}/../fast-highlight" ]]; then
    source "${ZERO}/../fast-highlight"
    fpath+=( "${ZERO}/.." )
elif [[ -e "../fast-highlight" ]]; then
    source "../fast-highlight"
    fpath+=( "$PWD/.." )
elif [[ -e "${ZERO}/fast-highlight" ]]; then
    source "${ZERO}/fast-highlight"
    fpath+=( "${ZERO}" )
elif [[ -e "./fast-highlight" ]]; then
    source "./fast-highlight"
    fpath+=( "./" )
else
    print -u2 "Could not find fast-highlight, aborting"
    exit 1
fi

zmodload zsh/zprof
autoload is-at-least chroma/-git.ch

setopt interactive_comments

# Own input?
if [[ "$1" = "-o" || "$1" = "-oo" || "$1" = "-ooo" || "$1" = "-git" ]]; then
    typeset -a input
    if [[ "$1" = "-o" ]]; then
        input+=( "./parse.zsh ../fast-highlight parse2.out" )
        input+=( "rm -f parse*.out" )
        input+=( "./mh-parse.zsh ../fast-highlight > out" )
        input+=( "if [[ -o multibyte ]]; then echo multibyte is set; fi" )
        input+=( "[[ \"a\" = *[[:alpha:]_-][[:alpha:]]# ]] && echo yes" )
        input+=( 'git tag -a v0.98 -m "Syntax highlighting of the history entries"' )
        input+=( 'func() { echo "a" >! phist2.db; echo "b" >>! phist2.db; fc -Rap "phist2.db"; list=( ${history[@]} ); echo "${history[1]}"; }' )
    elif [[ "$1" = "-oo" ]]; then
        input+=( 'typeset -a list\n() {\necho "a" >! phist2.db\necho "b" >>! phist2.db\nfc -Rap "phist2.db"\nlist=( ${history[@]} )\necho "${history[2]}"\necho "${history[1]}"\necho "${#history}";\ninteger size="${#history}"\nsize+=1\necho "$size" / "${history[$size]}"\nlist=( "${history[$size]}" ${history[@]} )\n}' )
        input+=( 'typeset -a list\n() {\necho "a" >! phist2.db\necho "b" >>! phist2.db\nfc -Rap "phist2.db"\nlist=( ${history[@]} )\necho "${history[2]}"\necho "${history[1]}"\necho "${#history}";\ninteger size="${#history}"\nsize+=1\necho "$size" / "${history[$size]}"\nlist=( "${history[$size]}" ${history[@]} )\n}' )
        input+=( 'typeset -a list\n() {\necho "a" >! phist2.db\necho "b" >>! phist2.db\nfc -Rap "phist2.db"\nlist=( ${history[@]} )\necho "${history[2]}"\necho "${history[1]}"\necho "${#history}";\ninteger size="${#history}"\nsize+=1\necho "$size" / "${history[$size]}"\nlist=( "${history[$size]}" ${history[@]} )\n}' )
        input+=( 'typeset -a list\n() {\necho "a" >! phist2.db\necho "b" >>! phist2.db\nfc -Rap "phist2.db"\nlist=( ${history[@]} )\necho "${history[2]}"\necho "${history[1]}"\necho "${#history}";\ninteger size="${#history}"\nsize+=1\necho "$size" / "${history[$size]}"\nlist=( "${history[$size]}" ${history[@]} )\n}' )
        input+=( 'typeset -a list\n() {\necho "a" >! phist2.db\necho "b" >>! phist2.db\nfc -Rap "phist2.db"\nlist=( ${history[@]} )\necho "${history[2]}"\necho "${history[1]}"\necho "${#history}";\ninteger size="${#history}"\nsize+=1\necho "$size" / "${history[$size]}"\nlist=( "${history[$size]}" ${history[@]} )\n}' )
        input+=( 'typeset -a list\n() {\necho "a" >! phist2.db\necho "b" >>! phist2.db\nfc -Rap "phist2.db"\nlist=( ${history[@]} )\necho "${history[2]}"\necho "${history[1]}"\necho "${#history}";\ninteger size="${#history}"\nsize+=1\necho "$size" / "${history[$size]}"\nlist=( "${history[$size]}" ${history[@]} )\n}' )
        input+=( 'typeset -a list\n() {\necho "a" >! phist2.db\necho "b" >>! phist2.db\nfc -Rap "phist2.db"\nlist=( ${history[@]} )\necho "${history[2]}"\necho "${history[1]}"\necho "${#history}";\ninteger size="${#history}"\nsize+=1\necho "$size" / "${history[$size]}"\nlist=( "${history[$size]}" ${history[@]} )\n}' )
    elif [[ "$1" = "-ooo" ]]; then
        local in='
# This is an example code that is diverse and allows to test a theme
text="An example quite long string $with variable in it"
local param1="text $variable" param2='"'"'other $variable'"'"'
math=$(( 10 + HISTSIZ + HISTSIZE + $SAVEHIST )) size=$(( 0 ))

for (( ii = 1; ii <= size; ++ ii )); do
    if [[ "${cmds[ii]} string" = "| string" ]]
    then
        sidx=${buffer[(in:ii:)\$\(?#[^\\\\]\)]} # find opening $(
        (( sidx <= len )) && {
            eidx=${buffer[(b:sidx:ii)[^\\\\]\)]} # find closing )
        }
    fi
done'
        input+=( "$in" )
        input+=( "$in" )
    elif [[ "$1" = "-git" ]]; then
        local in="git lp
git push origin master
  git commit
git add safari.ini zdharma.ini
git st .
git diff --cached
git commit --allow-empty
git checkout themes/zdharma.ini
git commit --amend
git tag -a 'v1.18' -m 'Here-string is highlighted, descriptor-variables passed to exec are correctly highlighted'
git tag -l -n9
git checkout cb66b11
"
        input+=( "$in" )
        input+=( "$in" )
    fi

    typeset -a long_input
    integer i
    for (( i=1; i<= 50; i ++ )); do
        long_input+=( "${input[@]}" )
    done

    typeset -F SECONDS
    SECONDS=0

    -fast-highlight-init

    local right_brace_is_recognised_everywhere
    integer path_dirs_was_set multi_func_def ointeractive_comments
    -fast-highlight-fill-option-variables

    local BUFFER
    for BUFFER in "${long_input[@]}"; do
        reply=( )
        -fast-highlight-process "" "$BUFFER" "0"
    done

    print "Running time: $SECONDS"
    zprof | head
# File input?
elif [[ -r "$1" ]]; then
    # Load from given file
    local BUFFER="$(<$1)"

    typeset -F SECONDS
    SECONDS=0

    reply=( )
    -fast-highlight-init

    local right_brace_is_recognised_everywhere
    integer path_dirs_was_set multi_func_def ointeractive_comments
    -fast-highlight-fill-option-variables

    -fast-highlight-process "" "$BUFFER" "0"

    print "Running time: $SECONDS"
    zprof | head

    # This output can be diffed to detect changes in operation
    if [[ -z "$2" ]]; then
        print -rl -- "${reply[@]}" >! out.parse
    else
        print -rl -- "${reply[@]}" >! "$2"
    fi
else
    if [[ -z "$1" ]]; then
        print -u2 "Usage: ./parse.zsh {to-parse file} [region_highlight output file]"
        exit 2
    else
        print -u2 "Unreadable to-parse file \`$1', aborting"
        exit 3
    fi
fi

exit 0

# vim:ft=zsh
