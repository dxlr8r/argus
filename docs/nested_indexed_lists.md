# Nested indexed lists

Below is a common object often found in the cloud, here defined using JSON:

`{"spec": [["name": "a", port: 80], ["name": "b", port: 443]]}`

This object can be created using Argus:

```sh
add_value obj 'spec 1 name' a
add_value obj 'spec 1 port' 80
add_value obj 'spec 2 name' b
add_value obj 'spec 2 port' 443
```

This however leads to some issues, in this case the indexing is defined manually. Usually we use the `add_value_at` function to manipulate a list, but that only works for named indexed lists, meaning each list has it's own named key (meaning not an integer/index).

I would argue that a better data structure, is to define the same data, still using JSON, as such:

`{"spec": {"a": {"port": 80}, "b": {"port": 443}}}`

Here the value of the name key is used as a key, and we don't have to deal with nested indexed lists.

In Argus this data structure can be create like so:

```sh
add_value obj 'spec a port' 80
add_value obj 'spec b port' 443
```

And `add_value_at` and the other `at` functions would work as normal.

If you still require nested indexed lists, Argus can do this as shown above. Argus data format is not the best match however for this data structure, the preferred way is to use regular named lists, like examplified above.

Argus does however have some logic to try and overcome some of the issues described above, like having to manually define indexing. Enable this logic by setting the variable `ARGUS_NILIST`, like so:

```sh
ARGUS_NILIST=TRUE
```

To unset it:

```sh
unset ARGUS_NILIST
```

Argus will now enable additional features, like the ability to add/remove an element to the beginning/end of an indexed list etc.

For example:

```sh
add_value my_nilist 'a 1' 'I will end up in position 2'
add_value my_nilist 'a 1' 'I will end up in position 1'
add_value my_nilist 'a 0' 'I will end up in the void somewhere'
add_value my_nilist 'a 3' 'I will end up in position 3'
rm_key my_nilist 'a 0'
get my_nilist | sort
```

Stdout:

```
a	1	I will end up in position 1
a	2	I will end up in position 2
a	3	I will end up in position 3
```

A function that will be made available is `pack_ilist`, it will try pack/reenumerate indexed lists. For example:

```sh
unset ARGUS_NILIST
add_value amess 'a 1' 'I will end up in position 1'
add_value amess 'a 5' 'I will end up in position 3'
add_value amess 'a 3' 'I will end up in position 2'
ARGUS_NILIST=TRUE
pack_ilist amess 'a'
get amess | sort
```

Stdout:

```
a	1	I will end up in position 1
a	2	I will end up in position 2
a	3	I will end up in position 3
```
