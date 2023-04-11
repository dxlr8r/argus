#!/bin/sh
# Name: argus
# Version: 0.2.1
# Copyright (c) 2022, Simen Strange
# License: Modified BSD license
# https://github.com/dxlr8r/argus/blob/master/LICENSE

# shellcheck disable=SC2154

# escape newlines and tabs
esc() {
  printf '%b' "$1" | sed 's/\\/\\&/g' | awk -v RS='\t' -v ORS='\\t' 1 | awk -v ORS='\\n' 1 | awk '{ printf substr($0, 1, length($0)-4) }'
}

# un/de escape escaped sequences
unesc() {
  if test "$#" -gt 0; then
    printf '%b' "$@"
  else
    printf '%b' "$(cat)"
  fi
}

_tab_key() {
  printf '%s' "$1" "$(test -z "$1" || printf ' ')" | tr ' ' '\t'
}

# add_value my_argus 'a b' 'hello'
add_value() {
  # if neither is defined, return
  printf '%s\t' "${2}${3}" | grep -Eqv '^[[:space:]]+$' || return 1
  # subshell to keep variables local
  _() (
    # set obj to variable named $1
    eval obj=\$"$1"
    key=$(printf '%s' "$2" | tr ' ' '\t')
    value=$(esc "$3")
    nl='\n'
    
    test -n "$obj" || nl=''
    printf "%s${nl}%s\t%s\n" "$obj" "$key" "$value"
  )
  # set variable named $1 to $value
  if test "$#" -eq 3; then
    eval "$1"'=$(_ "$1" "$2" "$3")'
  else
    eval "$1"'=$(_ "$1" "$2" "$(cat)")'
  fi
}

# like grep -v, but more suited handling of exit signals
_grepv() (
  pat=$(printf '%s\n' "$1" | sed 's/Fx/==/' | sed 's/E/~/')
  cat | awk -v haystack="$2" 'BEGIN { needle=0 }; { if ($0 '"$pat"' haystack ) { needle=1 } else { print }}; END { exit !needle }'
)

# rm_key my_argus 'a'
rm_key() {
  _() (
    eval obj=\$"$1"
    key=$(_tab_key "$2")

    # printf '%s' "$obj" | grep -vE "^$key"
    printf '%s' "$obj" | _grepv E "^$key"
  )
  eval "$1"'=$(_ "$1" "$2")'
}

# rm_value my_argus 'a b' 'hello'
rm_value() {
  _() (
    eval obj=\$"$1"
    key=$(_tab_key "$2")
    value=$3

    # printf '%s' "$obj" | grep -Fvx "${key}${value}"
    printf '%s' "$obj" | _grepv Fx "${key}${value}"
  )
  eval "$1"'=$(_ "$1" "$2" "$3")'
}

# rmx_value my_argus 'a b' 'he.*'
rmx_value() {
  _() (
    eval obj=\$"$1"
    key=$(_tab_key "$2")
    value=$(printf '%s' "$3" | sed 's/\\/\\&/g')

    # printf '%s' "$obj" | grep -vE "^${key}${value}\$"
    printf '%s' "$obj" | _grepv E "^${key}${value}\$"
  )
  eval "$1"'=$(_ "$1" "$2" "$3")'
}

# rm_item my_argus 'a b' 1
rm_item() {
  _() (
    eval obj=\$"$1"
    key=$(_tab_key "$2")
    item=$3

    needle=$(printf '%s' "$obj" | grep -E "^$key" | awk -v item="$item" '{ if (NR == item ) { print } }')
    # printf '%s' "$obj" | grep -Fvx "$needle"
    printf '%s' "$obj" | _grepv Fx "$needle"
  )
  eval "$1"'=$(_ "$1" "$2" "$3")'
}

# get_value my_argus 'a'
get_value() (
  eval obj=\$"$1"
  key=$(_tab_key "$2")
  keys=$(printf '%s' "$key" | tr '\t' '\n' | wc -l)
  printf '%s' "$obj" | grep -E "^${key}" | awk -v keys="$keys" -v FS='\t' '{if (NF == keys+1) { print $NF }} END { exit !NR }'
)

# get_pair my_argus 'a'
get_pair() (
  eval obj=\$"$1"
  key=$(_tab_key "$2")
  printf '%s' "$obj" | grep -E "^$key" | awk -v key="$key" '{print substr($0, length(key)+1) }' | awk -v FS='\t' '{print $1} END { exit !NR }'
)

# get_tail my_argus 'a b'
get_tail() (
  eval obj=\$"$1"
  key=$(_tab_key "$2")
  printf '%s' "$obj" | grep -E "^$key" | awk -v key="$key" '{print substr($0, length(key)+1) } END { exit !NR }'
)

# get my_argus 'a b'
get() (
  eval obj=\$"$1"
  key=$(_tab_key "$2")
  printf '%s' "$obj" | grep -E "^$key"
)
