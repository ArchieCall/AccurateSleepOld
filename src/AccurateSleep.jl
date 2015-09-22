#--- AccurateSleep.jl
#-- Stand alone script to demo using sleep_ns() compared to sleep()
# 09-22-2015
module NewSleep

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
      - sleep()    - approx. error is .001300 seconds
      - sleep_ns() - approx. error is .000002 seconds
   + see the web site: "github.org/ArchieCall/AccurateSleep" for further information
  =#

  const burn_time = .002300  #-- time in seconds that is reserved for accurate burning
  const min_burn_time = .9 * burn_time #-- minimum time reserved for burning

  if sleep_time > 100. || sleep_time < .000005
    @printf("Error:  sleep_time value of %13.8f is not between .000005 and 100. seconds!", sleep_time)
    Bad_Parm()  #-- dummy error function to halt program when bad parameter entry
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


function simple_compare(simulation_time::FloatingPoint, sleep_time::FloatingPoint)
  #=
    Compares sleep_ns() vs. sleep() for single value of sleep_time
    Parms:
      total_sim_time -> total simulation time for each sleep_time in the sleep_array
      sleep_array -> an array of sleep_times   ie. [.005, .002, .001, .0001, .00001]
    Up to 20,000 simulation samples are run for each sleep_time
    Pay attention to the Mean Difference statistic which highlights accuracy of sleep_ns()
  =#
  num_iters = convert(Integer,round(simulation_time / sleep_time))
  if num_iters < 1
    num_iters = 1
  end
  revised_simulation_time = num_iters * sleep_time
  @printf("\n========================== simple_compare simulation =======================\n")
  @show(num_iters)
  @printf("Total simulation time  ---------------------------  %10.6f seconds\n", revised_simulation_time)
  @printf("Specified sleep time -----------------------------  %10.6f seconds\n", sleep_time)

  delta_a = 0.
  nano1 = time_ns()
  i = 1
  while true
    sleep(sleep_time)
    nano2 = time_ns()
    delta_a = (nano2 - nano1) / 10^9
    i >= num_iters && break
    i += 1
  end
  delta_b = 0.
  nano1 = time_ns()
  i = 1
  while true
    sleep_ns(sleep_time)
    nano2 = time_ns()
    delta_b = (nano2 - nano1) / 10^9
    i >= num_iters && break
    i += 1
  end
  ave_delta_a = delta_a / num_iters
  ave_delta_b = delta_b / num_iters
  ave_diff_a = ave_delta_a - sleep_time
  ave_diff_b = ave_delta_b - sleep_time
  @printf("Average time for sleep() -------------------------  %10.6f seconds\n", ave_delta_a)
  @printf("Average time for sleep_ns() ----------------------  %10.6f seconds\n", ave_delta_b)
  @printf("Average differential time for sleep() ------------  %10.6f seconds\n", ave_diff_a)
  @printf("Average differential time for sleep_ns() ---------  %10.6f seconds\n", ave_diff_b)
  return nothing
end  #-- End of simple_compare() function


function detail_compare(total_sim_time::FloatingPoint, sleep_array)
  #=
    Compares sleep_ns() vs. sleep() over multiple values of sleep_time
    Parms:
      total_sim_time -> total simulation time for each sleep_time in the sleep_array
      sleep_array -> an array of sleep_times   ie. [.005, .002, .001, .0001, .00001]
    Up to 20,000 simulation samples are run for each sleep_time
    Pay attention to the Mean Difference statistic which highlights accuracy of sleep_ns()
=#
  @printf("\n======================= detail_compare simulation =========================\n")
  #@show(sleep_array)
  @printf("Total simulation time  ---------------------------------  %10.6f seconds\n", total_sim_time)
  for i = 1:length(sleep_array)
    @printf("Specified sleep time(s) --------------------------------  %10.6f seconds\n", sleep_array[i])
  end

  sample_size = 20_000  #-- maximum number iters used

  sleep_obs1 = zeros(FloatingPoint, sample_size)
  sleep_obs2 = zeros(FloatingPoint, sample_size)
  sleep_count1 = zeros(FloatingPoint, sample_size)
  sleep_count2 = zeros(FloatingPoint, sample_size)
  sleep_cdf1 = zeros(FloatingPoint, sample_size)
  sleep_cdf2 = zeros(FloatingPoint, sample_size)

  cpu_level =      [.0500,
                    .0300,
                    .0200,
                    .0100,
                    .0080,
                    .0060,
                    .0040,
                    .0030,
                    .0025,
                    .0023,
                    .0020,
                    .0010]

  cpu_load =      [2.1,
                   2.8,
                   3.0,
                   5.0,
                   6.0,
                   7.5,
                   10.5,
                   14.0,
                   24.0,
                   31.0,
                   31.0,
                   31.0]

  num_cpu_levels = 12

  #--- loops on sleep_time

  for sleep_time  in sleep_array
    #--- zero arrays for each new sleep_time cycle
    sleep_obs1[1:sample_size] = 0.
    sleep_obs2[1:sample_size] = 0.
    sleep_count1[1:sample_size] = 0.
    sleep_count2[1:sample_size] = 0.
    sleep_cdf1[1:sample_size] = 0.
    sleep_cdf2[1:sample_size] = 0.

    #-- calc the CPU load
    calc_load = 99.99
    for i = 1:num_cpu_levels
      #--- sleep_time > highest sleep index -> set at highest
      if sleep_time >  cpu_level[1]
        calc_load = cpu_load[1]
        break
      end
      #--- sleep_time <= lowest sleep index -> set at lowest
      if sleep_time <=  cpu_level[num_cpu_levels]
        calc_load = cpu_load[num_cpu_levels]
        break
      end
      #--- sleep_time between two sleep indices -> interpolate
      if sleep_time <=  cpu_level[i] && sleep_time >= cpu_level[i + 1]
        span_level = cpu_level[i] - cpu_level[i + 1]
        span_load = cpu_load[i + 1] - cpu_load[i]
        proportion_level = (cpu_level[i] - sleep_time) / span_level
        calc_load = cpu_load[i] + (proportion_level * span_load)
        break
      end
    end
    calc_load = calc_load - 2.0  #-- back off the baseline CPU load to reflect only the Julia impact
    num_iters = convert(Integer,round(total_sim_time/sleep_time))

    if num_iters < 1
      num_iters = 1
    end
    if num_iters > sample_size
      num_iters = sample_size
    end
    total_sim_time = num_iters * sleep_time
    for new_sleep in [false, true]

      delta = 0.
      diff = 0.
      new_delta = 0.
      i = 1
      while true
        if !new_sleep
          #--- regular sleep simulation
          nano1 = time_ns()
          sleep(sleep_time)
          nano2 = time_ns()
          delta = (nano2 - nano1) / 10^9
          sleep_obs1[i] = delta
        else
          #--- new sleep function simulation
          nano1 = time_ns()
          sleep_ns(sleep_time)
          nano2 = time_ns()
          delta = (nano2 - nano1) / 10^9
          sleep_obs2[i] = delta
        end
        i == num_iters && break
        i += 1
      end
    end

    #--- basic stats from sleep_obs
    mean1 = mean(sleep_obs1[1:num_iters])
    mean2 = mean(sleep_obs2[1:num_iters])
    diff1_mean = mean1 - sleep_time
    diff2_mean = mean2 - sleep_time
    max1 = maximum(sleep_obs1[1:num_iters])
    max2 = maximum(sleep_obs2[1:num_iters])
    min1 = minimum(sleep_obs1[1:num_iters])
    min2 = minimum(sleep_obs2[1:num_iters])
    diff1_max = max1 - sleep_time
    diff2_max = max2 - sleep_time

    #--- generate the percent counts in each bracket
    for i = 1:num_iters
      delta1 = sleep_obs1[i]
      bin1 = convert(Integer,round((delta1 - min1) * sample_size / (max1 - min1)))
      if bin1 < 1
        bin1 = 1
      end
      sleep_count1[bin1] += 1

      delta2 = sleep_obs2[i]
      bin2 = convert(Integer,round((delta2 - min2) * sample_size / (max2 - min2)))
      if bin2 < 1
        bin2 = 1
      end
      sleep_count2[bin2] += 1
    end

    #--- generate the cdf for each bracket
    cdf1_prior = 0.
    for i = 1:sample_size
      sleep_cdf1[i] = cdf1_prior + (sleep_count1[i]/num_iters)
      cdf1_prior = sleep_cdf1[i]
    end
    cdf2_prior = 0.
    for i = 1:sample_size
      sleep_cdf2[i] = cdf2_prior + (sleep_count2[i]/num_iters)
      cdf2_prior = sleep_cdf2[i]
    end

    #--- setup defs for confidence limits
    Levels = [.0001, .0010, .0100, .2000, .5000,
              .6667, .8000, .9500, .9900, .9990, .9999]
    LevelId = ["00.01%", "00.10%", "01.00%", "20.00%", "50.00%",
               "66.67%", "80.00%", "95.00%", "99.00%", "99.90%", "99.99%"]
    LevelFound1 = [false, false, false, false, false, false, false, false, false, false, false]
    LevelFound2 = [false, false, false, false, false, false, false, false, false, false, false]
    LevelSecs1 = [0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0.]
    LevelSecs2 = [0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0.]
    num_levels = 11  #-- number of confidence levels

    #--- generate stats for confidence limits
    for i = 1:sample_size
      for j = 1:num_levels
        if !LevelFound1[j] && (sleep_cdf1[i] >= Levels[j])
          LevelFound1[j] = true
          LevelSecs1[j] = min1 + (i * (max1-min1) / sample_size)
        end
      end
      for j = 1:num_levels
        if !LevelFound2[j] && (sleep_cdf2[i] >= Levels[j])
          LevelFound2[j] = true
          LevelSecs2[j] = min2 + (i * (max2-min2) / sample_size)
        end
      end
    end

    #--- print results for a given sleep_time
    @printf("\n===================================================================\n")
    @printf("    STATISTIC              -- sleep_ns() --        --- sleep() ---         \n")
    #@printf("===================================================================\n")
    @printf("Specified sleep_time --  %10.6f seconds      %10.6f seconds \n", sleep_time, sleep_time)
    @printf("Mean sleep ------------  %10.6f seconds      %10.6f seconds \n", mean2, mean1)
    @printf("Maximum sleep ---------  %10.6f seconds      %10.6f seconds \n", max2, max1)
    @printf("Minimum sleep ---------  %10.6f seconds      %10.6f seconds \n", min2, min1)
    @printf("Mean difference -------  %10.6f seconds      %10.6f seconds \n", diff2_mean, diff1_mean)
    @printf("Maximum difference ----  %10.6f seconds      %10.6f seconds \n", diff2_max, diff1_max)
    @printf("-------------------------------------------------------------------\n")
    @printf("  CDF OBSERVATIONS        -- sleep_ns() --        --- sleep() ---         \n")
    for i = 1:num_levels  #-- print confidence level of observations
      @printf("%s obs's under       %10.6f seconds      %10.6f seconds \n",
              LevelId[i], LevelSecs2[i], LevelSecs1[i] )
    end
    @printf("-------------------------------------------------------------------\n")
    @printf("  CDF DIFFERENCES          -- sleep_ns() --        --- sleep() ---         \n")
    for i = 1:num_levels  #-- print confidence level of diffs
      @printf("%s diff's under      %10.6f seconds      %10.6f seconds \n",
              LevelId[i], LevelSecs2[i]-sleep_time, LevelSecs1[i]-sleep_time)
    end
    @printf("-------------------------------------------------------------------\n")
    @printf("Simulation time       => %10.6f seconds\n", total_sim_time)
    @printf("Number of iterations  =>   %i \n", num_iters)
    @printf("Specified sleep time  => %10.6f seconds\n", sleep_time)
    @printf("CPU load [one core]   => %10.6f percent\n", calc_load)
    @printf("-------------------------------------------------------------------\n")
  end
  println("\n\n")
  return nothing
end  #-- End of detail_compare function

function seven_sleeps()
  #-- prints range of sleep_time's for sleep_ns() showing their accuracy
  println("\n------- samples calls to sleep_ns() ------")
  start_sleep_time = 1.
  for i = 1:6  sleep_time = start_sleep_time / 10^(i - 1)
    delta = sleep_ns(sleep_time)
    @printf("Wanted sleep time:   ------ %11.9f seconds\n", sleep_time)
    @printf("\Actual sleep time:   ------ %11.9f seconds  <--\n", delta)
  end
  sleep_time = .000005
  delta = sleep_ns(sleep_time)
  @printf("Wanted sleep time:   ------ %11.9f seconds\n", sleep_time)
  @printf("\Actual sleep time:   ------ %11.9f seconds  <--\n", delta)
  println("")

  #-- prints range of sleep_time's for sleep() showing their higher error rate
  println("\n--------- samples to call to sleep() ---------")
  start_sleep_time = 1.
  for i = 1:6  sleep_time = start_sleep_time / 10^(i - 1)
    tic1 = time_ns()   #-- since sleep() does not return a delta we need to calculate manually
    sleep(sleep_time)
    tic2 = time_ns()
    delta = (tic2-tic1) / 10^9
    @printf("Wanted sleep time:   ------ %11.9f seconds\n", sleep_time)
    @printf("\Actual sleep time:   ------ %11.9f seconds  <--\n", delta)
  end
  println("")

  return nothing
end  #-- end of seven_sleeps function

function demo_sleep_ns()
  #--- sample sleeps that show sleep_ns() in action
  sleep_time = .003   #-- want to sleep for .003 seconds
  sleep_ns(sleep_time)  #-- first call to warm up sleep_ns()

  @printf("Wanted sleep time ------> %14.7f \n", sleep_time)  #-- sleep for specified time and show delta
  @printf("Actual sleep time ------> %14.7f \n", sleep_ns(sleep_time))  #-- sleep for specified time and show delta

  seven_sleeps()  #-- print 7 graduated sleeps of sleep() and sleep_ns()

  StopNowWhileTesting()

  #sleep_ns(.000001)   #-- sleep time is too small! (uncomment to see error message)
  #sleep_ns(1)         #-- integers sleep times not allowed! (uncomment to see error message)

  #--- simple comparison: runs of only one sleep_time comparing sleep_ns() and sleep()
  simple_compare(10., .00500)  #-- simulate 10. seconds for a sleep_time of .00500 seconds

  #--- detailed comparison: runs multiple sleep_time's
  sleep_array = [.500000, .050000, .002500, .002310, .001000, .000100, .000010, .000005]
  detail_compare(20., sleep_array)  #-- simulate 20. seconds for each sleep_time

end  #-- End of demo_sleep_ns function

#export sleep_ns


end  #-- End of module NewSleep


module Mainline
#=
  To-Do
  -----
  call GitHub under program control
  run sleep_ns(.00200) for 2 hours and check memory used
  -----
  #
=#
println("--- module:Mainline has started ---")

import NewSleep.sleep_ns           #-- import sleep_ns function
import NewSleep.simple_compare     #-- import simple_compare function
import NewSleep.detail_compare     #-- import detail_report function
import NewSleep.seven_sleeps       #-- import ten_sleeps function
import NewSleep.demo_sleep_ns      #-- import ten_sleeps function

#run(`C:\\Users\\Owner\\AppData\\Local\\Google\\Chrome\\Application\\chrome.exe github.org//ArchieCall//AccurateSleep`)
demo_sleep_ns()

#-- Have fun testing sleep_ns()
#-- Archie Call - archcall@gmail.com

println("\n\n--- module:Mainline has ended ---")

end



