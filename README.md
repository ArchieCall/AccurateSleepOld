# AccurateSleep
A function to more accurately sleep a Julia process.

The present Julia sleep() function has an average error differential as follows:

  * 50% of sleep() calls exceed 1.10 milliseconds of error
  * 25% of sleep() calls exceed 1.75 milliseconds of error
  * 5% of sleep() calls exceed 1.90 milliseconds of error
  * 1% of sleep() calls exceed 2.00 milliseconds of error 

The sleep_ns() function enables extremely accurate sleeping of a Julia program accurately down to .005 ms.

This function works as follows: 
  the concept of burn_time is advanced, where burn_time  is a threshold where 99% of typical sleep() calls fall below this level.  Of course

Why is this not showing?

sleep_time   |         cpu load
-----------  |         --------
  .050 secs  |          0.1 %
  .030 secs  |          0.8 %
