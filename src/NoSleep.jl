"""
A Julia package to prevent the system from going to sleep while a long-running task is executing.
"""
module NoSleep

export @nosleep, nosleep_on, nosleep_off, with_nosleep

@static if Sys.iswindows()
    include("backend-windows.jl")
elseif Sys.islinux()
    include("backend-linux.jl")
elseif Sys.isapple()
    include("backend-macos.jl")
else
    include("backend-stub.jl")
end

"""
    nosleep_on(; keep_display::Bool=false)

Prevent the system from going to sleep. System will restore normal sleep behavior when `nosleep_off()` is called 
or the Julia process exits.
If `keep_display` is `true`, the display will also be kept on.
"""
function nosleep_on(; keep_display::Bool=false)
    _nosleep_on(; keep_display)
    return
end

"""
    nosleep_off()

Restore normal sleep behavior from `nosleep_on()`.
"""
function nosleep_off()
    _nosleep_off()
    return
end

# insurance for "normal" process exit
atexit(() -> (try nosleep_off() catch; end))


"""
    @nosleep expr

A macro to run `expr` with `nosleep_on()` and `nosleep_off()`.
"""
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

"""
    with_nosleep(f::Function; keep_display::Bool=false, timeout_seconds::Real=Inf)

Run function `f` with `nosleep_on()` and `nosleep_off()`. 
If `timeout_seconds` is finite, the `nosleep_off()` will be called after the timeout even if `f` is still running.
"""
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
