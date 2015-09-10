# AccurateSleep
A function to more accurately sleep a Julia process.

The present Julia sleep() function has an average error differential as follows:

  50% of sleep() calls exceed 1.10 milliseconds of error
  25% of sleep() calls exceed 1.75 milliseconds of error
   5% of sleep() calls exceed 1.90 milliseconds of error
   1% of sleep() calls exceed 2.00 milliseconds of error 

The sleep_ns() enables extremely accurate sleeping a Julia program accurately down to .01 ms, and less if desired.

This function works as follows: 
  the concept of burn_time is advanced, where burn_time  is a threshold where 99% of typical sleep() calls fall below this level.  Of course

Why is this not showing?

this is showing okk. hhh a;dffjas;dkffj a;skdjf a;sdkjf a;sd kfjf;a sdjfa;sddfj ;asddkjf 
;asdjf ;asddjf ;asdjf;askdjf;asdj f;asdjf;a

CPU Loading       sleep_time
more of the same
extra extra
