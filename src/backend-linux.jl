# Linux: default keep inhibitor through systemd-inhibit.
# Implemented as a background process that lives while the "no-sleep" is active.

# global reference to the inhibitor process
const _nosleep_proc_ref = Ref{Union{Nothing, Base.Process}}(nothing)

function _have_systemd_inhibit()
    sys = Sys.which("systemd-inhibit")
    sys !== nothing
end

# Build command safely
function _inhibitor_cmd(keep_display::Bool)
    what = keep_display ? "sleep:idle" : "sleep"
    # Prefer 'infinity' over 'inf' for better portability
    args = [
        "systemd-inhibit",
        "--what=$(what)",
        "--who=NoSleep.jl",
        "--why=Long computation",
        "--mode=block",
        "sleep", "infinity",
    ]
    return Cmd(args)
end

function _nosleep_on(; keep_display::Bool=false)
    if !_have_systemd_inhibit()
        @warn "systemd-inhibit not found in PATH; no-sleep may not work. Using stub."
        return
    end

    current = _nosleep_proc_ref[]
    if current isa Base.Process && current.exitcode !== nothing
        # drop finished inhibitor process so we can start a fresh one
        _nosleep_proc_ref[] = nothing
        current = nothing
    end

    if isnothing(current)
        cmd = _inhibitor_cmd(keep_display)
        _nosleep_proc_ref[] = run(cmd; wait=false)
    end
    return
end

function _nosleep_off()
    p = _nosleep_proc_ref[]
    if p isa Base.Process
        try
            if p.exitcode === nothing
                kill(p)   # stop inhibitor
            end
            wait(p)
        catch
        end
        _nosleep_proc_ref[] = nothing
    end
    return
end
