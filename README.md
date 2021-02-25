# Liquidsoap Utils

I started using this repository to store liquidsoap scripts and utility functions I wrote that were
general enough to be used across multiple projects, with the hope that they might be useful to
future engineers of the station.

---

## Config.liq

Config.liq provides a key value store that can be used for getting and setting
config parameters within a liquidsoap script. It is necessary because Liquidsoap
does not natively implement dictionaries, hashmaps, or anything similar.
Instead, liquidsoap lets users declare a list of tuples, where for each tuple in
the list, the first element in the tuple is represents the key, and the second
element represents the value. This is referred to by Liquidsoap as an
"associative list", and an example is included below.

```python
dictionary_like_list = [
  ("key1", "value1"),
  ("key2, "value2")
]
```

Liquidsoap provides several helper functions for interacting with associative
lists, but these can be difficult to understand for those new to the language,
particularly when you want the list to be mutable. This stems largely from the
bizarre syntax liquidsoap forces you to use when dealing with mutable
variables.

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

Notably, the `!` operator is not a logical not operator, like it would be in
other languages. Instead it means to dereference a mutable variable, which
copies its value into an immutable variable that be used by other parts of the
script without restriction. The `:=` operator, in turn, copies a new value into
a mutable variable. This attitude towards mutability is part of Liquidsoap's
heritage as a [functional programming
language](https://en.wikipedia.org/wiki/Functional_programming). This is very
intellectually interesting, and it can be a useful way of thinking, but I don't
think it should be necessary to understand these things in order to implement
something like a mutable config dictionary.

Config.liq simplifies the above expressions by replacing them with
`config_set(key, value)` and `config_get(key)`.

### Example

```python
%include "config.liq"
# Set default config values
config_set("icecast.server", "wjrh.org")
config_set("icecast.port", "8000")
config_set("icecast.mount", "test-mount")

# stream a sine wave to the icecast server at 440Hz
output.icecast(%mp3,
  host=config_get("icecast.server"),
  port=int_of_string(config_get("icecast.port")), # can only store strings
  mount=config_get("icecast.mount")
  password=icecast_password,
  sine(440.0)
)
```

### Telnet Server

Config.liq also gives you the option to bind it to the liquidsoap telnet or unix
domain socket server, if one exists, by calling the
`register_config_functions()` function. This exposes `config.get` and
`config.set` as server commands, which can be used to update the scripts
configuration on the fly.


## Timestring.liq

Liquidsoap includes an excellent syntax for declaring time intervals, documented here:
[https://www.liquidsoap.info/doc-dev/language.html#time-intervals](https://www.liquidsoap.info/doc-dev/language.html#time-intervals).
Timestring.liq allows strings matching this format to be used in a similar way. It exposes a function called `timerange_to_function()` Which takes a time expression encoded as a string, and returns a function that returns true when called within the time range specified, and false otherwise.

This grants the user a lot more flexibility with how time expressions can be used. They can now, for example, be generated dynamically by a function call, or updated by an external script over the telnet interface.


### Example

```python
timeslot1 = "3w12h-3w13h"
timeslot2 = "3w13h-3w14h"

output = switch([
	(timerange_to_function(timeslot1), sine(440.0)),
	(timerange_to_function(timeslot2), square(440.0)),

])
```

In the example above, we make a very simple source that plays a 440Hz sine wave on wednesdays between noon and 1:00pm, and a square wave between 1:00pm and 2:00pm

### Example: Remote Studio

```python
timeslots = ref([])

def add_timeslot(mount, timestring)
	print("new timeslot: #{mount} @ #{timestring}")
	timeslots := list.append([(mount, timestring)], !timeslots);
end

def make_source(timeslot)
	url = "http://#{config_get('input.server')}:#{config_get('input.port')}/#{fst(timeslot)}"
	source = input.http(id=fst(timeslot), url)
	predicate = timerange_to_function(snd(timeslot))
	(predicate, source)
end

def start()
	output = switch(track_sensitive = false, list.map(make_source, !timeslots))
	stream_to("remote-studio", output)
	"OK"
end

server.register("add", 
	namespace="timeslot",
	usage="add <mount> <timestring>",
	fun(argstring) -> begin
		args = string.split(separator=" ", argstring)
		mount = list.nth(default="", args, 0)
		timestring = list.nth(default="", args, 1)
		add_timeslot(mount, timestring)
		"OK"
	end
)

```

Above is a sample from the WJRH Remote Studio scheduler, which uses timestring.liq to receive schedule information over the telnet interface.

Under the hood, timestring.liq works by using regular expressions to parse the time ranges into tuples of integers, where each integer is the number of seconds since the beginning of the week. It then constructs a function that compares the integer value of the current second to that of those in the tuple, and returns true if it lies between them.

## Latch.liq

Latch.liq provides a simple implementation of an RS Latch in
Liquidsoap. It serves a similar purpose to the built in functions 
predicate.activates, predicate.changes, and predicate.once.
https://www.liquidsoap.info/doc-dev/reference-extras.html#predicate.activates
Currently, these functions are unstable, and only exist in the development
versions of Liquidsoap, so this serves as an alternative until those
features can be officially included.
