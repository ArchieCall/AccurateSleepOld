# AccurageSleep.jl
# 08-27-2015
#workspace()

module NewSleep
function sleep_ns(sleep_time; help = false)
  #-- an more accurate sleep function written in Julia
  #-- parameters
  #--   sleep_time => time to sleep in seconds
  #--   help when true => shows help information
  #=
    the current Julia sleep() function is only accurate to around 1-2 ms.
    sleep_ns works as follows:
      the time to sleep is broken up into a series of individual sleep intervals followed by a burn cycle
      each sleep interval amounts to about 75% of the remaining sleep time minus a small burn time reservation
      the intervals approach the total sleep time until only the final burn cycle is left
      the final burn cycle is very accurate because it loops thousands of times before stopping at the sleep_time
    sleep_ns will yield errors of much less than .01 ms
    sleep_ns works equally well for sleep_time's ranging from thousands of seconds down to .0005 seconds
    when sleep_time's are greater than .005 seconds there will be negligible impact on computer performance or cpu heatup
  =#
  const burn_time = .002  #-- time saved for final burn in seconds
  const tics_per_second = 1_000_000_000  #-- converts time_ns ticks to seconds
  const reduction_ratio = .75  #-- percentage that the sleep_time is reduced for each sleep() cycle
  remaining_sleep_time = sleep_time
  delta = 0.
  actual_burn_time = 0.
  num_sleeps = 0
  num_burns = 0
  nano1 = time_ns()
  if sleep_time > burn_time
    while true
      num_sleeps += 1
      partial_sleep = reduction_ratio * (remaining_sleep_time - burn_time)
      sleep(partial_sleep)  #-- normal Julia sleep function
      nano2 = time_ns()
      delta = (nano2 - nano1)/tics_per_second
      remaining_sleep_time = sleep_time - delta
      remaining_sleep_time < burn_time  && break
    end
  end

  burn_begin = time_ns()
  while true
    nano2 = time_ns()
    num_burns += 1
    delta = (nano2 - nano1)/tics_per_second
    if delta > sleep_time
      actual_burn_time = (nano2 - burn_begin)/tics_per_second
      break
    end
  end
  if help
    nano1 = time_ns()
    sleep(sleep_time)  #-- sleep with the regular Julia sleep for comparison purposes
    nano2 = time_ns()
    delta_compare = (nano2 - nano1)/tics_per_second
    percent_burn_time = actual_burn_time * 100. / sleep_time
    @show(sleep_time, delta, delta_compare, burn_time, percent_burn_time, reduction_ratio, actual_burn_time, num_sleeps, num_burns)
  end
  return delta
end
end

module Mainline
println("--- module:Mainline has started ---")
import NewSleep.sleep_ns   #-- import the function sleep_() from module NewSleep

#-- this code demonstrates various uses of sleep_ns()

println("--- warmup happens next ---")
sleep_ns(.02)              # warmup sleep_ns function with a short sleep of 20 ms.
println("")
println("--- help sample call - only used to demo how the function works ---")
sleep_ns(.006, help=true ) # sample of a single call of 6 ms. which includes help information
println("")

#--- a sample looping calling the present sleep() function
num_iters = 10      #-- 10 samples
sleep_time = .0001  #-- each sample is a sleep of .1 ms.
@printf "------- Sleep times for existing Julia sleep() function -------\n"
@printf("Number of iterations = %###i \n", num_iters)
@printf("Desired sleep time is %0.7f seconds.\n", sleep_time)
for i = 1:num_iters
  nano1 = time_ns()
  sleep(sleep_time)  #-- this is existing sleep function
  nano2 = time_ns()
  timed_sleep = (nano2 - nano1)/10^9
  @printf("Iter %##i  Actual sleep = %0.7f seconds.\n", i, timed_sleep)
end
println("")


num_iters = 10      #-- 10 samples
sleep_time = .0001  #-- each sample is a sleep of .1 ms.
#--- a sample looping calling the sleep_ns() function
#--- when examining the actual sleep times notice the increased accuracy
@printf "------- Sleep times for special sleep_ns() function -------\n"
@printf("Number of iterations = %###i \n", num_iters)
@printf("Desired sleep time is %0.7f seconds.\n", sleep_time)
for i = 1:num_iters
  nano1 = time_ns()
  sleep_ns(sleep_time)  #-- this is the new sleep function
  nano2 = time_ns()
  timed_sleep = (nano2 - nano1)/10^9
  @printf("Iter %##i  Actual sleep = %0.7f seconds.\n", i, timed_sleep)
end
println("")

num_iters = 5     #-- 5 samples
sleep_time = 3.0  #-- each sample is a sleep of 3.0 seconds
#--- a sample looping calling the sleep_ns() function
#--- when examining the actual sleep times notice the increased accuracy
@printf "------- Sleep times for special sleep_ns() function -------\n"
@printf("Number of iterations = %###i \n", num_iters)
@printf("Desired sleep time is %0.7f seconds.\n", sleep_time)
for i = 1:num_iters
  nano1 = time_ns()
  sleep_ns(sleep_time)  #-- this is the new sleep function
  nano2 = time_ns()
  timed_sleep = (nano2 - nano1)/10^9
  @printf("Iter %##i  Actual sleep = %0.7f seconds.\n", i, timed_sleep)
end
println("")

#-- sample of 1000 interations of .02 sleep and computes various stats
sleep_time = .02
num_iters = 1000
sum = 0.0
sum_elapsed = 0.0
delta_min = 999.
delta_max = 0.
for i in 1:num_iters
  elapsed_time = sleep_ns(sleep_time)
  sum_elapsed += elapsed_time
  delta = abs(elapsed_time - sleep_time)
  sum += delta
  deltaMilliseconds = delta * 1000.
  if deltaMilliseconds < delta_min
    delta_min = deltaMilliseconds
  end
  if deltaMilliseconds > delta_max
    delta_max = deltaMilliseconds
  end
end
sum1 = sum * 1000. / num_iters
@printf "Desired sleep time is %0.7f sec's.\n" sleep_time
@printf "Average sleep time is %0.7f sec's.\n" sum_elapsed / num_iters
@printf "Average error is %0.7f ms.\n" sum1
@printf "Minimum error is %0.7f ms.\n" delta_min
@printf "Maximum error is %0.7f ms.\n" delta_max
println("")
println("--- module:Mainline has ended ---")
end
