#!/usr/bin/env zsh
# Regression coverage for https://github.com/zdharma-continuum/fast-syntax-highlighting/issues/78
# Highlighting `git diff "$(cmd)"` must not run cmd, and quotes must keep
# their normal styles. Run with: zsh tests/issue-78.zsh
emulate -L zsh
setopt extendedglob noerrexit nomatch

0=${${(%):-%x}:a}
PLUGIN=${0:h:h}
repo=$(mktemp -d)
marker_dir=$(mktemp -d)
fail=0

cleanup() { rm -rf "$repo" "$marker_dir"; }
trap cleanup EXIT

cd "$repo" || exit 1
git init -q
git config user.email test@example.com
git config user.name test
print hello > file.txt
git add file.txt
git commit -q -m init

FAST_WORK_DIR=$marker_dir
touch "$marker_dir/secondary_theme.zsh"
fpath=($PLUGIN $fpath)
autoload -Uz .fast-run-git-command .fast-run-command →chroma/-git.ch →chroma/main-chroma.ch
source "$PLUGIN/fast-highlight"
-fast-highlight-fill-option-variables
-fast-highlight-init
PREBUFFER=""

ok() { print -r -- "OK: $*"; }
bad() { print -r -- "FAIL: $*"; fail=1; }

# Highlight the same buffer several times. The bug ran the substitution on
# every pass after the first.
exec_count() {
    local buffer="$1" marker="$2" i
    rm -f "$marker"
    for i in 1 2 3 4; do
        reply=()
        BUFFER="$buffer"
        -fast-highlight-process "$PREBUFFER" "$BUFFER" 0
    done
    [[ -f $marker ]] && wc -l < "$marker" || print 0
}

highlight() {
    reply=()
    BUFFER="$1"
    -fast-highlight-process "$PREBUFFER" "$BUFFER" 0
    reply=()
    -fast-highlight-process "$PREBUFFER" "$BUFFER" 0
}

region_has() {
    local want="$1" line
    for line in "${reply[@]}"; do
        [[ $line == *" $want" ]] && return 0
    done
    return 1
}

payload='$(print x >> '"$marker_dir"'/double)'
n=$(exec_count "git diff \"$payload\"" "$marker_dir/double")
[[ $n == 0 ]] && ok "double-quoted substitution not executed" || bad "double-quoted substitution ran $n time(s)"

payload='$(print x >> '"$marker_dir"'/single)'
n=$(exec_count "git diff '$payload'" "$marker_dir/single")
[[ $n == 0 ]] && ok "single-quoted substitution not executed" || bad "single-quoted substitution ran $n time(s)"

payload='$(print x >> '"$marker_dir"'/bare)'
n=$(exec_count "git diff $payload" "$marker_dir/bare")
[[ $n == 0 ]] && ok "bare substitution not executed" || bad "bare substitution ran $n time(s)"

payload='`print x >> '"$marker_dir"'/tick`'
n=$(exec_count "git diff $payload" "$marker_dir/tick")
[[ $n == 0 ]] && ok "backtick substitution not executed" || bad "backtick substitution ran $n time(s)"

for sub in checkout merge reset revert log tag; do
    payload='$(print x >> '"$marker_dir"'/'"$sub"')'
    n=$(exec_count "git $sub \"$payload\"" "$marker_dir/$sub")
    [[ $n == 0 ]] && ok "git $sub does not execute the substitution" || bad "git $sub executed it $n time(s)"
done

highlight 'git diff "$(fzf)"'
dq=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}double-quoted-argument]}
ddq=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}dollar-double-quoted-argument]}
cs=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}correct-subtle]}
inc=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}incorrect-subtle]}
region_has "$dq" && ok "double quotes keep double-quoted-argument" || bad "missing double-quoted style: ${reply[*]}"
region_has "$ddq" && ok "command substitution inside quotes keeps its style" || bad "missing substitution style: ${reply[*]}"
region_has "$inc" && bad "quoted substitution marked incorrect: ${reply[*]}" || ok "quoted substitution is not incorrect-subtle"

payload='$(fzf)'
highlight "git diff '$payload'"
sq=${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}single-quoted-argument]}
region_has "$sq" && ok "single quotes keep single-quoted-argument" || bad "missing single-quoted style: ${reply[*]}"
region_has "$inc" && bad "single-quoted substitution marked incorrect: ${reply[*]}" || ok "single-quoted substitution is not incorrect-subtle"

highlight 'git diff HEAD'
region_has "$cs" && ok "HEAD is still a correct revision" || bad "HEAD lost correct-subtle: ${reply[*]}"

highlight 'git diff "HEAD"'
region_has "$cs" && ok "quoted HEAD is still a correct revision" || bad "quoted HEAD lost correct-subtle: ${reply[*]}"

highlight 'git diff NOT_A_REVISION_zzz'
region_has "$inc" && ok "unknown revision is incorrect-subtle" || bad "unknown revision style: ${reply[*]}"

highlight 'git diff file.txt'
region_has "$cs" && ok "existing path is still accepted" || bad "file.txt style: ${reply[*]}"

# A cache key that itself contains a command substitution must not run it,
# on a miss or on a hit.
poison='chroma-poison-$(print x >> '"$marker_dir"'/poison)'
rm -f "$marker_dir/poison"
FAST_HIGHLIGHT[${poison}-cache]=
unset "FAST_HIGHLIGHT[${poison}-cache-born-at]"
.fast-run-git-command "git rev-parse --verify --quiet HEAD" "$poison" "" 10
.fast-run-git-command "git rev-parse --verify --quiet HEAD" "$poison" "" 10
[[ -f $marker_dir/poison ]] && bad "poisoned cache key was executed" || ok "poisoned cache key was not executed"

if (( fail )); then
    print FAIL
    exit 1
fi
print PASS
exit 0
