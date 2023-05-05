# Argus

_Pronounced any way you want._

Argus provides a KISS implementation of associative and indexed lists in any POSIX-compliant shell. Argus has a simple data structure, allowing you to manipulate and filter the lists using simple common shell tools.

Current status is under development, use with care.

# Getting started

First source argus:

```sh
source argus.sh
```

## Create list

Creating an empty list is as simple as:

```sh
my_argus=''
```

## Add key/value pairs to list

Let us implement the following YAML object literal:

```
name: Argus Array
description:
  type: Subspace telescope
  operator: Starfleet
  quadrant: alpha
  energy_source: fusion reactor
status:
  reactor:
    - true
    - true
    - true
    - false
```

```sh
add_value my_argus 'name' 'Argus Array'
add_value my_argus 'description type' 'Subspace telescope'
add_value my_argus 'description operator' 'Starfleet'
add_value my_argus 'description quadrant' 'alpha'
add_value my_argus 'description energy_source' 'fusion reactor'
add_value my_argus 'status reactor' 'true'
add_value my_argus 'status reactor' 'true'
add_value my_argus 'status reactor' 'true'
add_value my_argus 'status reactor' 'false'
```

## Import a CSV dataset to the argus list

Here we define the CSV in a variable as an example:

```sh
dilithium_reserves='deneva,1337
io,521
elas,5147
remus,217'

while IFS=',' read key value; do
  add_value my_argus "status dilithium_reserves $key" "$value"
done << EOF
$(printf '%s\n' "$dilithium_reserves")
EOF
```

## Backup object

Just write it to a file

```sh
get my_argus > my_argus
```

And restore from backup:

```sh
my_argus=$(cat my_argus)
```

## Get elements

Regular expressions are supported in all `get` functions. The regular expression should not contain ` ` (space), as that sign is used to separate keys.

### Get value

```sh
get_value my_argus 'status reactor'
```

Stdout:

```
true
false
```

## Remove elements

### Remove a key

```sh
rm_key my_argus 'description operator'
```

Will remove the key `operator` nested under `description` and all it's content.

### Remove an element

```sh
rm_at_key my_argus 'status reactor' '1'
```

Will remove the first element (`true`) from `reactor` nested under `status`. Note that the first element is 1, not 0.

### Remove a value

```sh
rm_value my_argus 'status reactor' 'false'
```

Will remove all reactors with status false. `rmx_value` also supports regular expressions, so you could replace `'false'` with `'f.*'` for the same result.

### Others

For a complete list of function and their documentation/usage [see]<docs/functions.md> 

## Examples

Use `grep`, `sed`, `awk` etc. 

Below are some examples:

### Count offline reactors

```sh
get_value my_argus 'status reactor' | grep -cxF 'false'
```

### Filter out the entire row where the reactors are online

In `awk` the value is always located in `$NF`.

```sh
get my_argus 'status reactor' | awk -v FS='\t' '{ if($NF == "true") { print } }'
```

Or using `grep`:

```sh
get my_argus 'status reactor' | grep -E '\ttrue$'
```

### Use `awk` to search for any key named `operator` nested one level below the root level

```sh
get my_argus | awk -v FS='\t' '{ if ($2 ~ "operator" && $2 != $NF) { print }}'
```

The query in the example above could also been done using `get` and with a regular expression: `get my_argus '.+ operator'`


### Looping

Get systems where the dilithium reserves are low:

```sh
while IFS= read -r entry; do
  reserves=$(get_value entry)
  system=$(echo "$entry" | awk '{print $1}')
  if test "$reserves" -lt 1000; then
    printf 'system "%s" has dangerously low reserves of dilithium: %s\n' "$system" "$reserves"
  fi
done << EOF
$(get_tail my_argus 'status dilithium_reserves')
EOF
```

For additional examples (see)<docs/loops.md>

### Read from pipe/stdin

In most shells a pipeline spawn a new subshell, the common idiom to overcome this is to use here docs:

```sh
IFS= add_value my_argus 'description location' << EOF
$(printf 'Alpha Quadrant\n')
EOF
```

In shells that allow it, like zsh you could do:

```zsh
printf 'Alpha Quadrant\n' | { add_value my_argus 'description location'; }
```

# Want to know more?

If you think Argus sounds interesting, and want to investigate more, take a look in the (documentation)<docs>
