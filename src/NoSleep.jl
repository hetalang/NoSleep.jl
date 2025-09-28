#=
using NoSleep
# 1
with_nosleep() do
    ...
end

# 2
nosleep_on()
...
nosleep_off()

№ 3
@nosleep begin
    ...
end

# to check
in PowerShell (admin)
powercfg /requests
=#

module NoSleep

export @nosleep, nosleep_on, nosleep_off, with_nosleep, backend_name

@static if Sys.iswindows()
    include("backend-windows.jl")
elseif Sys.islinux()
    include("backend-linux.jl")
elseif Sys.isapple()
    include("backend-macos.jl")
else
    include("backend-stub.jl")
end

function nosleep_on(; keep_display::Bool=false)
    _nosleep_on(; keep_display)
    return
end

function nosleep_off()
    _nosleep_off()
    return
end

backend_name() = _backend_name

# insurance for "normal" process exit
atexit(() -> (try nosleep_off() catch; end))

macro nosleep(ex)
    return quote
        NoSleep.nosleep_on()
        try
            $(esc(ex))
        finally
            NoSleep.nosleep_off()
        end
    end
end


function with_nosleep(f::Function; keep_display::Bool=false, timeout_seconds::Real=Inf)
    nosleep_on(; keep_display)

    t = nothing
    if isfinite(timeout_seconds)
        t = @async begin
            sleep(timeout_seconds)
            try
                nosleep_off()
            catch
            end
        end
    end

    try
        return f()
    finally
        try
            nosleep_off()
        catch
        end
        if t !== nothing
            try
                Base.throwto(t, InterruptException())
            catch
            end
        end
    end
end

end # module
