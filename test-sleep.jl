include("./src/NoSleep.jl")

using .NoSleep

nosleep_on(; keep_display=true)

backend_name()

nosleep_off()

@nosleep begin
    sleep(30)
end

with_nosleep() do
    sleep(30)
end

