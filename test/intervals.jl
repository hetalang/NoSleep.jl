# MANUAL TESTING

# Sleep drift monitor for 1 hour.
# Prints every minute and measures wall-clock delta between iterations.
# If the system sleeps, you'll see a delta >> 60s.

include("../src/NoSleep.jl")
using .NoSleep

using Dates

function time_interval_monitor(; minutes::Int=60, interval::Real=60)
    # Use wall clock; it jumps forward across suspend/resume
    t_prev = time()

    @info "Sleep monitor started" minutes interval

    try
        for i in 1:minutes
            sleep(interval)  # pause ~60s (will stall during system sleep)

            t_now = time()
            delta = t_now - t_prev
            t_prev = t_now
            
            # Pretty timestamp without DateFormat pitfalls
            ts = now()
            println("[$(Dates.hour(ts)):$(Dates.minute(ts)):$(Dates.second(ts))] iter=$i  delta=$(round(delta)) s")
        end
    catch e
        if e isa InterruptException
            println("\n^C Stopped by user.")
        else
            rethrow()
        end
    finally
        @info "Sleep monitor finished."
    end

    return
end

@nosleep begin
    time_interval_monitor();
end
