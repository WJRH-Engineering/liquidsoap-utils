# Liquidsoap Utils

I started using this repository to store liquidsoap scripts and utility functions I wrote that were general enough to be used across multiple projects, with the hope that they might be useful to future engineers of the station.

---

## Config.liq

Config.liq provides a key value store that can be used for getting and setting config parameters within a liquidsoap script. It is necessary because Liquidsoap does not natively implement dictionaries, hashmaps, or anything similar. Instead, liquidsoap lets users declare a list of tuples, where for each tuple in the list, the first element in the tuple is represents the key, and the second element represents the value. This is referred to by Liquidsoap as an "associative list", and an example is included below.

```python
dictionary_like_list = [
  ("key1", "value1"),
  ("key2, "value2")
]
```

Liquidsoap provides several helper functions for interacting with associative lists, but these can be difficult to understand for those new to the language, particularly when you want the list to be mutable. This stems largely from the bizarre syntax liquidsoap forces you to use when dealing with mutable variables.

For example, a mutable list can be declared with the `ref` keyword like so:
```python
mutable_list = ref([
  ("key1", "value1"),
  ("key2, "value2")
])
```

It can be read with the expression:
```python
list_copy = !mutable_list; list_copy["key1"]
```

And updated with the expression:
```python
if list.mem_assoc("key1", !mutable_list) then
  mutable_list := list.remove_assoc("key1", !mutable_list)
end

mutable_list := list.add(("key1", "new-value"), !mutable_list)
```

Notably, the `!` operator is not a logical not operator, like it would be in other languages. Instead it means to dereference a mutable variable, which copies its value into an immutable variable that be used by other parts of the script without restriction. The `:=` operator, in turn, copies a new value into a mutable variable. This attitude towards mutability is part of Liquidsoap's heritage as a [functional programming language](https://en.wikipedia.org/wiki/Functional_programming).
