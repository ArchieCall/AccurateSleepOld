#--- tests are here sleep_ns()
using Distributions
using AccurateSleep
import NewSleep.sleep_ns
#using Base.test
act_sleep_time = sleep_ns(.005)
act_sleep_time = sleep_ns(.005)
@show(act_sleep_time)
test_times = [.006, .003, .001, .0001]
for sleep_time in test_times
  println(sleep_time)
end
