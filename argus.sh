#!/bin/sh
# Name: argus
# Version: 0.0.4
# Copyright (c) 2022, Simen Strange Øya
# License: Modified BSD license
# https://github.com/dxlr8r/argus/blob/master/LICENSE

# quote newlines and tabs
_quotew() {
  printf "$1" | sed 's/\\/\\&/g' | awk -v RS='\t' -v ORS='\\t' 1 | awk -v ORS='\\n' 1 | awk '{printf substr($0, 1, length($0)-4) }'
}

_tab_key() {
  printf '%s' $1 "$(test -z "$1" || printf ' ')" | tr ' ' '\t'
}

# add_value my_argus 'a b' 'hello'
add_value() {
  # subshell to keep variables local
  (
    # set obj to variable named $1
    eval obj=\$"$1"
    key=$(printf "$2" | tr ' ' '\t')
    value=$(_quotew "$3")
    nl='\n'
    
    test -n "$obj" || nl=''
    printf "%s${nl}%s\t%s\n" "$obj" "$key" "$value"
  ) | \
  {
    # set variable named $1 to $value
    eval "$1"'=$(cat)'
  }
}

# rm_key my_argus 'a'
rm_key() {
  # subshell to keep variables local
  (
    # set obj to variable named $1
    eval obj=\$"$1"
    key=$(_tab_key "$2")

    printf '%s' "$obj" | grep -vE "^$key"
  ) | \
  {
    # set variable named $1 to $value
    eval "$1"'=$(cat)'
  }
}

# rm_value my_argus 'a b' 'hello'
rm_value() {
  # subshell to keep variables local
  (
    # set obj to variable named $1
    eval obj=\$"$1"
    key=$(_tab_key "$2")
    value=$3

    printf '%s' "$obj" | grep -Fvx "${key}${value}"
  ) | \
  {
    # set variable named $1 to $value
    eval "$1"'=$(cat)'
  }
}

# rmx_value my_argus 'a b' 'he.*'
rmx_value() {
  # subshell to keep variables local
  (
    # set obj to variable named $1
    eval obj=\$"$1"
    key=$(_tab_key "$2")
    value=$(printf '%s' "$3" | sed 's/\\/\\&/g')

    printf '%s' "$obj" | grep -vE "^${key}${value}\$"
  ) | \
  {
    # set variable named $1 to $value
    eval "$1"'=$(cat)'
  }
}


# get_value my_argus 'a'
get_value() (
 eval obj=\$"$1"
 key=$(_tab_key "$2")
 printf '%s' "$obj" | grep -E "^$key" | awk -v FS='\t' '{print $NF}'
)

# get_pair my_argus 'a'
get_pair() (
  eval obj=\$"$1"
  key=$(_tab_key "$2")
  printf '%s' "$obj" | grep -E "^$key" | awk -v key="$key" '{print substr($0, length(key)+1) }' | awk -v FS='\t' '{print $1}'
)

# get my_argus 'a b'
get() (
  eval obj=\$"$1"
  key=$(_tab_key "$2")
  printf '%s' "$obj" | grep -E "^$key" | awk -v key="$key" '{print substr($0, length(key)+1) }'
)
