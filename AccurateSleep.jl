# AccurateSleep.jl
# 09-15-2015
module NewSleep

function sleep_ns(sleep_time::FloatingPoint)
  #=
   + Purpose: an accurate sleep function written totally in Julia
   + Parameter:  sleep_time in seconds
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
    #ArgumentError
    sleep_time_parm_out_of_range()
  end

  nano1 = time_ns()  #-- get beginning time tic
  nano_final = nano1 + (sleep_time * tics_per_second)

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
  delta = 0.
  nano2 = nano1
  while true
    nano2 = time_ns() #-- take tic to allow delta calc
    nano2 >= nano_final && break  #-- break out if full time has elapsed
    delta = (nano2 - nano1) / tics_per_second  #-- actual elapsed time of sleep
  end

  return delta
end  #-- End of sleep_ns() function


function simple_compare(simulation_time::FloatingPoint, sleep_time::FloatingPoint; warm_up = false)

  const tics_per_sec = 1_000_000_000
  num_iters = convert(Integer,round(simulation_time / sleep_time))
  if num_iters < 1
    num_iters = 1
  end
  if warm_up
    num_iters = 1
  end
  revised_simulation_time = num_iters * sleep_time
  if !warm_up
    @printf("\n========================== simple_compare simulation =======================\n")
    @show(num_iters)
    @printf("Total simulation time  ---------------------------------  %10.6f seconds\n", revised_simulation_time)
    @printf("Specified sleep time -----------------------------------  %10.6f seconds\n", sleep_time)
  end

  delta_a = 0.
  nano1 = time_ns()
  i = 1
  while true
    sleep(sleep_time)
    nano2 = time_ns()
    delta_a = (nano2 - nano1) / tics_per_sec
    i >= num_iters && break
    i += 1
  end
  delta_b = 0.
  nano1 = time_ns()
  i = 1
  while true
    sleep_ns(sleep_time)
    nano2 = time_ns()
    delta_b = (nano2 - nano1) / tics_per_sec
    i >= num_iters && break
    i += 1
  end
  ave_delta_a = delta_a / num_iters
  ave_delta_b = delta_b / num_iters
  ave_diff_a = ave_delta_a - sleep_time
  ave_diff_b = ave_delta_b - sleep_time
  if !warm_up
    @printf("Average sleep time for sleep() -------------------------  %10.6f seconds\n", ave_delta_a)
    @printf("Average sleep time for sleep_ns() ----------------------  %10.6f seconds\n", ave_delta_b)
    @printf("Average differential sleep time for sleep() ------------  %10.6f seconds\n", ave_diff_a)
    @printf("Average differential sleep time for sleep_ns() ---------  %10.6f seconds\n", ave_diff_b)
  end
  return nothing
end  #-- End of simple_compare() function


function comparison_report(total_sim_time::FloatingPoint, sleep_array; warm_up = false)
  #=
    Compares sleep_ns() vs. sleep() for multiple values of start_sleep_time
    Parms:
      total_sim_time -> total simulation time for each sleep_time in the sleep_array
      sleep_array -> an array of sleep_times   ie. [.005, .002, .001, .0001, .00001]
    Up to 100,000 simulation samples are run for each sleep_time
    Pay attention to the Mean Difference statistic which highlights accuracy of sleep_ns()
=#
  if !warm_up
    @printf("\n====================== comparison_report simulation ========================\n")
    #@show(sleep_array)
    @printf("Total simulation time  ---------------------------------  %10.6f seconds\n", total_sim_time)
    for i = 1:length(sleep_array)
      @printf("Specified sleep time(s) --------------------------------  %10.6f seconds\n", sleep_array[i])
    end
  end

  sample_size = 20_000

  sleep_obs1 = zeros(Float64,sample_size)
  sleep_obs2 = zeros(Float64,sample_size)
  sleep_count1 = zeros(Float64,sample_size)
  sleep_count2 = zeros(Float64,sample_size)
  sleep_cdf1 = zeros(Float64,sample_size)
  sleep_cdf2 = zeros(Float64,sample_size)

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
      const tics_per_second = 1_000_000_000.
      i = 1
      while true
        if !new_sleep
          #--- regular sleep simulation
          nano1 = time_ns()
          sleep(sleep_time)
          nano2 = time_ns()
          delta = (nano2 - nano1) / 1_000_000_000.
          sleep_obs1[i] = delta
        else
          #--- new sleep function simulation
          nano1 = time_ns()
          sleep_ns(sleep_time)
          nano2 = time_ns()
          delta = (nano2 - nano1) / tics_per_second
          sleep_obs2[i] = delta
        end
        i == num_iters && break
        i += 1
      end
    end

    if !warm_up
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
        bin1 = convert(Integer,round(delta1 * sample_size / max1))
        if bin1 < 1
          bin1 = 1
        end
        sleep_count1[bin1] += 1
        delta2 = sleep_obs2[i]
        bin2 = convert(Integer,round(delta2 * sample_size / max2))
        if bin2 < 1
          bin2 = 1
        end
        sleep_count2[bin2] += 1
      end

      #--- generate the cdf for each bracket
      cdf1_prior = 0
      for i = 1:sample_size
        sleep_cdf1[i] = cdf1_prior + (sleep_count1[i]/num_iters)
        cdf1_prior = sleep_cdf1[i]
      end
      cdf2_prior = 0
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
            LevelSecs1[j] = i * max1 / sample_size
          end
        end
        for j = 1:num_levels
          if !LevelFound2[j] && (sleep_cdf2[i] >= Levels[j])
            LevelFound2[j] = true
            LevelSecs2[j] = i * max2 / sample_size
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
  end
  println("\n\n")
  return nothing
end  #-- End of comparison_report() function


end  #-- End of module NewSleep


module Mainline
#=
  To-Do
  call GitHub under program control
  run sleep_ns(.00200) for 2 hours and check memory used.
  #
=#
println("--- module:Mainline has started ---")

import NewSleep.sleep_ns           #-- import sleep_ns function
import NewSleep.simple_compare     #-- import simple_compare function
import NewSleep.comparison_report  #-- import comparison_report function

#--- sample sleeps that show direct sleep_ns() in action
#run(`C:\\Users\\Owner\\AppData\\Local\\Google\\Chrome\\Application\\chrome.exe github.org//ArchieCall//AccurateSleep`)
const tics_per_second = 1_000_000_000

#codesample

sleep_time = .003
@show(sleep_time)  #-- show specified sleep_time
@show(sleep_ns(sleep_time))  #-- sleep for specified time and show delta

println("\n------- samples calls to sleep_ns() ------")
#-- prints range of sleep_time's for sleep_ns() showing their accuracy
start_sleep_time = 1.
for i = 1:6  sleep_time = start_sleep_time / 10^(i - 1)
  delta = sleep_ns(sleep_time)
  @printf("Wanted sleep time:   ------ %11.9f seconds\n", sleep_time)
  @printf("\Actual sleep time:   ------ %11.9f seconds  <--\n", delta)
end
println("")

println("\n--------- samples to call to sleep() ---------")
#-- prints range of sleep_time's for sleep() showing their higher error rate
start_sleep_time = 1.
for i = 1:7  sleep_time = start_sleep_time / 10^(i - 1)
  tic1 = time_ns()
  sleep(sleep_time)
  tic2 = time_ns()
  delta = (tic2-tic1)/tics_per_second
  @printf("Wanted sleep time:   ------ %11.9f seconds\n", sleep_time)
  @printf("\Actual sleep time:   ------ %11.9f seconds  <--\n", delta)
end
println("")

#sleep_ns(1)    #-- integers times not allowed! (uncomment to see error)


#--- simple comparison: runs takes about 20 seconds
simple_compare(.1, .00500, warm_up = true)  #-- warm_up implies no output
simple_compare(10., .00500)  #-- production run - 10 secs duration for .00231 secs sleep

#--- detailed comparison report: runs about 1 minute for each sleep_time
sleep_array = [.05000]
#sleep_array = [.008000, .005000, .002500, .002310, .001000, .000100, .000010, .000005]
comparison_report(.1, sleep_array, warm_up = true)  #--warmup implies no output
comparison_report(15., sleep_array)  #-- production run

#-- Have fun testing sleep_ns()
#-- Archie Call - archcall@gmail.com

println("\n\n--- module:Mainline has ended ---")

end
