# Linux: default keep inhibitor through systemd-inhibit.
# Implemented as a background process that lives while the "no-sleep" is active.

const _backend_name = "linux:systemd-inhibit"
const _nosleep_proc_ref = Ref{Base.Process}()

function _have_systemd_inhibit()
    sys = Sys.which("systemd-inhibit")
    sys !== nothing
end

function _nosleep_on(; keep_display::Bool=false)
    # --what can be extended: sleep, idle, handle-lid-switch
    if !_have_systemd_inhibit()
        @warn "systemd-inhibit not found in PATH; no-sleep may not work. Using stub."
        return
    end
    
    cmd = `systemd-inhibit --what=sleep --who=NoSleep.jl --why=Long\ computation --mode=block sleep inf`
    # run without waiting
    if isnothing(_nosleep_proc_ref[])
        _nosleep_proc_ref[] = run(cmd; wait=false)
    end
    return
end

function _nosleep_off()
    p = _nosleep_proc_ref[]
    if p isa Base.Process
        try
            kill(p)   # stop inhibitor
        catch
        end
        _nosleep_proc_ref[] = nothing
    end
    return
end
