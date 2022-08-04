# Argus

_Pronounced any way you want._

Argus provides a KISS implementation of associative and indexed arrays in any POSIX-compliant shell. Argus has a simple data structure, allowing you to manipulate and filter the arrays using simple common shell tools.

Current status is under development, use with care.

## Usage

First source argus:

```sh
source argus.sh
```

### Create array

Creating an array is as simple as:

```sh
my_argus=''
```

### Add key/value pairs to array

Let us implement the following YAML object literal:

```
type: Subspace telescope
description:
  operator: Starfleet
status:
  reactor: 
    - true
    - false
```

```sh
add_value my_argus 'type' 'Subspace telescope'
add_value my_argus 'description operator' 'Starfleet'
add_value my_argus 'status reactor' 'true'
add_value my_argus 'status reactor' 'false'
```

### Get elements

Regular expressions are supported in `get` and `get_value`. The regular expression should not contain ` ` (space), as that sign is used to separate keys.

#### Get key pair

```sh
get_pair my_argus 'description'
```

Stdout:

```
operator
```

#### Get value

```sh
get_value my_argus 'status reactor'
```

Stdout:

```
true
false
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

### Remove elements

#### Remove a key

```sh
rm_key my_argus 'description operator'
```

Will remove the key `operator` nested under `description` and all it's content.

#### Remove an item

```sh
rm_item my_argus 'status reactor' '1'
```

Will remove the first item (`true`) from `reactor` nested under `status`. Note that the first item is 1, not 0.

#### Remove a value

```sh
rm_value my_argus 'status reactor' 'false'
```

Will remove all reactors with status false. `rmx_value` also supports regular expressions, so you could  replace `'false'` with `'f.*'` for the same result.

### Filter

Use `grep`, `sed`, `awk` etc. 

Below are some examples:

#### Count offline reactors

```sh
get_tail my_argus 'status reactor' | grep -cxF 'false'
```

#### Filter out the entire row where the reactors are online

In `awk` the value is always located in `$NF`.

```sh
get my_argus 'status reactor' | awk -v FS='\t' '{ if($NF == "true") { print } }'
```

Or using `grep`:

```sh
get my_argus 'status reactor' | grep -E '\ttrue$'
```

#### Use `awk` to search for any key named `operator` nested one level below the root level

```sh
get my_argus | awk -v FS='\t' '{ if ($2 ~ "operator" && $2 != $NF) { print }}'
```

The query in the example above could also been done using `get` and with a regular expression: `get my_argus '.+ operator'`

### Other examples

#### Import a CSV dataset to the argus array

```sh
dilithium_reserves='deneva,1337
io,521
elas,5147
remus,217'

printf '%s\n' "$dilithium_reserves" | while IFS=',' read key value
do
  add_value my_argus "status dilithium_reserves $key" "$value"
done
```

#### Read from pipe/stdin

```sh
printf 'Alpha Quadrant\n' | { add_value my_argus 'description location' "$(cat)" }
```

## Data format and escape sequences

Argus dataformat is simply a tab separated values list (tsv), from the usage section above we would be left with:

```sh
get my_argus | sort
```

Stdout:

```
description	location	Alpha Quadrant
description	operator	Starfleet
status	dilithium_reserves	deneva	1337
status	dilithium_reserves	elas	5147
status	dilithium_reserves	io	521
status	dilithium_reserves	remus	217
status	reactor	false
status	reactor	true
type	Subspace telescope
```

Each value has 1 or more keys, and the value is always the last column. The value **cannot** contain a tab or a newline, so any string that contains these characters requires them to be replaced with the escape sequence equivalent, which `add_value` does by default using the helper function `esc`. Using `esc` or your own implementation, custom functions for manipulation is possible and encouraged where needed.

To *un/de escape* a string use `unesc` which supports strings as arguments or stdin (pipe). You can also use `printf '%b'` etc.

The value is always a string, as the POSIX shell is typeless. If needed, you can represent data types using any notation you prefer, Argus has no best practices for this. One example could be to have the last key decide the data type, in this case a boolean.

´´´sh
add_value my_argus 'status reactor boolean' 'true'
´´´
