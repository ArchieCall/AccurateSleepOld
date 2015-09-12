**AccurateSleep**

***sleep_ns(sleep_time)***
* A function to block the current task (i.e. sleep) for the specified number of seconds.
* sleep_time must be a floating point number between .000005 seconds and 100. seconds.
* sleep_ns() is very similiar to the normal Julia sleep() function, albeit with more accuracy.

***Function sleep_ns() is a hybrid solution that works as follows:*** 
  * the actual sleep time of sleep() was examined
  * the actual time was always greater than the specified time
  * the average error of the sleep was about .00150 second
  * 99+% of the errors were found to be less than .00230 seconds
  * a constant called burn_time is set to .00230 seconds
  * let us sample a specific sleep_time say .00800 seconds
  * the call to the function is:  sleep_ns(.00800)
  * the function now subtracts off the burn_time yielding a partial_sleep_time of .00570 seconds
  * a nano second time taken with time_ns() is put in var nano1
  * a new var called nano_final is computed to be nano1 + (sleep_time * 1_000_000_000)
  * sleep itself is called with:  sleep(partial_sleep_time)
  * when this sleep is done the actual time elapsed will almost always be between .00570 seconds and .00800 seconds
  * if the elapsed time is greater than or = to .00800, then sleep_ns() is done
  * if the elapsed time is less than .00800 then a burn cycle is required
  * the burn cycle is a simple while loop that takes a second time_ns() called nano2
  * in the while loop when nano2 equals or exceeds nanofinal, then sleep_ns() is done
  * delta returned in the return statement 
  
***CPU loading when using sleep_ns***
* the sleep(partial_sleep_time) portion of sleep_ns() has zero impact on loading
* the burn cycle of sleep_ns() has an impact on cpu loading
* on my Windows 10 Core i5 laptop running Julia 3.11, I found that the burn cycle maxed out at 29% CPU loading
  * the 29% loading on my computer is predicated on the number of cores and the standard setting on Windows 10
  * if the Affinity and Priority were revised for sleep_ns(), then the loading might be mitigated somewhat
  * I'm not familiar with how Linux handles such matters, but anything that throttles a process would be of benefit
* the burn_time threshold of .00230 seconds defines where burning begins
* if the sleep_time is less than .00230, then burning applies all the time
* if the sleep_time is greater than .00230, then the sleep is a hybrid of sleep and burn
* the greater the sleep_time in relation to burn_time the less the impact on loading
* for example, at sleep_time = .00800 seconds, the impact on cpu loading is 4%, while at .00400 seconds the loading is 12%
* 


cdf                    |   sleep() err           | sleep_ns() err           
---------------------  |  --------------------   | -------------------
50.00 %                |  .001681 secs           |  .000001 secs
66.67 %                |  .001887 secs           |  .000001 secs
80.00 %                |  .002259 secs           |  .000001 secs
95.00 %                |  .002022 secs           |  .000002 secs
99.00 %                |  .002107 secs           |  .000022 secs
99.90 %                |  .002211 secs           |  .000050 secs
99.99 %                |  .002430 secs           |  .000085 secs






The impact of sleep_ns on computer cpu loading is summarized below.

sleep_time   |        cpu load  
-----------  |        --------  
  .099 secs  |         0.1 %
  .050 secs  |         0.1 %    
  .030 secs  |         0.8 %
  .020 secs  |         1.0 %
  .010 secs  |         3.0 %
  .008 secs  |         4.0 %
  .006 secs  |         5.5 %
  .004 secs  |         8.5 %
  .003 secs  |        12.0 %
  .0025 secs |        22.0 %
  .0023 secs |        29.0 %
  .0020 secs |        29.0 %
  
  
 
 
 ***The AccurateSleep.jl is comprised of the following:***
 * module NewSleep
   * sleep_ns() function
   * simple_compare() function
   * comparison_report() function
 * module Mainline
   * import NewSleep.sleep_ns     #this should be spaced over
   * import NewSleep.simple_compare
   * import NewSleep.comparison_report
   * runs all sorts of sample sleep stuff to show sleep_ns in action
 * 

***The sleep_ns.jl file is comprised of:***
* sleep_ns()   #--- just the sleep_ns() ready to cut a paste into your app
