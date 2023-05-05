# Data format and escape sequences

Argus dataformat is simply a tab separated values list (tsv):

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

```sh
add_value my_argus 'status reactor boolean' 'true'
```
