## AccurateSleep
```
A package that provides an alternative sleep function:  sleep_ns().

This function is very similiar to the normal Julia sleep() function,
albeit with much improved accuracy.

The sleep_ns() function has an average error rate of .000001 seconds,
with only 5% of the errors exceeding .000002 seconds

In contrast: the regular sleep() function has an average error of .001150 seconds,
with 5% of the errors exceeding .002100 seconds
```
### Installation
```
I apologise up front that this is not a package install.
I will get there once Github commands are wrapped in my mind!
```

**Method A: Manually install just the function sleep_ns()**
```julia
#-- copy and paste the contents of "sleep_ns.jl" into an appropriate location in your Julia application
#-- the contents are the sleep_ns() function
#-- no external packages are required 

sleep_ns(.05)  #-- warm up sleep_ns
sleep_ns(.05)  #-- sleep accurately for .05 seconds

wanted_sleep = .002
actual_sleep = sleep_ns(wanted_sleep)
@show(wanted_sleep, actual_sleep)

#=  this is the output of above @show command
wanted_sleep => 0.002
actual_sleep => 0.002000409
=#

```
**Method B: Manually install demo file AccurateSleep.jl**
```julia
#-- download the file AccurateSleep.jl to your local computer

#-- the instruction below will run the demo application
include("c:\\ArchieJulia\\AccurateSleep.jl")  #-- revise the file location specific to your Julia installation

#-- the output should be similar to that in the SampleOutput folder on GitHub

```


-----------
### Table showing results for sample simulation
```
6,000 Samples comparing sleep(.005) and sleep_ns(.005)
DIFF => sleep(.005) - .005  or sleep_ns(.005) - .005
CDF => cumulative density function of DIFF
```

  Statistic            |   sleep(.005)           | sleep_ns(.005)                 
:-------------------:  |  :-------------------:  | :-----------------:
CDF 20.00 %            |  .001046 secs           |  .000001 secs
CDF 50.00 %            |  .001495 secs           |  .000001 secs
CDF 80.00 %            |  .001801 secs           |  .000001 secs
CDF 95.00 %            |  .002020 secs           |  .000001 secs
CDF 99.00 %            |  .002121 secs           |  .000023 secs
CDF 99.90 %            |  .002197 secs           |  .000165 secs
CDF 99.99 %            |  .003201 secs           |  .000233 secs
Mean sleep             |  .006366 secs           |  .005001 secs
Maximum sleep          |  .008201 secs           |  .005233 secs
Minimum sleep          |  .006366 secs           |  .005001 secs
Mean sleep DIFF        |  .001343 secs           |  .000002 secs


----------
## Use cases
* use sleep_ns() whenever sleep() is not accurate enough for your purposes
* call a function on a precise interval
* syncrhonize some action to a real time process or clock
* produce timestamps or tokens on some frequency
* 

-------------
## How sleep_ns() works 
  * the actual sleep time of sleep() was examined
  * the time slept is always greater than the specified time
  * average error of the sleep is about .00150 second
  * 99+% of the errors were found to be less than .00230 seconds
  * a constant called burn_time is defined: const burn_time = .00230  #-- in seconds
  * let us produce a sleep_time of .00800 seconds
  * the call to the function is:  sleep_ns(.00800)
  * the function initially subtracts off the burn_time as follows:
  *   partial_sleep_time = .00800 - partial_sleep_time - burn_time  #-- computes to .00570 seconds
  *   sleep(partial_sleep_time)  #--sleeps off .00570 sec
  * a nano second time taken with: nano1 = time_ns()
  * asleep itself is called with:  sleep(partial_sleep_time)
  * when this sleep is done the actual time elapsed will almost always be between .00570 seconds and .00800 seconds
  * if the elapsed time is greater than or = to .00800, then sleep_ns() is done
  * if the elapsed time is less than .00800 then a burn cycle is required
  * the burn cycle is a simple while loop that takes a second time_ns() called nano2
  * in the while loop when nano2 equals or exceeds nanofinal, then sleep_ns() is done
  * delta returned in the return statement 
  
## CPU loading when using sleep_ns
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


***The impact of sleep_ns on computer cpu loading is summarized below***

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


-----------
### Importance of warm up operations
```
sleep_ns() and other functions calling sleep_ns() should be warmed up for accurate sleeping
  
```
---------------  
### Functions 
***sleep_ns()***
```
stand alone function that performs a hybrid sleep
uses a combination of standard sleep() and final burn cycle
does not depand on any Packages and uses 100% julia code
```
***simple_compare()***
```
compares sleep() and sleep_ns for only one sleep_time
```
***detail_compare()***
```
compares sleep() and sleep_ns for multple sleep_time's
produces probability density function & cumulative density functions
```
***six_sleeps()***
```
performs six calls to sleep_ns() using a graded series of sleep_times's
``` 
 
 ***The AccurateSleep.jl is comprised of the following:***
 * module NewSleep
   * sleep_ns() function
   * simple_compare() function
   * detail_compare() function
   * ten_sleeps() function
   * interval_function_caller function
   * do_something function
 * module Mainline
   * import NewSleep.sleep_ns
   * import NewSleep.simple_compare
   * import NewSleep.detail_compare
   * import NewSleep.ten_sleeps
   * import NewSleep.interval_function_caller
   * import NewSleep.do_something
   * runs examples showing sleep_ns in action
 * 

## Possible use of sleep_ns in parallel operation
```
  There are areas of parallel operations that use polling.
  
  I have examined some of these and it seems that the poll timing is only accurate
  to about 1.5 milliseconds which is similiar to sleep().
  
  Potentially some of this polling or waiting could be augmented with sleep_ns().
  Of course, such a revision would need to be weighed against increased CPU loading!
```


## To-Do
* learn enough GitHub commands to create registered Julia package
* create AccurateSleep as a registered package
* check out whether time_ns() dramatically affects number of while cycles when burning
* investigate C instructions that are NOP and take up time but not CPU load
