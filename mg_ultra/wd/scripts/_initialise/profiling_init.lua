print("Profiler")

--A function for starting the Profiler
function start_profiling()
	registar:update("profiler_active", true)
end

--Stop profiling
function stop_profiling()
	registar:update("profiler_active", false)
end

--convert a profile slice into a string of information
function convertToProfileString(name, slice)
	if slice[3] < 1 then
		--If theres a timing, we want to display :
		-- 1. proportion of period spent executinf
		-- 2. effective timing,
		return 
			string.pad_string(name, 12)
			.. "F-> "
			.. string.format("exec: %.3f ", slice[2]/slice[1]) 
			.. string.format("etime: %d", math.floor(1000000 / (slice[2] + 1))) 
			.. "\n"
	else 
		--If theres a timing, we want to display :
		-- 1. proportion of period spent executing
		-- 2. ratio of period to timing, as a percentage
		local desiredTimePerCycle = 1000000 / slice[3]
		return 
			string.pad_string(name, 12)
			.. "T-> "
			.. string.format("exec: %.3f ", slice[2]/slice[1]) 
			.. string.format("speed: %3.2f%% ", 100*(slice[1] / desiredTimePerCycle) )
			.. "\n"

	end
end