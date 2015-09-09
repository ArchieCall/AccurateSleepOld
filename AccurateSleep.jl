# AccurateSleep.jl
# 09-09-2015
module NewSleep
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

end

module Mainline
println("--- module:Mainline has started ---")
#=
  refer to web site for details
=#

import NewSleep.sleep_ns   #-- import the function sleep_() from module NewSleep

#---compare sleep and sleep_ns
function comparison_report(total_sim_time::FloatingPoint, sleep_array; warm_up = false)

  println("--- comparison_report started ---")
  @show(total_sim_time)
  @show(sleep_array)
  @show(warm_up)

  sleep_obs1 = zeros(Float64,10_000)
  sleep_obs2 = zeros(Float64,10_000)
  sleep_count1 = zeros(Float64,10_000)
  sleep_count2 = zeros(Float64,10_000)
  sleep_cdf1 = zeros(Float64,10_000)
  sleep_cdf2 = zeros(Float64,10_000)

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
  new_burn_time = .00230

  #--- loops on sleep_time

  for sleep_time  in sleep_array
    #--- zero arrays for each new sleep_time cycle
    sleep_obs1[1:end] = 0.
    sleep_obs2[1:end] = 0.
    sleep_count1[1:end] = 0.
    sleep_count2[1:end] = 0.
    sleep_cdf1[1:end] = 0.
    sleep_cdf2[1:end] = 0.

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
    if num_iters > 10000
      num_iters = 10000
    end
    total_sim_time = num_iters * sleep_time
    for new_sleep in [false, true]

      delta = 0.
      diff = 0.
      new_delta = 0.
      const tics_per_second = 1_000_000_000.
      num_over_threshold = 0
      const new_burn_time = .00231
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
          sleep_ns(sleep_time, burn_time = new_burn_time)
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
        bin1 = convert(Integer,round(delta1 * 10_000 / max1))
        if bin1 < 1
          bin1 = 1
        end
        sleep_count1[bin1] += 1
        delta2 = sleep_obs2[i]
        bin2 = convert(Integer,round(delta2 * 10_000 / max2))
        if bin2 < 1
          bin2 = 1
        end
        sleep_count2[bin2] += 1
      end

      #--- generate the cdf for each bracket
      cdf1_prior = 0
      for i = 1:10_000
        sleep_cdf1[i] = cdf1_prior + (sleep_count1[i]/num_iters)
        cdf1_prior = sleep_cdf1[i]
      end
      cdf2_prior = 0
      for i = 1:10_000
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
      for i = 1:10_000
        for j = 1:num_levels
          if !LevelFound1[j] && (sleep_cdf1[i] >= Levels[j])
            LevelFound1[j] = true
            LevelSecs1[j] = i * max1 / 10_000
          end
        end
        for j = 1:num_levels
          if !LevelFound2[j] && (sleep_cdf2[i] >= Levels[j])
            LevelFound2[j] = true
            LevelSecs2[j] = i * max2 / 10_000
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
      @printf("Specified burn time   => %10.6f seconds\n", new_burn_time)
      @printf("CPU load [one core]   => %10.6f percent\n", calc_load)
      @printf("   [Note: please refer to defintions at top of this report]\n")
      @printf("-------------------------------------------------------------------\n")
    end
  end
  println("\n\n")
  return nothing
end

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
    @show(sleep_time, num_iters)
    @printf("Total simulation time  ---------------------------------  %10.6f seconds\n", revised_simulation_time)
    @printf("Average sleep time for sleep() -------------------------  %10.6f seconds\n", ave_delta_a)
    @printf("Average sleep time for sleep_ns() ----------------------  %10.6f seconds\n", ave_delta_b)
    @printf("Average differential sleep time for sleep() ------------  %10.6f seconds\n", ave_diff_a)
    @printf("Average differential sleep time for sleep_ns() ---------  %10.6f seconds\n", ave_diff_b)
  end
  return nothing
end


#--- these are sample scripts that show sleep_ns() in action
sleep_ns(.01) #-- warm up the new function - one sleep call for .01 seconds

#--- this run takes about 22 seconds
simple_compare(.1, .0050, warm_up = true)  #-- warmup - .1 secs duration & .0050 secs sleep
simple_compare(30., .0050)  #-- production run - 30 secs duration & 0050 secs sleep

#--- this run will take about 1 minutes per each sleep_time
sleep_array = [.500, .100, .050, .010, .008, .007, .006, .005, .004, .003, .002, .001]  #--- varying sleep_time's in seconds
comparison_report(.1, sleep_array, warm_up = true)  #--warmup for .1 seconds
comparison_report(30., sleep_array)  #-- production run for 30 seconds

println("\n\n--- module:Mainline has ended ---")

end
