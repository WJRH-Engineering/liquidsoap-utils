# A time expression that determines
# when a station id should be played
station_id_times = ref ({0m or 15m or 30m or 45m})

def set_station_id_times(times) =
	station_id_times := times
end

# A flag that tells robodj whether it should
# play a station id on the next track
play_station_id = ref false

# Define a getter for the play_station_id flag
# because using ! as a dereference operator can
# be confusing
def time_for_station_id() =
	!play_station_id
end

# The play_station_id flag behaves like a state machine
# it is set by this script when the time condition is met
# and reset by the station_id source upon completion of a 
# station id

def set_station_id() =
	play_station_id := true
end

def reset_station_id(m) =
	play_station_id := false
end

def update_loop() = 

	# Calling station_id_times as a function
	# returns a boolean that is true if we are
	# inside of the time range and false otherwise
	
	station_id_times = !station_id_times
	
	if station_id_times() 
	then
		set_station_id()
		5.0 * 60.0
	else	
		30.0
	end
end

add_timeout(0.0, update_loop)
