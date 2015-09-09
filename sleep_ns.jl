function sleep_ns(sleep_time::FloatingPoint; burn_time::FloatingPoint = .002300)
  #=
   accurate sleep function written totally in Julia
   Parameters
     sleep_time => time to sleep in seconds
     burn_time => final burn time in seconds - default is .0023 seconds
     current Julia sleep() function:
       loses accuracy around 2.2 ms
       the actual sleep time is quite variable for all ranges of sleep_time
       is a pure sleep with no impact on CPU loading
     sleep_ns words as follows:
       the sleep is broken up into an intial sleep followed by a final burn cycle
       the initial sleep is the specified sleep_time minus the burn_time
       the final burn cycle is very accurate as it loops thousands of times before stopping at the sleep_time
       it uses time_ns to accurately time the sleep
       errors are less than .00005 seconds (ie., .05 ms)
       works equally well for sleep_time's ranging from thousands of seconds down to .00001 seconds, or less
      sleep_time's effect on cpu loading
        sleep_time is greater then .004 seconds => neglible impact on CPU loading
        sleep_time is between .001 and .004 seconds => only slight impact but the computer very usable for other tasks
        sleep_time between .0001 and .004 seconds => some impact - however computer is still not sluggish
  =#
  const tics_per_second = 1_000_000_000.  #-- converts diff time_ns ticks to seconds
  nano1 = time_ns()  #-- get initial time tic
  #------ the initial sleep that reserves the burn_time
  partial_sleep_time = sleep_time - burn_time
  if partial_sleep_time > 0.
    sleep(partial_sleep_time)  #-- standard Julia sleep of partial_sleep_time
  end
  #------ final burn_time loops until full sleep_time has elapsed
  delta = 0.
  while true
    nano2 = time_ns() #-- take tic to allow delta calc
    delta = (nano2 - nano1)/tics_per_second
    delta >= sleep_time && break  #-- break out if full time elapsed
  end
  return delta
end

