# Loops

Some examples of how we can iterate over objects using the Argus with regular POSIX while and for.

The example in "Getting started -> Looping" is the one I recommend, as that is the fastest.

## While

As shown in the "Getting started -> Looping" section of the [README](../README.md#looping)

Same example as above, fetching until empty instead of HERE DOC:

```sh
status_dilithium=$(get my_argus 'status dilithium_reserves')
while get status_dilithium >/dev/null; do
  entry=$(get_at status_dilithium 1)
  reserves=$(get_value entry)
  system=$(echo "$entry" | awk '{print $(NF-1)}')
  if test "$reserves" -lt 1000; then
    printf 'system "%s" has dangerously low reserves of dilithium: %s\n' "$system" "$reserves"
  fi
  rm_at_key status_dilithium 1
done
```

## For

Get systems where the dilithium reserves are low. Using enumeration:

```sh
keys='status dilithium_reserves'
for i in $(get_enumerated my_argus "$keys"); do
  entry=$(get_at my_argus "$keys" $i)
  reserves=$(get_value entry)
  system=$(echo "$entry" | awk '{print $(NF-1)}')
  if test "$reserves" -lt 1000; then
    printf 'system "%s" has dangerously low reserves of dilithium: %s\n' "$system" "$reserves"
  fi
done
```
