# ---------
# LATCH.LIQ
# ---------
# This library is an provides a simple implementation of an RS Latch in
# Liquidsoap. It serves a similar purpose to the built in functions 
# predicate.activates, predicate.changes, and predicate.once.
# https://www.liquidsoap.info/doc-dev/reference-extras.html#predicate.activates
# Currently, these functions are unstable, and only exist in the development
# versions of Liquidsoap, so this serves as an alternative until those
# features can be officially included.

# At its core, the library consists of a Boolean flag called latch_state, and
# helper functions latch_set(), latch_reset(), and latch_get_value().
# In addition, the user of the library can provide a condition function, which
# will get called periodically, and set the latch if it returns true.


latch_state = ref(false)
latch_set = fun() -> latch_state := true
latch_reset = fun() -> latch_state := false
latch_get_value = fun() -> !latch_state

# configurable state
latch_set_condition = ref(fun() -> 0m-30m)
latch_wait_after_true = ref(5.0 * 60.0)
latch_wait_after_false = ref(30.0)

def latch_update_loop()
	# dereference condition function
	condition = !latch_set_condition

	if condition() then
		latch_set()
		!latch_wait_after_true
	else
		!latch_wait_after_false
	end
end

def latch_begin()
	add_timeout(0.0, latch_update_loop)
end


def register_latch_commands(namespace)
    server.register(namespace = namespace, "set", fun(arg) -> begin latch_set(); "OK" end)
    server.register(namespace = namespace, "reset", fun(arg) -> begin latch_reset(); "OK" end)
    server.register(namespace = namespace, "get", fun(arg) -> string_of(latch_get_value()))
end
