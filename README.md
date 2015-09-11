# AccurateSleep
A function to more accurately sleep a Julia process.

cumulative percent     |  sleep() error rate     | sleep_ns() error rate
---------------------  |  --------------------   | -------------------
50%                    |  .0015                  |    .0000012
25%                    |  .000                   |  .99
1%                     |  .030                   |  .00014
.1%                    |  .0005 seconds          | .00001 seconds
.01%                   |  .00045                 | .88888 seconds

The present Julia sleep() function has an average error differential as follows:

  * 50% of sleep() calls exceed 1.15 milliseconds of error
  * 25% of sleep() calls exceed 1.75 milliseconds of error
  * 5% of sleep() calls exceed 1.90 milliseconds of error
  * 1% of sleep() calls exceed 2.00 milliseconds of error 

The sleep_ns() function enables extremely accurate sleeping of a Julia program accurately down to .000002 seconds.

This function works as follows: 
  the concept of burn_time is advanced, where burn_time  is a threshold where 99% of typical sleep() calls fall below this level.  Of course

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
  
