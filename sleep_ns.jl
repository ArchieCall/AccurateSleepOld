function sleep_ns(sleep_time::FloatingPoint)
  #=
   + Purpose: an accurate sleep function written totally in Julia
   + Parameter:
       - sleep_time - seconds to sleep
           - must be floating point within range .000001 to 100.
   + Hybrid solution
       - combines regular sleep() function with a final burn cycle
       - regular sleep is simply (sleep_time - burn_time)
       - any remaining time after the sleep() is burned off in a while loop
       - burn_time constant of .002300 seconds evolved after many simulations
         that traded off accuracy vs. cpu loading
       - all timing is with time_ns() which uses tics down to the nano second
   + Returns:  delta -> the actual elapsed time in seconds of the sleep
               note: delta is never less than the desired sleep_time
   + Accuracy
      - sleep()    - average error is .001300 seconds
      - sleep_ns() - average error is .000002 seconds
   + see the web site: "github.org/ArchieCall/AccurateSleep" for further information
  =#

  const tics_per_second = 1_000_000_000  #-- converts differential time_ns ticks to elapsed seconds
  const burn_time = .002300  #-- time in seconds that is reserved for accurate burning
  const min_burn_time = .9 * burn_time #-- minimum time reserved for burning

  if sleep_time > 100. || sleep_time < .000005
    @printf("Error:  sleep_time value of %13.8f is not between .000005 and 100. seconds!", sleep_time)
    Bad_Parm()  #-- dummy error function put here to halt program
  end

  nano1 = time_ns()  #-- get beginning time tic

  #------ the initial sleep that reserves off the burn_time
  partial_sleep_time = sleep_time - burn_time
  #--- adjust partial_sleep_time to always have a remaining_burn_tine
  #    that is greater than the min_burn_time, note. this only applies
  #    if the specified sleep_time is greater than the burn_time
  if partial_sleep_time > 0. && partial_sleep_time  < burn_time
    remaining_burn_time = sleep_time - partial_sleep_time
    if remaining_burn_time < min_burn_time
      remaining_burn_time = min_burn_time
      partial_sleep_time = sleep_time - remaining_burn_time
    end
  end

  if partial_sleep_time > 0.
    sleep(partial_sleep_time)  #-- standard Julia sleep of partial_sleep_time
  end

  #------ final burn_time loops until full sleep_time has elapsed
  delta = 0.     #-- make delta available outside while loop
  while true
    nano2 = time_ns() #-- take tic to allow delta calc
    delta = (nano2 - nano1) / 10^9  #-- actual elapsed time of sleep
    if delta >= sleep_time
      break  #-- break out if full time has elapsed
    end
  end

  return delta
end  #-- End of sleep_ns() function

