# AccurateSleep

sleep_ns(sleep_time)  -     A function to block the current task.

                      Parmater - sleep_time is specified in seconds and must be a floating point between .000001 seconds and 100. seconds.  

The sleep_ns() function enables extremely accurate sleeping of a Julia program accurately down to .000002 seconds.

This function works as follows: 
  the concept of burn_time is advanced, where burn_time  is a threshold where 99% of typical sleep() calls fall below this level.  Of course

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
  
