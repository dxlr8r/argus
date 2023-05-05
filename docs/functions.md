# Functions

## add_value

```sh
add_value obj 'key ...' [value]
```

Arguments: If last argument is not supplied, will read from stdin

Description: Add value to variable obj nested under key

## add_value_at

```sh
add_value obj 'key ...' pos [value]
```

Arguments: If last argument is not supplied, will read from stdin

Description: Add value to variable obj nested under key as a list at position pos (`[0-1]+`). If pos is 0 add to the end of the list, if 1 add to the beginning.

## rm_key

```sh
rm_key obj 'key ...'
```

Description: Deletes entry in obj where key matches

## rm_value

```sh
rm_value obj 'key ...' value
```

Description: Deletes entry in obj where key and value matches

## rmx_value

```sh
rm_value obj 'key ...' value
```

Description: Like rm_value, but value can be a regular expression

## rm_at_key

```sh
rm_at_key obj ['key ...'] pos
```
s
Description: Deletes entry in obj where key and value matches and is at position pos (`[0-1]+`). If pos is 1 remove the first entry, if 0 remove the last entry.

## get

```sh
get obj ['key ...']
```

Description: Print to stdout all entries where key matches

## get_value

```sh
get_value obj ['key ...']
```

Description: Print to stdout all values where key matches

## get_pair

```sh
get_pair obj 'key ...'
```

Description: Print to stdout all next fields, key or value, where key matches

## get_tail

```sh
get_tail obj 'key ...'
```

Description: Print to stdout all fields, keys and value, after key where key matches

## get_at

```sh
get_at obj ['key ...'] pos
```

Description: Print to stdout entry where key matches and is at position pos (`[0-1]+`). If pos is 0 print the last entry of the list, if 1 print the first entry.


## get_enumerated

```sh
get_enumerated obj ['key ...']
```

Description: Print to stdout entries where key matches as an enumerated list, a sequence of positive integers starting at 1. 


# Helper functions

## esc

```sh
esc [string]
```

Arguments: If last argument is not supplied, will read from stdin.

Description: Escapes tab and newline of input string. Please note that trailing newlines will be trimmed because of the way the POSIX shells handles trailing newlines.


Example:

```sh
esc "$(printf 'A\ttab with a new\nline')"
printf 'A\ttab with a new\nline' | esc
```

Stdout:

```
A\ttab with a new\nline
A\ttab with a new\nline
```

## unesc

```sh
unesc string
unesc
```

Arguments: One argument or stdin.

Description: Unscapes single escaped tabs and newlines of input string.

#### Get key pair

```sh
get_pair my_argus 'description'
```

Stdout:

```
operator
```

#### Get tail

```sh
get_tail my_argus 'status'
```

Stdout:

```
reactor	true
reactor	false
```

If you want the entire row, not just the tail (key(s) removed), use `get`.
