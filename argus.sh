#!/bin/sh
# SPDX-FileCopyrightText: 2022-2023 Simen Strange <https://github.com/dxlr8r/argus>
# SPDX-License-Identifier: MIT
# Version: 0.3.0-beta

# shellcheck disable=SC2154

# escape newlines and tabs
esc() {
  _() (
    printf '%s_' "$1" | sed 's/\\/\\&/g' | awk -v RS='\t' -v ORS='\\t' 1 | awk -v ORS='\\n' 1 | awk '{ printf substr($0, 1, length($0)-5) }'
  )
  if test "$#" -gt 0; then
    _ "$@"
  else
    _ "$(cat)"
  fi
}

# un/de escape escaped sequences
unesc() {
  if test "$#" -gt 0; then
    printf '%b' "$@"
  else
    printf '%b' "$(cat)"
  fi
}

_empty_or_ws() {
  while test "$#" -gt 0; do
    printf '%s' "$1" | awk '{if ($0 ~ /(^$|[[:space:]])/) exit 1} END {if (NR != 1) exit 1}'
    ret=$?; test $ret -gt 0 && return $ret
    shift
  done
}

_empty() {
  while test "$#" -gt 0; do
    test "$1" || return $?
    shift
  done
}

_tab_key() {
  printf '%s' "$1" "$(test -z "$1" || printf ' ')" | tr ' ' '\t'
}

# like grep -v, but more suited handling of exit signals
_grepv() (
  pat=$(printf '%s\n' "$1" | sed 's/Fx/==/' | sed 's/E/~/')
  cat | awk -v haystack="$2" 'BEGIN { needle=0 }; { if ($0 '"$pat"' haystack ) { needle=1 } else { print }}; END { exit !needle }'
)

_if_last_key_is_int_remove_it() {
  # first strip trailing tab from key, as value is not added. Then check if last key is an integer, if true remove last key
  awk -v key="$1" -v OFS='\t' 'BEGIN { $0 = key; sub(/[ \t]*$/, "", $0); if ($NF ~ /^[0-9]+$/) {$NF=""; print; exit 0} else {exit 1}}'
}

_ilist_add_or_rm() (
  action=$1
  key=$2
  value=$3
  obj=$4
  
  # number of columns of keys
  qty_keys=$(printf '%s' "$key" | tr '\t' '\n' | wc -l | tr -d ' ')
  rkey=$(_if_last_key_is_int_remove_it "$key")
  # regex=$(printf '^%s[0-9]+\\t' "$(esc "$rkey")" | sed 's/\\t/[[:blank:]]/g')
  regex="^${rkey}[0-9]+\t"
  
  # requested index of entry
  idx=$(printf '%s' "$key" | awk -v FS='\t' '{print $(NF-1)}')

  # determine the highest index currently available
  fallback_max_idx=$(printf '%s0\t\n' "$rkey")
  max_idx=$(printf '%s\n' "$fallback_max_idx" "$obj" | grep -E "$regex" | sort -nk$qty_keys | tail -n1 | \
    awk -v FS='\t' -v qty_keys="$qty_keys" '{print $(qty_keys)}')

  if test "$action" = "add"; then
    # increase rows
    alter_rows='
    {
      if ($0 ~ regex && $(qty_keys) >= idx)
        { $(qty_keys)=$(qty_keys)+1; print }
      else print
    }'
  fi
  
  if test "$action" = "rm"; then
    # decrease rows
    alter_rows='
    {
      if ($0 ~ regex && $(qty_keys) > idx)
        { $(qty_keys)=$(qty_keys)-1; print }
      else print
    }'
  fi

  # check if idx is valid if not replace with max_idx
  # if test $idx -gt $max_idx || test $idx -eq 0; then
  if test $idx -eq 0; then
    test "$action" = "add" && idx=$((max_idx+1)) || :
    test "$action" = "rm"  && idx=$max_idx || :
    key=$(printf '%s' "$key" | awk -v FS='\t' -v OFS='\t' -v new_idx="$idx" -v qty_keys="$qty_keys" '$(qty_keys) = new_idx')
  fi

  # if out of bounds, return
  #test $idx -gt $max_idx && { printf '%s' "$obj"; return 1; } || :

  # rm element
  test "$action" = "rm" && obj=$(printf '%s' "$obj" | grep -vE "^$key") || :
  
  # print obj and reorder
  test -n "$obj" && printf '%s\n' "$obj" | awk -v FS='\t' -v OFS='\t' -v qty_keys="$qty_keys" -v idx="$idx" -v regex="$regex" "$alter_rows" || :
  
  # add element
  test "$action" = "add" && printf "%s%s\n" "$key" "$value" || :
)

# add_value my_argus 'a b' 'hello'
add_value() {
  # need to be defined
  _empty_or_ws "$1" || return $?
  _empty "$2" || return $?
  
  # subshell to keep variables local
  _() (
    # set obj to variable named $1
    eval obj=\$"$1"
    key=$(_tab_key "$2")
    value=$(esc "$3")

    if test "$ARGUS_NILIST" && _if_last_key_is_int_remove_it "$key" >/dev/null; then
      _ilist_add_or_rm "add" "$key" "$value" "$obj" 
    else
      test -n "$obj" && printf '%s\n' "$obj" || :
      printf "%s%s\n" "$key" "$value"
    fi
  )
  # set variable named $1 to $value
  if test "$#" -eq 3; then
    eval "$1"'=$(_ "$1" "$2" "$3")'
  else
    eval "$1"'=$(_ "$1" "$2" "$(cat)")'
  fi
}

# add_value_at my_argus 'a b' 1 'hello'
add_value_at() {
  # need to be defined
  _empty_or_ws "$1" "$3" || return $?
  _empty "$2" "$4" || return $?

  _() (
    eval obj=\$"$1"
    key=$(_tab_key "$2")
    item=$3
    value=$(esc "$4")

    # printf '%s' "$obj" | awk -v FS='\t' -v OFS='\t' -v idx="$item" -v key="$key" -v value="$value" 'BEGIN {added=0} {if(NR == idx) { printf "%s%s\n%s\n", key, value, $0; added=1 } else {print}} END { if(!added) { printf "%s%s\n", key, value } }'
    printf '%s' "$obj" | awk -v FS='\t' -v OFS='\t' -v idx="$item" -v key="$key" -v value="$value" 'BEGIN {added=0} {if(NR == idx) { printf "%s%s\n%s\n", key, value, $0; added=1 } else {print}} END { if(!added) { if(idx == 0) { printf "%s%s\n", key, value } else {exit 1}}} '
  )

  # set variable named $1 to $value
  if test "$#" -eq 4; then
    eval "$1"'=$(_ "$1" "$2" "$3" "$4")'
  else
    eval "$1"'=$(_ "$1" "$2" "$3" "$(cat)")'
  fi  
}

# rm_key my_argus 'a'
rm_key() {
  # need to be defined
  _empty_or_ws "$1" || return $?
  _empty "$2" || return $?
  _() ( 
    eval obj=\$"$1"
    key=$(_tab_key "$2")

    # if the last key is an int, fill it's gap
    if test "$ARGUS_NILIST" && _if_last_key_is_int_remove_it "$key" >/dev/null; then
      _ilist_add_or_rm "rm" "$key" "$value" "$obj" 
    else
      test -n "$obj" && printf '%s' "$obj" | grep -vE "^$key"
    fi
  )
  eval "$1"'=$(_ "$1" "$2")'
}

# rm_value my_argus 'a b' 'hello'
rm_value() {
  # need to be defined
  _empty_or_ws "$1" || return $?
  _empty "$2" "$3" || return $?
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
  # need to be defined
  _empty_or_ws "$1" || return $?
  _empty "$2" "$3" || return $?
  _() (
    eval obj=\$"$1"
    key=$(_tab_key "$2")
    value=$(printf '%s' "$3" | sed 's/\\/\\&/g')

    # printf '%s' "$obj" | grep -vE "^${key}${value}\$"
    printf '%s' "$obj" | _grepv E "^${key}${value}\$"
  )
  eval "$1"'=$(_ "$1" "$2" "$3")'
}

# rm_at_key my_argus 'a b' 1
rm_at_key() {
  # need to be defined
  _empty_or_ws "$1" || return $?
  _() (
    _empty "$3" || return $?
    eval obj=\$"$1"
    key=$(_tab_key "$2")
    item=$3
    regex="^${key}"

    rows=$(printf '%s' "$obj" | awk -v regex="$regex" 'BEGIN {rows=0} {if ($0 ~ regex) {rows=rows+1}} END {print rows}')
    test $rows -eq 0 && { printf '%s' "$obj"; return 1; } || :
    printf '%s' "$obj" | awk -v regex="$regex" -v item="$item" -v rows="$rows" \
      'BEGIN {found=0; row=0; if(item == 0) {item=rows}} 
      #BEGIN {row=0; if(item == 0 || item > rows) {item=rows}} 
      {
        if ($0 ~ regex) {row=row+1; if(row == item) { found=1 } else { print }} 
        else { print }
      }
      END {exit !found}'
  )
  if   test "$#" -eq 2; then
    eval "$1"'=$(_ "$1" "" "$2")'
  elif test "$#" -eq 3; then
    eval "$1"'=$(_ "$1" "$2" "$3")'
  fi
}

# get my_argus 'a b'
get() (
  # need to be defined
  _empty_or_ws "$1" || return $?
  if test "$1" = "-"; then
    obj=$(cat)
  else
    eval obj=\$"$1"
  fi
  key=$(_tab_key "$2")
  # last key is int and is 0
  if test "$ARGUS_NILIST" && rkey=$(_if_last_key_is_int_remove_it "$key") && awk -v key="$key" 'BEGIN { $0 = key; if ($NF != 0) {exit 1} }' ; then
    regex="^${rkey}[-]?[0-9]+[[:blank:]]"
    printf '%s' "$obj" | grep -E "$regex" | tail -n1 | awk '{print} END { exit !NR }'
  else
    printf '%s' "$obj" | grep -E "^$key"
  fi
)

# get_value my_argus 'a'
get_value() (
  # need to be defined
  _empty_or_ws "$1" || return $?
  get "$1" "$2" | awk -v rkey="$2" -v keys=$(printf '%s' "$2" | awk '{print NF}') -v FS='\t' '{if (NF == keys+1 || rkey == "") { print $NF }} END { exit !NR }'
)

# get_pair my_argus 'a'
get_pair() {
  # need to be defined
  _empty_or_ws "$1" || return $?
  _empty "$2" || return $?
  get "$1" "$2" | awk -v key="$(_tab_key "$2")" '{print substr($0, length(key)+1) }' | awk -v FS='\t' '{print $1} END { exit !NR }'
}

# get_tail my_argus 'a b'
get_tail() {
  # need to be defined
  _empty_or_ws "$1" || return $?
  _empty "$2" || return $?
  get "$1" "$2" | awk -v key="$(_tab_key "$2")" '{print substr($0, length(key)+1) } END { exit !NR }'
}

# get_at my_argus 'a b' 1
get_at() (
  # need to be defined
  _empty_or_ws "$1" || return $?

  if   test "$#" -eq 2; then
    _empty "$2" || return $?
    key=''
    pos=$2
  elif test "$#" -eq 3; then
    _empty "$3" || return $?
    key=$2
    pos=$3
  else
    return 1
  fi 

  get "$1" "$key" | awk -v item="$pos" 'BEGIN {found=0} {if (NR==item) {print; found=1}} END { if (!found && item==0) {print} else if (!found && item > 0) {exit 1}}'
)

# get_enumerated my_argus 'a b'
get_enumerated() (
  # need to be defined
  _empty_or_ws "$1" || return $?
  get "$1" "$2" | awk '{print NR} END { exit !NR }'
)

pack_ilist() {
  # need to be defined
  _empty_or_ws "$1" || return $?
  _empty "$2" || return $?
  test "$ARGUS_NILIST" || return 1

  _() (
    eval obj=\$"$1"
    key=$(_tab_key "$2")
    keys=$(printf '%s' "$key" | tr '\t' '\n' | wc -l)
    ffkey=$((keys+1))
    sfkey=$((keys+2))
    # match key that are followed by an int
    regex="^${key}[-]?[0-9]+[[:blank:]]"
    
    # filter and sort out fields to enumerate
    enumerate=$(printf '%s' "$obj" | grep -E "$regex" | sort -nk$ffkey)
    printf '%s' "$enumerate" | awk -v ffkey="$ffkey" -v sfkey="$sfkey" -v FS='\t' -v OFS='\t' \
    '# init enumerator, previous, current & current next column
    BEGIN { e=0; pcol=e; ccol=e; cncol=e; }
    {
      ccol=$(ffkey);
      cncol=$(sfkey);
      # if first run OR ccol > pcol OR next cncol is non int
      if(e == 0 || ccol > pcol || cncol !~ /^[0-9]+$/ ) { e=e+1 }; 
      $(ffkey)=e; pcol=ccol; print
    }'

    # filter out fields not to enumurate
    printf '%s' "$obj" | grep -vE "$regex"
  )
  eval "$1"'=$(_ "$1" "$2")'
}
