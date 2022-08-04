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
get my_argus 'status'
```

Stdout:

```
reactor	true
reactor	false
```

### Remove elements

#### Remove a key

```sh
rm_key my_argus 'description operator'
```

Will remove the key `operator` nested under `description` and all it's content.

#### Remove a value

```sh
rm_value my_argus 'status reactor' 'false'
```

Will remove all reactors with status false. `rmx_value` also supports regular expressions, so you could  replace `'false'` with `'f.*'` for the same result.

### Filter

Use `grep`, `sed`, `awk` etc. 

For example, count offline reactors:

```sh
get my_argus 'status reactor' | grep -cxF 'false'
```

Use `awk` to search for any key named `operator` nested one level below the root level:

```sh
get my_argus '' | awk -v FS='\t' '{ if ($2 ~ "operator" && $2 != $NF) { print }}'
```

### Other examples

Import a CSV dataset to an argus array:

```
dilithium_reserves='deneva,1337
io,521
elas,5147
remus,217'

printf '%s\n' "$dilithium_reserves" | while IFS=',' read key value
do
  add_value my_argus "status dilithium_reserves $key" "$value"
done
```
