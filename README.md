**AccurateSleep**

***sleep_ns(sleep_time)***
* A function to block the current task (i.e. sleep) for the specified number of seconds.
* sleep_time must be a floating point number between .000001 seconds and 100. seconds.
* sleep_ns() is very similiar to the normal Julia sleep() function, albeit with more accuracy.

The sleep_ns() function enables extremely accurate sleeping of a Julia program accurately down to .000005 seconds.

Function sleep_ns() is a hybrid solution that works as follows: 
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
  * the time delta is put in the return statement
  * 
  
CPU loading when using sleep_ns
* cool and the gang
* dkdkdk
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

sleep_time   |        cpu load   | mean error
-----------  |        --------   | ----------
  .099 secs  |         0.1 %     |  .000003 secs
  .050 secs  |         0.1 %     |  .000014 secs
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
  
