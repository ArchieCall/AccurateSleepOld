# AccurateSleep
A function to more accurately sleep a Julia process.

The present Julia sleep() function has an average error differential of 1.1 milliseconds.  Indeed 30% of sleep() calls exceed 1.5 milliseconds of error.

The sleep_ns() enables extremely accurate sleeping a Julia program accurately down to .01 ms, and less if desired.

This function works as follows:
  . the concept of burn_time is advanced, where burn_time  is a threshold where 99% of typical sleep() calls fall below this level
  
  
